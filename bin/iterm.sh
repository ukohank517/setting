#!/bin/bash

# iTerm2 の設定を repo から適用する
# 事前に iTerm2 を終了しておくこと（起動中は終了時に設定が上書きされるため）

ITERM_DOMAIN=com.googlecode.iterm2
ITERM_SET_FILE=./src/iterm2/com.googlecode.iterm2.plist

# iTerm.app が存在するか判定
if [ ! -d "/Applications/iTerm.app" ]; then
    message="[error] you cannot use application: iTerm.app, please install it first"
    echo -e $'\e[31m' "${message}" $'\e[0m'
    exit 1
fi

# iTerm2 が起動中なら警告して終了
if pgrep -x "iTerm2" > /dev/null; then
    message="[error] iTerm2 is running. quit it first, then run again."
    echo -e $'\e[31m' "${message}" $'\e[0m'
    exit 1
fi

echo "import iterm2 setting file ... "

# repo の plist を defaults に取り込む
defaults import "$ITERM_DOMAIN" "$ITERM_SET_FILE"

# 設定キャッシュを再読み込みさせる
killall cfprefsd 2>/dev/null

echo "Successfully imported iterm2 setting from $ITERM_SET_FILE"
