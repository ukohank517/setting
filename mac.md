# macの初期設定

普段使ってるアプリと設定のメモ。セットアップは基本 `make` で完結する。

## セットアップ手順

```bash
make mac      # brew・アプリ・フォント・herdr を自動インストール、macOS defaults 設定
make shell    # brew でシェル関連パッケージ (emacs, mysql, trash, wget, bash-completion)
make dotfile  # 設定ファイルを git <-> local で対話同期
```

## make mac が入れるもの

自動インストール (brew cask / formula)。無いものだけ入る。

| 種類 | 対象 |
|---|---|
| アプリ | Chrome, VS Code, Docker, Postman, Hammerspoon, Clipy, Ghostty, AltTab |
| フォント | HackGen Console NF (ghostty で使用) |
| CLI | herdr |
| defaults | キーリピート高速化 (ApplePressAndHoldEnabled / InitialKeyRepeat / KeyRepeat) |

- [RunCat](https://apps.apple.com/jp/app/runcat/id1429033973) だけは Mac App Store 専売なので、DLページが開く (手動インストール)
- brew 自体も無ければ自動で入る

## make dotfile が同期するもの

`bin/dotfile.sh` に一覧がある。新しい設定ファイルを管理したくなったら1行足す。

| 名前 | local |
|---|---|
| emacs | `~/.emacs.d/init.el` |
| vim | `~/.vimrc` |
| git-branches | `~/.git-branches` |
| bash_profile | `~/.bash_profile` |
| bashrc | `~/.bashrc` |
| ghostty | `~/.config/ghostty/config` |
| herdr | `~/.config/herdr/config.toml` |
| hammerspoon | `~/.hammerspoon/` 以下 |

差分があると diff を表示して local -> git / git -> local / vimdiff手動マージ / skip を選べる。
git -> local は上書き前に `.bak` を残す。local -> git はコピーだけなのでコミットは手動。

## ターミナル構成

- **Ghostty** … 入れ物 (描画・フォント・テーマ)。TokyoNight + HackGen Console NF。
  分割やタブ管理はしない。`cmd+d` は herdr の分割キーに転送している。
- **herdr** … ターミナル多重化 + AIエージェント管理。プレフィックスは `ctrl+b`。
  分割・タブ・ワークスペース・セッション永続化はすべてこちら。
  ペイン境界に pwd が出る (bashrc の `__herdr_pane_title` フック)。

## アプリ個別メモ

### [chrome](https://www.google.co.jp/chrome/)

設定→規定のブラウザよりデフォルト設定変更

### [Visual Studio Code](https://code.visualstudio.com/)

setting sync オンする

### [hammerspoon](https://www.hammerspoon.org/)

ウィンドウ操作。設定は `src/hammerspoon/` (ShiftIt spoon + カスタムホットキー)

### [clipy](https://clipy-app.com/)

拡張クリップボード、複数コピー情報を所有できる

### [RunCat](https://apps.apple.com/jp/app/runcat/id1429033973)

メニューバーで猫が走る。App Store から入れる
