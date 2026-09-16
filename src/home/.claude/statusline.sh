#!/bin/bash

# Claude Code statusLine script.
# - prints a status line inside claude code (model | context % | usage limits)
# - mirrors the same data into this pane's rows in herdr's agents sidebar via
#   pane metadata tokens (see [ui.sidebar.agents.rows_by_agent] in
#   src/home/.config/herdr/config.toml):
#     $name  claude code session name (what /list-agents and SendMessage use,
#            e.g. "setting-42")
#     $ctx   context window usage of this session
#     $five  5h account usage window: bar, percent, reset time
#     $week  7d account usage window: bar, percent, reset date
#   the 5h/7d limits are account-wide, so every claude pane shows the same
#   values; they used to sit on the top workspace's spaces rows instead.

input=$(cat)

# every field gets a non-empty default: IFS=tab collapses consecutive tabs,
# so an empty field would shift the ones after it.
IFS=$'\t' read -r model ctx five five_reset seven seven_reset session_id <<EOF
$(echo "$input" | jq -r '
  [ (.model.display_name // "?"),
    (.context_window.used_percentage // -1 | floor),
    (.rate_limits.five_hour.used_percentage // -1 | floor),
    (.rate_limits.five_hour.resets_at // 0),
    (.rate_limits.seven_day.used_percentage // -1 | floor),
    (.rate_limits.seven_day.resets_at // 0),
    (.session_id // "-")
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

line="$model"
[ "$ctx" -ge 0 ] && line="$line | CTX ${ctx}%"
[ -n "$usage5h" ] && line="$line | $usage5h"
[ -n "$usage7d" ] && line="$line | $usage7d"
echo "$line"

HERDR_BIN=$(command -v herdr || echo /opt/homebrew/bin/herdr)

# claude code's session name (what /list-agents shows). claude writes one
# ~/.claude/sessions/<pid>.json per live session with sessionId and name;
# match on session_id, falling back to our parent pid (the claude process).
session_name=""
if [ -n "$HERDR_PANE_ID" ] && hash jq 2>/dev/null; then
    if [ "$session_id" != "-" ]; then
        session_name=$(jq -r --arg sid "$session_id" \
            'select(.sessionId == $sid) | .name // empty' \
            ~/.claude/sessions/*.json 2>/dev/null | head -n1)
    fi
    if [ -z "$session_name" ] && [ -f ~/.claude/sessions/"$PPID".json ]; then
        session_name=$(jq -r '.name // empty' ~/.claude/sessions/"$PPID".json 2>/dev/null)
    fi
fi

# per-pane rows in herdr's agents sidebar (all pushed under one source, so
# a value that disappears from the input is cleared rather than left stale).
if [ -n "$HERDR_PANE_ID" ] && [ -x "$HERDR_BIN" ]; then
    args=()
    if [ -n "$session_name" ]; then
        args+=(--token "name=$session_name")
    else
        args+=(--clear-token name)
    fi
    if [ "$ctx" -ge 0 ]; then
        args+=(--token "ctx=CTX ${ctx}%")
    else
        args+=(--clear-token ctx)
    fi
    if [ -n "$usage5h" ]; then
        args+=(--token "five=$usage5h")
    else
        args+=(--clear-token five)
    fi
    if [ -n "$usage7d" ]; then
        args+=(--token "week=$usage7d")
    else
        args+=(--clear-token week)
    fi
    "$HERDR_BIN" pane report-metadata "$HERDR_PANE_ID" \
        --source claude-statusline "${args[@]}" >/dev/null 2>&1 &

    # refresh this workspace's pane-path list in the spaces rows ($path1..)
    if [ -x ~/.config/herdr/report-pane-paths.sh ]; then
        ~/.config/herdr/report-pane-paths.sh "$HERDR_PANE_ID" >/dev/null 2>&1 &
    fi
fi
