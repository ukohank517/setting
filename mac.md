# macの初期設定

普段使ってるアプリと設定のメモ。セットアップは基本 `make` で完結する。

## セットアップ手順

```bash
make mac      # brew・アプリ・フォント・CLI を自動インストール、macOS defaults 設定、ログインシェルを zsh に
make dotfile  # 設定ファイルを git <-> local で対話同期
```

## make mac が入れるもの

自動インストール (brew cask / formula)。無いものだけ入る。

| 種類 | 対象 |
|---|---|
| アプリ | Chrome, VS Code, Docker, Postman, Hammerspoon, Clipy, Ghostty, AltTab |
| フォント | HackGen Console NF (ghostty で使用) |
| CLI | herdr, emacs, mysql, wget, trash |
| defaults | キーリピート高速化 (ApplePressAndHoldEnabled / InitialKeyRepeat / KeyRepeat) |
| シェル | ログインシェルが zsh でなければ `chsh -s /bin/zsh` (+ 旧シェルの履歴を `~/.zsh_history` に移行) |

- [RunCat](https://apps.apple.com/jp/app/runcat/id1429033973) だけは Mac App Store 専売なので、DLページが開く (手動インストール)
- brew 自体も無ければ自動で入る

## make dotfile が同期するもの

`src/home/` 以下の全ファイル。`~` 内での配置をそのままミラーしているので、
新しい設定ファイルを管理したくなったら同じパスで `src/home/` に置くだけで自動で拾われる
(例: `src/home/.config/ghostty/config` → `~/.config/ghostty/config`)。

主なもの: zshrc / bashrc / vimrc / emacs / git-branches / ghostty / herdr /
claude statusline / hammerspoon / LaunchAgents (caps lock -> ctrl)。

差分があると diff を表示して local -> git / git -> local / vimdiff手動マージ / skip を選べる。
git -> local は上書き前に `.bak` を残す。local -> git はコピーだけなのでコミットは手動。

- ログインシェルは zsh (`~/.zshrc` が本体)。bash の設定は未使用だが管理は継続。
- トークンなどの秘密情報・機体固有の設定は git に入れず `~/.zshrc.local` に書く
  (zshrc が source する)。シェル設定に差分が出たとき「diff -> ~/.zshrc.local」を
  選ぶと、local 側の差分行が git に入らずそちらへ退避される。

## ターミナル構成

- **Ghostty** … 入れ物 (描画・フォント・テーマ)。TokyoNight + HackGen Console NF。
  分割やタブ管理はしない。`cmd+d` は herdr の分割キーに転送している。
- **herdr** … ターミナル多重化 + AIエージェント管理。プレフィックスは `ctrl+b`。
  分割・タブ・ワークスペース・セッション永続化はすべてこちら。
  ペイン境界に pwd が出る (zshrc の `__herdr_pane_title` フック)。

## アプリ個別メモ

### [chrome](https://www.google.co.jp/chrome/)

設定→規定のブラウザよりデフォルト設定変更

### [Visual Studio Code](https://code.visualstudio.com/)

setting sync オンする

### [hammerspoon](https://www.hammerspoon.org/)

ウィンドウ操作。設定は `src/home/.hammerspoon/` (ShiftIt spoon + カスタムホットキー)

### [clipy](https://clipy-app.com/)

拡張クリップボード、複数コピー情報を所有できる

### [RunCat](https://apps.apple.com/jp/app/runcat/id1429033973)

メニューバーで猫が走る。App Store から入れる
