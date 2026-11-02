#!/bin/bash

# sync ALL setting files between this repo (git) and local (~).
# convention: put a file under src/home/ mirroring its path in $HOME
# (e.g. src/home/.config/ghostty/config -> ~/.config/ghostty/config)
# and it is picked up automatically — no per-file line needed.
# NOTE: managed file paths must not contain spaces.

cd "$(dirname "$0")/.." || exit 1

source ./bin/sync_setting.sh

# ~/.claude/settings.json is rewritten by claude code itself (model,
# permissions, ...) so it is not synced as a whole file — syncing it would
# show a diff on every run. instead the keys in src/claude/settings-fragment.json
# (statusLine, timestamp hooks, ...) are deep-merged into it and every other
# key is left alone. the timestamp hooks print display-only systemMessage
# lines (💬 on prompt / 🔧 before each tool call / 🤖 on response) that never
# reach the model. the time is wrapped in \u001b[31m -- a raw ESC byte would
# be invalid json.
#
# jq's `*` replaces lists, which is what permissions.deny wants, but under
# "hooks" other tools add their own entries next to ours (herdr integration
# installs one on PreToolUse etc.). so for each event the fragment defines,
# the merged list is the local entries the fragment does not contain (compared
# by their inner "hooks" commands) followed by the fragment's entries.
#
# the same merge is applied to ~/.claude.json (user-scope MCP servers live
# under its mcpServers key, next to session metadata) with
# src/claude/mcp-fragment.json. merge only adds/overwrites: a server removed
# from the fragment must be removed by hand with `claude mcp remove <name>`.
# OAuth tokens for MCP servers live in the Keychain, so a new machine still
# needs a one-time `/mcp` -> Authenticate inside claude.
# run this while claude is not running: it rewrites both files itself and a
# concurrent write could drop the merge.
#
# mergeClaudeFragment <target json> <fragment json>
function mergeClaudeFragment() {
    SETTINGS=$1
    FRAGMENT=$2

    echo ""
    echo "=== claude managed keys (${SETTINGS}) ==="

    if ! hash jq 2>/dev/null; then
        echo "jq not found. merge ${FRAGMENT} into ${SETTINGS} manually."
        return 0
    fi

    mkdir -p "$(dirname "$SETTINGS")"
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

    MERGE_JQ='
        def merge_hooks($local; $frag):
            reduce ($frag | keys[]) as $ev ($local;
                .[$ev] = (($local[$ev] // [])
                          | map(select(.hooks as $h | ($frag[$ev] | any(.hooks == $h)) | not)))
                         + $frag[$ev]);
        . as [$local, $frag]
        | ($local * $frag)
        | if ($frag | has("hooks")) then .hooks = merge_hooks($local.hooks // {}; $frag.hooks) else . end
    '

    TMP=$(mktemp)
    if ! jq -s "$MERGE_JQ" "$SETTINGS" "$FRAGMENT" > "$TMP" 2>/dev/null || [ ! -s "$TMP" ]; then
        /bin/rm -f "$TMP"
        echo "failed to update ${SETTINGS} (invalid json?). merge ${FRAGMENT} manually."
        return 0
    fi

    if jq -e -s '.[0] == .[1]' "$SETTINGS" "$TMP" >/dev/null 2>&1; then
        /bin/rm -f "$TMP"
        echo "OK: managed keys already set."
        return 0
    fi

    # -p / cat > keep the target's mode (~/.claude.json is 600) on both copies
    cp -p "$SETTINGS" "${SETTINGS}.bak"
    cat "$TMP" > "$SETTINGS" && /bin/rm -f "$TMP"
    echo "merged: $(jq -r 'keys | join(", ")' "$FRAGMENT")"
    echo "        (backup: ${SETTINGS}.bak)"
}

HOME_SRC=./src/home
for GIT_FILE in $(find "$HOME_SRC" -type f ! -name .DS_Store | sort); do
    REL_PATH=${GIT_FILE#"$HOME_SRC"/}
    syncSettingFile "$REL_PATH" "$GIT_FILE" ~/"$REL_PATH"
done

mergeClaudeFragment ~/.claude/settings.json ./src/claude/settings-fragment.json
mergeClaudeFragment ~/.claude.json         ./src/claude/mcp-fragment.json
