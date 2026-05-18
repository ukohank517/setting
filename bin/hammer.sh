#!/bin/bash

HAMMERSPOON_PATH=~/.hammerspoon
HAMMERSPOON_SET_FOLDER=./src/hammerSpoon

# Hammerspoon.app が存在するか直接判定
if [ -d "/Applications/Hammerspoon.app" ]; then
    echo "set hammerspoon setting file ... "

    # コピー先のディレクトリが存在しない場合は作成
    mkdir -p "$HAMMERSPOON_PATH"

    # HAMMERSPOON_SET_FOLDER の中身を丸ごとコピー
    # 末尾に「/.」をつけることで、フォルダ自体ではなく「中身すべて」を対象にします
    cp -R "$HAMMERSPOON_SET_FOLDER/." "$HAMMERSPOON_PATH/"

    echo "Successfully copied all settings to $HAMMERSPOON_PATH"

else
    message="<error> you cannot use application: Hammerspoon.app, please install it first"
    echo -e $'\e[31m' "${message}" $'\e[0m'
    exit 1
fi