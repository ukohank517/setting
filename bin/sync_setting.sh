#!/bin/bash

# common function to sync a setting file between this repo (git) and local (~).
#  - local file not exist  : copy git -> local
#  - same                  : just report
#  - different             : show diff, then ask which way to sync
# usage: source ./bin/sync_setting.sh

# arrow-key menu (up/down or j/k, enter to decide).
# cursor starts on the LAST option, so plain enter picks the safe one (skip).
# $@: options, selected index (0-based) -> SELECT_RESULT
function selectMenu() {
    local options=("$@")
    local count=$#
    local idx=$((count - 1))
    local i key key2

    # not a terminal (e.g. piped): fall back to number input
    if [ ! -t 0 ]; then
        for ((i=0; i<count; i++)); do
            echo "  $((i+1))) ${options[$i]}"
        done
        read -p "select [1-${count}]: " key
        case "$key" in
            [0-9]) SELECT_RESULT=$((key-1));;
            *)     SELECT_RESULT=$((count-1));; # default: last option (skip)
        esac
        return 0
    fi

    while true; do
        for ((i=0; i<count; i++)); do
            if [ $i -eq $idx ]; then
                echo -e "  \033[7m> ${options[$i]}\033[0m"
            else
                echo "    ${options[$i]}"
            fi
        done
        IFS= read -rsn1 key
        if [ "$key" = $'\e' ]; then
            IFS= read -rsn2 -t 1 key2
            key="$key$key2"
        fi
        case "$key" in
            $'\e[A'|k) idx=$(( (idx - 1 + count) % count ));;
            $'\e[B'|j) idx=$(( (idx + 1) % count ));;
            "")        SELECT_RESULT=$idx; return 0;; # enter
        esac
        printf "\033[%dA" "$count" # move cursor up to redraw menu
    done
}

# $1: name, $2: git-managed file, $3: local path
function syncSettingFile() {
    NAME=$1
    GIT_FILE=$2
    LOCAL_FILE=$3

    echo ""
    echo "=== ${NAME} (${LOCAL_FILE}) ==="

    # local not exist: default behavior, copy from git
    if [ ! -e "$LOCAL_FILE" ]; then
        echo "local file not exist. copy git -> local"
        mkdir -p "$(dirname "$LOCAL_FILE")"
        cp "$GIT_FILE" "$LOCAL_FILE"
        return 0
    fi

    # same: nothing to do
    if cmp -s "$GIT_FILE" "$LOCAL_FILE"; then
        echo "OK: git and local are identical."
        return 0
    fi

    # different: show diff and ask
    echo "git and local are different:"
    echo "--------------------------------------------------"
    diff -u "$GIT_FILE" "$LOCAL_FILE" \
        | sed -e "s|^--- .*|--- git   : $GIT_FILE|" -e "s|^+++ .*|+++ local : $LOCAL_FILE|" \
        | awk '
            /^@@/  { printf "\033[36m%s\033[0m\n", $0; next }  # hunk header: cyan
            /^-/   { printf "\033[31m%s\033[0m\n", $0; next }  # git side   : red
            /^\+/  { printf "\033[32m%s\033[0m\n", $0; next }  # local side : green
                   { print }
        '
    echo "--------------------------------------------------"
    # repeat the target here: with a long diff, the header has scrolled away
    echo "how to sync? -> ${NAME} (${LOCAL_FILE})"
    selectMenu \
        "local -> git   (copy local file into this repo)" \
        "git -> local   (overwrite local file)" \
        "merge manually (vimdiff. left=local, right=git. after save&quit, local is copied to git)" \
        "skip"

    case "$SELECT_RESULT" in
        0)
            cp "$LOCAL_FILE" "$GIT_FILE"
            echo "done: local -> git. check 'git diff' and commit it."
            ;;
        1)
            cp "$LOCAL_FILE" "${LOCAL_FILE}.bak"
            cp "$GIT_FILE" "$LOCAL_FILE"
            echo "done: git -> local. (backup: ${LOCAL_FILE}.bak)"
            ;;
        2)
            vimdiff "$LOCAL_FILE" "$GIT_FILE"
            if cmp -s "$GIT_FILE" "$LOCAL_FILE"; then
                echo "done: merged, git and local are identical."
            else
                read -p "copy merged local -> git? [y/N]: " YN
                if [ "$YN" = "y" ] || [ "$YN" = "Y" ]; then
                    cp "$LOCAL_FILE" "$GIT_FILE"
                    echo "done: local -> git. check 'git diff' and commit it."
                else
                    echo "skipped copy. git and local are still different."
                fi
            fi
            ;;
        *)
            echo "skipped."
            ;;
    esac
}
