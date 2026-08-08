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
# show a diff on every run. only the statusLine key is wired up here, so
# the synced statusline.sh actually runs (it also feeds herdr's sidebar).
function ensureClaudeStatusLine() {
    SETTINGS=~/.claude/settings.json
    WANT="bash ~/.claude/statusline.sh"

    echo ""
    echo "=== claude statusLine (${SETTINGS}) ==="

    if ! hash jq 2>/dev/null; then
        echo "jq not found. set it manually:"
        echo "  \"statusLine\": { \"type\": \"command\", \"command\": \"${WANT}\" }"
        return 0
    fi

    mkdir -p "$(dirname "$SETTINGS")"
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

    CURRENT=$(jq -r '.statusLine.command // ""' "$SETTINGS" 2>/dev/null)
    if [ "$CURRENT" = "$WANT" ]; then
        echo "OK: statusLine already set."
        return 0
    fi

    TMP=$(mktemp)
    if jq --arg cmd "$WANT" '.statusLine = {type: "command", command: $cmd}' \
            "$SETTINGS" > "$TMP" 2>/dev/null && [ -s "$TMP" ]; then
        cp "$SETTINGS" "${SETTINGS}.bak"
        mv "$TMP" "$SETTINGS"
        echo "set: statusLine -> ${WANT} (was: ${CURRENT:-<not set>})"
        echo "     (backup: ${SETTINGS}.bak)"
    else
        /bin/rm -f "$TMP"
        echo "failed to update ${SETTINGS} (invalid json?). set statusLine manually."
    fi
}

HOME_SRC=./src/home
for GIT_FILE in $(find "$HOME_SRC" -type f ! -name .DS_Store | sort); do
    REL_PATH=${GIT_FILE#"$HOME_SRC"/}
    syncSettingFile "$REL_PATH" "$GIT_FILE" ~/"$REL_PATH"
done

ensureClaudeStatusLine
