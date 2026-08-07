#!/bin/bash

# login shell setup: keep the login shell on bash.
# recent macOS ships zsh as the default, so on a fresh machine this
# switches it back to bash and takes the zsh history along.
# sourced by bin/mac_check.sh (needs bin/mac_lib.sh).

# $1: old history file, $2: history file to append into.
# 取り込み先にまだ無い行だけを末尾に足す (取り込み先の並び順は壊さない)。
function migrateHistory() {
    OLD_HIST=$1
    NEW_HIST=$2

    if [ ! -f "$OLD_HIST" ]; then
        printInfo "no history file to migrate: $OLD_HIST"
        return 0
    fi

    touch "$NEW_HIST"
    TMP_HIST=$(mktemp)
    # -F -x: exact whole-line match, -a: history may contain non-UTF8 bytes
    LC_ALL=C grep -avxFf "$NEW_HIST" "$OLD_HIST" > "$TMP_HIST" || true
    if [ -s "$TMP_HIST" ]; then
        cat "$TMP_HIST" >> "$NEW_HIST"
        printInfo "migrated $(wc -l < "$TMP_HIST" | tr -d ' ') history lines from $OLD_HIST"
    else
        printInfo "no new history lines to migrate from $OLD_HIST"
    fi
    /bin/rm -f "$TMP_HIST"
}

function setupDefaultShell() {
    printTitle "Login Shell Check"

    CURRENT_SHELL=$(dscl . -read ~/ UserShell | awk '{print $2}')

    if [ "$CURRENT_SHELL" = "/bin/bash" ]; then
        printInfo "login shell is already bash"
        return 0
    fi

    printInfo "current login shell: $CURRENT_SHELL"

    # chsh の前に履歴を移行しておく (chsh に失敗しても再実行で拾える)
    case "$CURRENT_SHELL" in
        */zsh) migrateHistory ~/.zsh_history ~/.bash_history ;;
        *)     printInfo "unknown shell, skip history migration" ;;
    esac

    printInfo "changing login shell to /bin/bash (password may be asked)"
    if chsh -s /bin/bash; then
        printInfo "done. new terminals will start bash."
    else
        printError "chsh failed. run manually: chsh -s /bin/bash"
    fi
}
