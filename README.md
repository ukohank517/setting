# setting

Mac のセットアップと dotfiles を管理するリポジトリ。詳細な手順とアプリのメモは [mac.md](mac.md) を参照。

## 使い方

```bash
make            # ターゲット一覧を表示
make mac        # アプリ/フォント/CLI のチェックと自動インストール、macOS defaults、ログインシェルを zsh に
make defaults   # macOS defaults のみ適用
make dotfile    # 設定ファイルを git <-> local で対話同期
```

## 構成

```
Makefile            # 入口 (上の3ターゲット)
mac.md              # セットアップ手順・アプリ個別メモ
bin/
  mac_check.sh      # make mac のオーケストレーター
  mac_lib.sh        #   └ 表示ヘルパー
  mac_apps.sh       #   └ アプリ/フォント/CLI チェック + brew 自動インストール + ログイン項目
  mac_defaults.sh   #   └ macOS defaults (make defaults で単体実行も可)
  mac_shell.sh      #   └ ログインシェルを zsh へ (+ 旧シェルの履歴移行)
  dotfile.sh        # make dotfile: src/home/ 以下を ~ と同期
  sync_setting.sh   #   └ 同期の共通関数 (diff表示・対話マージ・~/.zshrc.local への退避)
src/home/           # ~ をミラーした管理対象の設定ファイル群
```

## ルール

- **設定ファイルの追加**: `src/home/` に「`~` 内での配置と同じパス」で置くだけ。
  `make dotfile` が自動で拾う (例: `src/home/.config/ghostty/config` → `~/.config/ghostty/config`)。
- **秘密情報 (トークン等) と機体固有の設定**: git には入れず `~/.zshrc.local` に書く
  (zshrc が存在すれば source する)。`make dotfile` でシェル設定に差分が出たとき、
  「diff -> ~/.zshrc.local」を選ぶと local 側の差分行が git に入らず退避される。
- ログインシェルは zsh。bash の設定 (`.bashrc` / `.bash_profile`) は未使用だが管理は継続。
