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

# terminal
syncSettingFile "ghostty" ./src/ghostty_config     ~/.config/ghostty/config
syncSettingFile "herdr"   ./src/herdr_config.toml  ~/.config/herdr/config.toml

# claude code (statusline also feeds herdr's sidebar, see herdr_config.toml)
syncSettingFile "claude-statusline" ./src/claude_statusline.sh ~/.claude/statusline.sh

# keyboard: caps lock -> ctrl (ログイン時に hidutil で適用される LaunchAgent)
syncSettingFile "capslock-to-ctrl" ./src/launchagents/com.ukohank517.capslock-to-ctrl.plist ~/Library/LaunchAgents/com.ukohank517.capslock-to-ctrl.plist

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
