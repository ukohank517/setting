#!/bin/bash

# login shell setup: switch the default shell to zsh, migrating the old
# shell's history. sourced by bin/mac_check.sh (needs bin/mac_lib.sh).

# $1: old history file — 旧シェルの履歴を ~/.zsh_history に取り込む。
# 既存のzsh履歴に無い行だけを先頭側に足す (zsh側のエントリが新しいまま残る)。
function migrateHistoryToZsh() {
    OLD_HIST=$1
    ZSH_HIST=~/.zsh_history

    if [ ! -f "$OLD_HIST" ]; then
        printInfo "no history file to migrate: $OLD_HIST"
        return 0
    fi

    touch "$ZSH_HIST"
    TMP_HIST=$(mktemp)
    # -F -x: exact whole-line match, -a: history may contain non-UTF8 bytes
    LC_ALL=C grep -avxFf "$ZSH_HIST" "$OLD_HIST" > "$TMP_HIST" || true
    if [ -s "$TMP_HIST" ]; then
        cat "$TMP_HIST" "$ZSH_HIST" > "${ZSH_HIST}.new" && mv "${ZSH_HIST}.new" "$ZSH_HIST"
        printInfo "migrated $(wc -l < "$TMP_HIST" | tr -d ' ') history lines from $OLD_HIST"
    else
        printInfo "no new history lines to migrate from $OLD_HIST"
    fi
    /bin/rm -f "$TMP_HIST"
}

function setupDefaultShell() {
    printTitle "Login Shell Check"

    CURRENT_SHELL=$(dscl . -read ~/ UserShell | awk '{print $2}')

    if [ "$CURRENT_SHELL" = "/bin/zsh" ]; then
        printInfo "login shell is already zsh"
        return 0
    fi

    printInfo "current login shell: $CURRENT_SHELL"

    # chsh の前に履歴を移行しておく (chsh に失敗しても再実行で拾える)
    case "$CURRENT_SHELL" in
        */bash) migrateHistoryToZsh ~/.bash_history ;;
        *)      printInfo "unknown shell, skip history migration" ;;
    esac

    printInfo "changing login shell to /bin/zsh (password may be asked)"
    if chsh -s /bin/zsh; then
        printInfo "done. new terminals will start zsh."
    else
        printError "chsh failed. run manually: chsh -s /bin/zsh"
    fi
}
