#!/usr/bin/env python3
"""keep herdr's spaces pane-path rows current by listening to herdr events.

report-pane-paths.sh renders "<state> <cwd>" rows per workspace, but it only
runs when something calls it (shell cd, claude code status update). focus
moves, agent state changes and pane open/close happen without either, so
this watcher subscribes to herdr's newline-delimited JSON socket API and
re-runs the script for the workspaces whose rows would change.

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
import socket
import subprocess
import sys
import threading
import time

HERDR_DIR = os.path.expanduser("~/.config/herdr")
SOCK = os.path.join(HERDR_DIR, "herdr.sock")
PIDFILE = os.path.join(HERDR_DIR, "pane-paths-watch.pid")
SCRIPT = os.path.join(HERDR_DIR, "report-pane-paths.sh")
DEBOUNCE = 0.2   # seconds of quiet before looking at the snapshot
MIN_GAP = 0.5    # seconds between two refresh passes, whatever happens

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


def fingerprints():
    """{workspace_id: fingerprint} from one snapshot; None if herdr is gone."""
    try:
        out = subprocess.run(["herdr", "api", "snapshot"], capture_output=True,
                             text=True, timeout=5).stdout
        snap = json.loads(out)["result"]["snapshot"]
    except Exception as e:  # noqa: BLE001
        log(f"snapshot failed: {e}")
        return None
    focused = snap.get("focused_pane_id")
    per_ws = {w["workspace_id"]: [] for w in snap.get("workspaces", [])}
    for p in snap.get("panes", []):
        per_ws.setdefault(p["workspace_id"], []).append((
            p["pane_id"], p.get("agent"), p.get("agent_status"),
            p.get("foreground_cwd") or p.get("cwd"),
            p["pane_id"] == focused,
        ))
    return {ws: tuple(rows) for ws, rows in per_ws.items()}


def main():
    if already_running():
        return 0
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(SOCK)
    except OSError as e:
        log(f"cannot connect to {SOCK}: {e}")
        return 1
    req = {"id": "pane-paths-watch", "method": "events.subscribe",
           "params": {"subscriptions": [{"type": t} for t in SUBSCRIPTIONS]}}
    s.sendall((json.dumps(req) + "\n").encode())
    log("subscribed")

    lock = threading.Lock()
    timer = [None]
    last = [fingerprints() or {}]
    last_pass = [0.0]

    def refresh():
        with lock:
            timer[0] = None
        now = time.monotonic()
        if now - last_pass[0] < MIN_GAP:
            schedule(MIN_GAP - (now - last_pass[0]))
            return
        last_pass[0] = now
        current = fingerprints()
        if current is None:
            return
        changed = [ws for ws, fp in current.items() if last[0].get(ws) != fp]
        last[0] = current
        for ws in changed:
            subprocess.Popen([SCRIPT, "-w", ws], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        if changed:
            log(f"refreshed {' '.join(changed)}")

    def schedule(delay=DEBOUNCE):
        with lock:
            if timer[0]:
                timer[0].cancel()
            timer[0] = threading.Timer(delay, refresh)
            timer[0].daemon = True
            timer[0].start()

    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            log("socket closed, exiting")
            break
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            try:
                msg = json.loads(line)
            except ValueError:
                continue
            if "error" in msg:
                log(f"error: {msg['error']}")
                continue
            if "result" in msg:
                continue
            schedule()
    try:
        os.remove(PIDFILE)
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
