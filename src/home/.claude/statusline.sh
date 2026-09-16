#!/bin/bash

# Claude Code statusLine script.
# - prints a status line inside claude code
#   ("@session(model) | context % | usage limits", e.g. "@setting-42(Fable) | CTX 4% | ...";
#   the session name leads because it is what tells panes apart, the model
#   rarely changes. it falls back to just the model when no name resolves)
# - mirrors the same data into this pane's rows in herdr's agents sidebar via
#   pane metadata tokens (see [ui.sidebar.agents.rows_by_agent] in
#   src/home/.config/herdr/config.toml):
#     $session  claude code session name (what /list-agents and SendMessage
#               use, e.g. "setting-42"). not shown directly: pane-paths-watch.py
#               copies it into $name (pane in the focused workspace, bright)
#               or $name_other (any other workspace, dim), next to a state
#               token it colours the same way, so agents of the selected
#               workspace stand out from the rest.
#     $ctx    context window usage of this session: bar, percent, then the
#             agent name ("CTX ████░░░░ 17% claude"). the agent name rides in
#             this token because herdr joins separate tokens with " · ".
#     $five   5h account usage window: bar, percent, reset time
#     $week   7d account usage window: bar, percent, reset date
# - keeps this pane's border title at "<cwd> (<git branch>)", the same format
#   the shell precmd hook in .zshrc/.bashrc uses, so a checkout made from
#   inside claude code shows up on the pane border too.
#   the three bar rows pad their labels to 3 columns ("CTX", "5h ", "7d ") so
#   the bars line up; herdr trims leading spaces, so the pad goes after the
#   label.
#   the 5h/7d limits are account-wide, so every claude pane shows the same
#   values; they used to sit on the top workspace's spaces rows instead.

input=$(cat)

# every field gets a non-empty default: IFS=tab collapses consecutive tabs,
# so an empty field would shift the ones after it.
IFS=$'\t' read -r model ctx five five_reset seven seven_reset session_id cwd <<EOF
$(echo "$input" | jq -r '
  [ (.model.display_name // "?"),
    (.context_window.used_percentage // -1 | floor),
    (.rate_limits.five_hour.used_percentage // -1 | floor),
    (.rate_limits.five_hour.resets_at // 0),
    (.rate_limits.seven_day.used_percentage // -1 | floor),
    (.rate_limits.seven_day.resets_at // 0),
    (.session_id // "-"),
    (.workspace.current_dir // .cwd // "-")
  ] | @tsv')
EOF

# render an 8-cell percent bar like ██░░░░░░
bar() {
    local pct=$1 cells=8 filled=0 i out=""
    filled=$(( (pct * cells + 50) / 100 ))
    [ "$filled" -gt "$cells" ] && filled=$cells
    for ((i = 0; i < cells; i++)); do
        [ "$i" -lt "$filled" ] && out+="█" || out+="░"
    done
    printf '%s' "$out"
}

usage5h=""
if [ "$five" -ge 0 ]; then
    usage5h="5h $(bar "$five") ${five}%"
    [ "$five_reset" -gt 0 ] && usage5h="$usage5h ↻$(date -r "$five_reset" '+%H:%M')"
fi

usage7d=""
if [ "$seven" -ge 0 ]; then
    usage7d="7d $(bar "$seven") ${seven}%"
    [ "$seven_reset" -gt 0 ] && usage7d="$usage7d ↻$(date -r "$seven_reset" '+%m/%d')"
fi

# claude code's session name (what /list-agents shows). claude writes one
# ~/.claude/sessions/<pid>.json per live session with sessionId and name;
# match on session_id, falling back to our parent pid (the claude process).
session_name=""
if hash jq 2>/dev/null; then
    if [ "$session_id" != "-" ]; then
        session_name=$(jq -r --arg sid "$session_id" \
            'select(.sessionId == $sid) | .name // empty' \
            ~/.claude/sessions/*.json 2>/dev/null | head -n1)
    fi
    if [ -z "$session_name" ] && [ -f ~/.claude/sessions/"$PPID".json ]; then
        session_name=$(jq -r '.name // empty' ~/.claude/sessions/"$PPID".json 2>/dev/null)
    fi
fi

if [ -n "$session_name" ]; then
    line="@$session_name($model)"
else
    line="$model"
fi
[ "$ctx" -ge 0 ] && line="$line | CTX ${ctx}%"
[ -n "$usage5h" ] && line="$line | $usage5h"
[ -n "$usage7d" ] && line="$line | $usage7d"
echo "$line"

HERDR_BIN=$(command -v herdr || echo /opt/homebrew/bin/herdr)

# per-pane rows in herdr's agents sidebar (all pushed under one source, so
# a value that disappears from the input is cleared rather than left stale).
if [ -n "$HERDR_PANE_ID" ] && [ -x "$HERDR_BIN" ]; then
    args=()
    if [ -n "$session_name" ]; then
        args+=(--token "session=$session_name")
    else
        args+=(--clear-token session)
    fi
    if [ "$ctx" -ge 0 ]; then
        args+=(--token "ctx=CTX $(bar "$ctx") ${ctx}% claude")
    else
        args+=(--clear-token ctx)
    fi
    if [ -n "$usage5h" ]; then
        args+=(--token "five=${usage5h/#5h /5h  }")
    else
        args+=(--clear-token five)
    fi
    if [ -n "$usage7d" ]; then
        args+=(--token "week=${usage7d/#7d /7d  }")
    else
        args+=(--clear-token week)
    fi
    "$HERDR_BIN" pane report-metadata "$HERDR_PANE_ID" \
        --source claude-statusline "${args[@]}" >/dev/null 2>&1 &

    # pane border title: "<cwd> (<branch>)", same format as the shell hook.
    # this script runs several times a second while claude streams, so only
    # send the title when it differs from the last one sent for this pane.
    if [ "$cwd" != "-" ] && [ -d "$cwd" ]; then
        branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
            || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
        title="${cwd/#$HOME/~}${branch:+ ($branch)}"
        stamp="${TMPDIR:-/tmp}/herdr-pane-title-${HERDR_PANE_ID//[^A-Za-z0-9]/_}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$title" ]; then
            printf '%s' "$title" > "$stamp"
            "$HERDR_BIN" pane rename "$HERDR_PANE_ID" "$title" >/dev/null 2>&1 &
        fi
    fi

    # the spaces pane-path rows ($path1.., ~/.config/herdr/report-pane-paths.sh)
    # are kept current by pane-paths-watch.py, which reacts to the pane
    # metadata pushed above. just make sure that watcher is alive; it exits
    # with the herdr server.
    watcher=~/.config/herdr/pane-paths-watch.py
    pidfile=~/.config/herdr/pane-paths-watch.pid
    if [ -f "$watcher" ] && hash python3 2>/dev/null \
        && ! { [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; }; then
        nohup python3 "$watcher" >>~/.config/herdr/pane-paths-watch.log 2>&1 </dev/null &
    fi
fi
