#!/bin/bash

# push one row per pane of a workspace into herdr's sidebar spaces rows as
# $path1..$pathN workspace tokens (see [ui.sidebar.spaces] in config.toml):
# "<state> <cwd>", e.g. "● ukohank517/setting". herdr tracks pane cwds and
# agent states itself but has no built-in spaces token for either.
#
# the state mark mirrors herdr's state_dot() (src/ui/status.rs) in shape only,
# since a token has a single colour: ● agent working, ◆ agent blocked
# (herdr draws that as a red ●), ○ agent idle, · no agent (a plain shell).
# it is refreshed whenever this script runs, i.e. on cd in a shell pane and
# on every claude code status update, not on the state change itself.
#
# usage: report-pane-paths.sh [PANE_ID [CWD]]
#   PANE_ID  any pane of the target workspace (default: $HERDR_PANE_ID)
#   CWD      that pane's current directory, used instead of what herdr has
#            polled so far (shell precmd fires before herdr notices a cd)
#
# callers: the herdr precmd hook in .zshrc/.bashrc (on every cd) and
# .claude/statusline.sh (on every claude code status update). a closed pane
# stays listed until the next call from a sibling pane.

pane=${1:-$HERDR_PANE_ID}
override_cwd=$2
[ -n "$pane" ] || exit 0

MAX=6                          # must match the $pathN rows in config.toml
STRIP_PREFIX="$HOME/workspace/"  # common repo root, dropped to save columns
ELLIPSIS="…"                   # marks a path whose head was cut off
FALLBACK_WIDTH=26              # row width when the sidebar width is unknown

herdr=$(command -v herdr || echo /opt/homebrew/bin/herdr)
[ -x "$herdr" ] && hash jq 2>/dev/null || exit 0

list=$("$herdr" pane list 2>/dev/null) || exit 0

# herdr truncates overlong tokens at the END ("~/a/b/c/…"), which hides the
# part of a path that matters. so cut the HEAD here to the width the row
# actually has: the sidebar width is the x offset of the pane area in the
# snapshot; minus 1 for the sidebar divider, up to 1 for a scrollbar and 3
# for the indent of non-name rows (see render_workspace_list() in herdr's
# src/ui/sidebar.rs). worktree children are indented 5 more and still get
# herdr's end-truncation.
sidebar_w=$("$herdr" api snapshot 2>/dev/null \
    | jq -r '.result.snapshot.layouts[0].area.x // empty' 2>/dev/null)
if [ -n "$sidebar_w" ] && [ "$sidebar_w" -gt 10 ] 2>/dev/null; then
    width=$((sidebar_w - 5))
else
    width=$FALLBACK_WIDTH
fi

ws=$(jq -r --arg p "$pane" \
    '.result.panes[] | select(.pane_id == $p) | .workspace_id' <<<"$list" | head -n1)
[ -n "$ws" ] || exit 0

# "<state>\t<cwd>" for every pane in the workspace, pane order.
rows=$(jq -r --arg ws "$ws" --arg p "$pane" --arg o "$override_cwd" '
    .result.panes[]
    | select(.workspace_id == $ws)
    | [ (if .agent == null then "shell" else (.agent_status // "unknown") end),
        (if .pane_id == $p and $o != "" then $o else (.foreground_cwd // .cwd // "") end)
      ] | @tsv' <<<"$list")

args=()
i=0
width=$((width - 2))   # "<mark> " in front of every path
while IFS=$'\t' read -r state p; do
    [ -n "$p" ] || continue
    i=$((i + 1))
    [ "$i" -gt "$MAX" ] && break
    case "$state" in
        working) mark="●" ;;
        blocked) mark="◆" ;;
        idle|done) mark="○" ;;
        *) mark="·" ;;
    esac
    p=${p#"$STRIP_PREFIX"}
    p=${p/#$HOME/~}   # an escaped \~ here would insert a literal backslash
    if [ "${#p}" -gt "$width" ]; then
        # drop leading directories until "…/rest" fits; if even the last
        # component is too long, cut it mid-way instead.
        rest=$p
        while [ $(( ${#ELLIPSIS} + 1 + ${#rest} )) -gt "$width" ] && [[ "$rest" == */* ]]; do
            rest=${rest#*/}
        done
        if [ $(( ${#ELLIPSIS} + 1 + ${#rest} )) -le "$width" ]; then
            p="$ELLIPSIS/$rest"
        else
            keep=$((width - ${#ELLIPSIS}))
            p="$ELLIPSIS${p: -$keep}"
        fi
    fi
    args+=(--token "path$i=$mark $p")
done <<<"$rows"
for ((j = i + 1; j <= MAX; j++)); do
    args+=(--clear-token "path$j")
done

exec "$herdr" workspace report-metadata "$ws" --source pane-paths "${args[@]}" >/dev/null 2>&1
