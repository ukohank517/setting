#!/bin/bash

# Claude Code statusLine script.
# - prints a status line inside claude code (model | context % | usage limits)
# - mirrors account usage limits (/usage の 5h・7d ウィンドウ) into herdr's
#   sidebar spaces rows via workspace metadata ($usage / $week tokens,
#   see [ui.sidebar.spaces] in src/home/.config/herdr/config.toml).
#   account-wide values, so they are pinned to the top workspace only.

input=$(cat)

IFS=$'\t' read -r model ctx five five_reset seven seven_reset <<EOF
$(echo "$input" | jq -r '
  [ (.model.display_name // "?"),
    (.context_window.used_percentage // -1 | floor),
    (.rate_limits.five_hour.used_percentage // -1 | floor),
    (.rate_limits.five_hour.resets_at // 0),
    (.rate_limits.seven_day.used_percentage // -1 | floor),
    (.rate_limits.seven_day.resets_at // 0)
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

# per-pane row in herdr's agents sidebar: context usage + 5h reset
if [ -n "$HERDR_PANE_ID" ] && [ -x "$HERDR_BIN" ]; then
    args=()
    [ "$ctx" -ge 0 ] && args+=(--token "usage=CTX ${ctx}%")
    if [ "$five_reset" -gt 0 ]; then
        args+=(--token "reset=↻$(date -r "$five_reset" '+%m/%d %H:%M')")
    fi
    if [ ${#args[@]} -gt 0 ]; then
        "$HERDR_BIN" pane report-metadata "$HERDR_PANE_ID" \
            --source claude-statusline "${args[@]}" >/dev/null 2>&1 &
    fi
fi

# spaces rows in herdr's sidebar: account-wide usage limits.
# the values are global to the account, so they are pinned to the sidebar's
# top workspace instead of the one this session runs in — one row, no
# duplicates, and unaffected by panes moving between workspaces.
if [ "$HERDR_ENV" = 1 ] && [ -x "$HERDR_BIN" ]; then
    args=()
    [ -n "$usage5h" ] && args+=(--token "usage=$usage5h")
    [ -n "$usage7d" ] && args+=(--token "week=$usage7d")
    if [ ${#args[@]} -gt 0 ]; then
        (
            top_ws=$("$HERDR_BIN" workspace list 2>/dev/null \
                | jq -r '.result.workspaces[0].workspace_id // empty')
            [ -n "$top_ws" ] && "$HERDR_BIN" workspace report-metadata "$top_ws" \
                --source claude-statusline "${args[@]}"
        ) >/dev/null 2>&1 &
    fi
fi
