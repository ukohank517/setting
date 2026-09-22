#!/usr/bin/env python3
"""keep herdr's spaces pane-path rows current by listening to herdr events.

report-pane-paths.sh renders "<state> <cwd>" rows per workspace, but it only
runs when something calls it (shell cd, claude code status update). focus
moves, agent state changes and pane open/close happen without either, so
this watcher subscribes to herdr's newline-delimited JSON socket API and
re-runs the script for the workspaces whose rows would change.

it also colours the agents rows by workspace membership. a sidebar token
has one fixed style, so each claude pane's name row is fed through slots
(see [ui.sidebar.agents.rows_by_agent] in config.toml): the session name
statusline.sh reports as $session is copied into $name (pane in the focused
workspace, bright) or $name_other (dim); herdr's state goes into
$st_working / $st_blocked / $st_idle / $st_done (state colours) or $st_other
(dim, idle in a foreign workspace). only one slot of each pair is set, the rest
are cleared, so the row still reads "● setting-42 · working".

the state text also keeps its own "done". herdr's done means "finished
while the tab was not on screen or the terminal window was not focused"
(apply_pane_state_change in src/app/actions.rs), and it flips back to idle
as soon as the window regains focus or the tab is shown, for every pane in
the tab at once. the sidebar instead shows "done" when an agent finished
while its pane was not the focused pane, and keeps it until that pane gets
focus (UNACKED below). herdr's own done is honoured too. the state icon is
still herdr's, so it can go green while the text stays blue. only the text
is affected; herdr's notifications and `herdr agent wait` see herdr's state.
working, blocked and this "done" are shown in their state colour in every
workspace; only idle is dimmed in a foreign workspace (with the name).

herdr's agent state (working / idle / blocked / done) is announced by
pane.agent_status_changed only, and that subscription is per pane: it needs
a pane_id, "*" is rejected, and a request naming an unknown pane makes herdr
close the connection. a connection also accepts exactly one events.subscribe
(a second one closes it). so the general subscription below lives on one
socket and every pane gets its own small socket subscribed to its status,
opened and closed as panes come and go in the snapshot. without those the
state text (the $st_* slots) lagged behind herdr's own state icon: an agent
that stops printing goes working -> idle on herdr's quiet timer, which emits
no pane.updated, so nothing woke the watcher until the next focus move or
shell prompt.

events are only a trigger, never trusted as a diff: herdr emits pane_focused /
workspace_focused events on every workspace metadata update (including the
ones this pipeline sends), which made a naive "refresh on focus event"
watcher loop at ~10 Hz. so after a debounced burst of events the watcher
takes one snapshot, fingerprints what the rows depend on (the globally
focused pane and, per workspace, each pane's id, agent, state and cwd) and
refreshes only workspaces whose fingerprint changed. a refresh that changes
nothing therefore produces no further refresh.

started on demand by report-pane-paths.sh (pid file next to this script);
exits when the herdr socket closes, i.e. with the herdr server.
"""
import json
import os
import selectors
import socket
import subprocess
import sys
import threading
import time

HERDR_DIR = os.path.expanduser("~/.config/herdr")
SOCK = os.path.join(HERDR_DIR, "herdr.sock")
PIDFILE = os.path.join(HERDR_DIR, "pane-paths-watch.pid")
SCRIPT = os.path.join(HERDR_DIR, "report-pane-paths.sh")
DEBOUNCE = 0.05  # seconds of quiet before looking at the snapshot
MIN_GAP = 0.15   # seconds between two refresh passes, whatever happens
# refreshed without debounce: the user is waiting on these
URGENT_EVENTS = {"pane_focused", "workspace_focused",
                 "pane_agent_status_changed", "pane.agent_status_changed"}

SUBSCRIPTIONS = [
    "pane.focused", "workspace.focused", "pane.created", "pane.closed",
    "pane.moved", "pane.exited", "pane.updated", "pane.agent_detected",
]


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def already_running():
    try:
        with open(PIDFILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return pid != os.getpid()
    except (OSError, ValueError):
        return False


STATE_SLOTS = ("st_working", "st_blocked", "st_idle", "st_done", "st_other")
NAME_SLOTS = ("name", "name_other")
FINISHED = ("idle", "done")

LAST_STATUS = {}   # pane_id -> herdr status in the previous snapshot
UNACKED = set()    # panes that finished while not focused, until focused


def display_status(pane_id, status, focused):
    """herdr's status, with the sidebar's own "done" applied (see module doc)."""
    prev = LAST_STATUS.get(pane_id)
    LAST_STATUS[pane_id] = status
    if focused or status not in FINISHED:
        UNACKED.discard(pane_id)
    elif status == "done" or prev == "working":
        UNACKED.add(pane_id)
    return "done" if pane_id in UNACKED else status


class Client:
    """one request/response connection to the herdr socket (newline JSON).

    spawning the herdr CLI costs ~50 ms per call; a request over an open
    socket takes a few ms, which is what keeps the sidebar refresh snappy."""

    def __init__(self):
        self.sock = None
        self.buf = b""
        self.n = 0

    def request(self, method, params):
        for attempt in (1, 2):
            try:
                if self.sock is None:
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.settimeout(5)
                    self.sock.connect(SOCK)
                    self.buf = b""
                self.n += 1
                msg = {"id": f"pane-paths-watch:{self.n}", "method": method, "params": params}
                self.sock.sendall((json.dumps(msg) + "\n").encode())
                while b"\n" not in self.buf:
                    chunk = self.sock.recv(1 << 20)
                    if not chunk:
                        raise OSError("socket closed")
                    self.buf += chunk
                line, self.buf = self.buf.split(b"\n", 1)
                reply = json.loads(line)
                if "error" in reply:
                    log(f"{method} failed: {reply['error']}")
                    return None
                return reply.get("result")
            except (OSError, ValueError) as e:
                self.sock = None
                if attempt == 2:
                    log(f"{method} failed: {e}")
                    return None


client = Client()


def snapshot():
    result = client.request("session.snapshot", {})
    return result.get("snapshot") if result else None


def fingerprints(snap):
    """{workspace_id: fingerprint} of what the spaces rows depend on."""
    focused = snap.get("focused_pane_id")
    per_ws = {w["workspace_id"]: [] for w in snap.get("workspaces", [])}
    for p in snap.get("panes", []):
        per_ws.setdefault(p["workspace_id"], []).append((
            p["pane_id"], p.get("agent"), p.get("agent_status"),
            p.get("foreground_cwd") or p.get("cwd"),
            p["pane_id"] == focused,
        ))
    return {ws: tuple(rows) for ws, rows in per_ws.items()}


def agent_rows(snap):
    """{pane_id: (wanted_tokens, current_tokens)} for panes reporting a session.

    wanted maps every slot to its value or None (= cleared); current is what
    the snapshot shows for those slots, so a comparison catches tokens that
    went missing as well as ones that should change."""
    focused_ws = snap.get("focused_workspace_id")
    focused_pane = snap.get("focused_pane_id")
    rows = {}
    seen = set()
    for a in snap.get("agents", []):
        pane_id = a["pane_id"]
        seen.add(pane_id)
        status = a.get("agent_status") or "unknown"
        if status == "unknown":
            status = "idle"   # herdr's state_label() renders unknown as idle
        status = display_status(pane_id, status, pane_id == focused_pane)
        tokens = a.get("tokens") or {}
        session = tokens.get("session")
        if not session:
            continue
        same = a.get("workspace_id") == focused_ws
        name_slot = "name" if same else "name_other"
        # a foreign workspace dims only idle; anything that wants attention
        # (working / blocked / done) keeps its state colour everywhere
        state_slot = f"st_{status}" if same or status != "idle" else "st_other"
        wanted = {slot: (session if slot == name_slot else None) for slot in NAME_SLOTS}
        wanted.update({slot: (status if slot == state_slot else None) for slot in STATE_SLOTS})
        current = {slot: tokens.get(slot) for slot in NAME_SLOTS + STATE_SLOTS}
        rows[pane_id] = (wanted, current)
    for pane_id in list(LAST_STATUS):
        if pane_id not in seen:   # pane closed or agent gone
            LAST_STATUS.pop(pane_id, None)
            UNACKED.discard(pane_id)
    return rows


def push_agent_row(pane_id, tokens):
    # a null token value clears that token
    client.request("pane.report_metadata",
                   {"pane_id": pane_id, "source": "pane-view", "tokens": tokens})


def main():
    if already_running():
        return 0
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))

    def subscribe(subscriptions, request_id):
        """open a socket with one events.subscribe on it (see module doc)."""
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(SOCK)
        req = {"id": request_id, "method": "events.subscribe",
               "params": {"subscriptions": subscriptions}}
        sock.sendall((json.dumps(req) + "\n").encode())
        return sock

    try:
        main_sock = subscribe([{"type": t} for t in SUBSCRIPTIONS], "pane-paths-watch")
    except OSError as e:
        log(f"cannot connect to {SOCK}: {e}")
        return 1
    log("subscribed")

    sel = selectors.DefaultSelector()
    sel.register(main_sock, selectors.EVENT_READ, "main")
    status_socks = {}   # pane_id -> socket subscribed to that pane's status
    bufs = {}           # socket -> unread bytes

    lock = threading.Lock()
    work = threading.Lock()   # one refresh at a time (shared request socket)
    timer = [None]
    last = [{}]        # workspace fingerprints
    # time.monotonic() can start near zero with the process (macOS python),
    # so seed this far enough back that the first refresh() runs
    last_pass = [time.monotonic() - MIN_GAP]
    panes = [None]     # pane ids of the latest snapshot, read by the main loop

    def schedule(delay=DEBOUNCE):
        with lock:
            if timer[0]:
                timer[0].cancel()
            timer[0] = threading.Timer(delay, refresh)
            timer[0].daemon = True
            timer[0].start()

    def refresh():
        with lock:
            timer[0] = None
        now = time.monotonic()
        if now - last_pass[0] < MIN_GAP:
            schedule(MIN_GAP - (now - last_pass[0]))
            return
        last_pass[0] = now
        with work:
            refresh_locked()

    def refresh_locked():
        t0 = time.monotonic()
        snap = snapshot()
        if snap is None:
            return
        panes[0] = {p["pane_id"] for p in snap.get("panes", [])}
        current = fingerprints(snap)
        changed = [ws for ws, fp in current.items() if last[0].get(ws) != fp]
        last[0] = current
        for ws in changed:
            subprocess.Popen([SCRIPT, "-w", ws], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        rows = agent_rows(snap)
        repushed = [pid for pid, (wanted, current) in rows.items() if wanted != current]
        for pid in repushed:
            push_agent_row(pid, rows[pid][0])
        if changed or repushed:
            ms = (time.monotonic() - t0) * 1000
            log(f"refreshed spaces={' '.join(changed) or '-'} "
                f"agents={' '.join(repushed) or '-'} in {ms:.0f}ms")

    refresh()   # bring everything in line once at startup

    def drop_status(pane_id):
        sock = status_socks.pop(pane_id, None)
        if sock is None:
            return
        sel.unregister(sock)
        bufs.pop(sock, None)
        sock.close()

    def sync_status_subs():
        """one status subscription per pane in the latest snapshot.

        only run from the main loop (the selector is not thread-safe); the
        snapshot thread just publishes the pane set."""
        wanted = panes[0]
        if wanted is None:
            return
        for pane_id in list(status_socks):
            if pane_id not in wanted:
                drop_status(pane_id)
        for pane_id in wanted:
            if pane_id in status_socks:
                continue
            try:
                sock = subscribe([{"type": "pane.agent_status_changed", "pane_id": pane_id}],
                                 f"pane-paths-watch:status:{pane_id}")
            except OSError as e:
                log(f"status subscription for {pane_id} failed: {e}")
                continue
            status_socks[pane_id] = sock
            sel.register(sock, selectors.EVENT_READ, pane_id)

    def handle(sock, tag):
        """read what arrived on one socket; False once it is gone."""
        chunk = sock.recv(65536)
        if not chunk:
            return False
        buf = bufs.get(sock, b"") + chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            try:
                msg = json.loads(line)
            except ValueError:
                continue
            if "error" in msg:
                log(f"error on {tag}: {msg['error']}")
                continue
            if "result" in msg:
                continue
            # focus moves and state changes are what the user is waiting
            # on: refresh at once. everything else (pane output revisions
            # arrive at ~10 Hz while an agent streams) is debounced.
            schedule(0 if msg.get("event") in URGENT_EVENTS else DEBOUNCE)
        bufs[sock] = buf
        return True

    while True:
        sync_status_subs()
        for key, _ in sel.select(timeout=1.0):
            sock, tag = key.fileobj, key.data
            try:
                alive = handle(sock, tag)
            except OSError:
                alive = False
            if alive:
                continue
            if tag == "main":
                log("socket closed, exiting")
                break
            # herdr closes a status socket when its pane goes away (or
            # rejected the pane); sync re-subscribes if the pane still exists
            drop_status(tag)
        else:
            continue
        break
    try:
        os.remove(PIDFILE)
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
