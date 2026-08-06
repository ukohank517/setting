#!/bin/bash

# sync ALL setting files between this repo (git) and local (~).
# convention: put a file under src/home/ mirroring its path in $HOME
# (e.g. src/home/.config/ghostty/config -> ~/.config/ghostty/config)
# and it is picked up automatically — no per-file line needed.
# NOTE: managed file paths must not contain spaces.

cd "$(dirname "$0")/.." || exit 1

source ./bin/sync_setting.sh

HOME_SRC=./src/home
for GIT_FILE in $(find "$HOME_SRC" -type f ! -name .DS_Store | sort); do
    REL_PATH=${GIT_FILE#"$HOME_SRC"/}
    syncSettingFile "$REL_PATH" "$GIT_FILE" ~/"$REL_PATH"
done
