# macの初期設定

普段使ってるアプリと、その中の設定を書き出しています。

## [chrome](https://www.google.co.jp/chrome/)

ブラウザー

設定→規定のブラウザよりデフォルト設定変更　

## [Visual Studio Code](https://code.visualstudio.com/)

カスタマイズするエディター、setting syncオンする

## shell

### [homebrew](https://brew.sh/)

パッケージ管理ツール、入れ終わると、下記のパッケージを入れる。

```bash
brew install emacs
brew install trash
brew install bash-completion
# download git-prompt.sh
# wget -P /usr/local/etc/bash_completion.d/ https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
# download git-completion.sh
# wget -P /usr/local/etc/bash_completion.d/ https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
# ln -s /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash /usr/local/etc/bash_completion.d/git-completion.bash
```

### bash_profile

[bash_profile](https://github.com/ukohank517/setting/blob/master/bash_profile.sh)

### bashrc

[bashrc](https://github.com/ukohank517/setting/blob/master/bashrc.sh)

## [docker for mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac)

[Get Docker](https://hub.docker.com/editions/community/docker-ce-desktop-mac)より、ダウンロードしてインストールする。

## [postman](https://www.postman.com/download)

一応ウェブプログラマーなので、API叩けるツールが必要

## [hammerspoon](https://www.hammerspoon.org/)

- https://github.com/fikovnik/ShiftIt/releases
- https://github.com/peterklijn/hammerspoon-shiftit/tree/master/Spoons
- https://github.com/ukohank517/setting/blob/master/bin/init.lua


## [iTerm2](https://iterm2.com/)

ターミナル。設定は `src/iterm2/com.googlecode.iterm2.plist` に書き出して管理している。

適用（iTerm2 を終了してから実行）:

```bash
make iterm
```

主なカスタマイズ:

- 新規タブ/分割を前セッションと同じフォルダで開く（Profiles → General → Working Directory → Reuse previous session's directory）
- 分割ペインごとにタイトルバー表示（Appearance → Panes → Show per-pane title bar）
- タイトルに現在フォルダ・実行コマンドを表示（Profiles → General → Title → Current Directory / Job Name）
- 上記は [Shell Integration](https://iterm2.com/documentation-shell-integration.html) が前提

GUI で設定を変えたら、下記で repo 側に反映する:

```bash
defaults export com.googlecode.iterm2 ./src/iterm2/com.googlecode.iterm2.plist
```

## [clipy](https://clipy-app.com/)

拡張クリップボード、複数コピー情報を所有できる。

## [gasmask](https://github.com/2ndalpha/gasmask/releases)

hostファイル編集ツール
