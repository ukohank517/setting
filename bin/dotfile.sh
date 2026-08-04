#!/bin/bash

# sync ALL setting files between this repo (git) and local (~).
# add a syncSettingFile line here when you start to manage a new setting file.

source ./bin/sync_setting.sh

# editor
syncSettingFile "emacs" ./src/emacs.d_init.el ~/.emacs.d/init.el
syncSettingFile "vim"   ./src/vimrc           ~/.vimrc

# shell
syncSettingFile "git-branches" ./src/git-branches.sh ~/.git-branches
syncSettingFile "bash_profile" ./src/bash_profile.sh ~/.bash_profile
syncSettingFile "bashrc"       ./src/bashrc.sh       ~/.bashrc

# hammerspoon (sync every file in the repo folder, keeping relative paths)
if [ -d "/Applications/Hammerspoon.app" ]; then
    HAMMERSPOON_SET_FOLDER=./src/hammerspoon
    for GIT_FILE in $(find "$HAMMERSPOON_SET_FOLDER" -type f); do
        REL_PATH=${GIT_FILE#"$HAMMERSPOON_SET_FOLDER"/}
        syncSettingFile "hammerspoon: $REL_PATH" "$GIT_FILE" ~/.hammerspoon/"$REL_PATH"
    done
else
    message="<error> you cannot use application: Hammerspoon.app, skip hammerspoon settings"
    echo -e $'\e[31m' "${message}" $'\e[0m'
fi
