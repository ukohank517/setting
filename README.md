# setting

Mac のセットアップと dotfiles を管理するリポジトリ。詳細な手順とアプリのメモは [mac.md](mac.md) を参照。

## 使い方

```bash
make            # ターゲット一覧を表示
make mac        # アプリ/フォント/CLI のチェックと自動インストール、macOS defaults、ログインシェルを bash に
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
  mac_shell.sh      #   └ ログインシェルを bash へ (+ 旧シェルの履歴移行)
  dotfile.sh        # make dotfile: src/home/ 以下を ~ と同期 + claude 管理キーのマージ
  sync_setting.sh   #   └ 同期の共通関数 (diff表示・対話マージ・<shell>rc.local への退避)
src/home/           # ~ をミラーした管理対象の設定ファイル群
src/claude/         # ~/.claude/settings.json と ~/.claude.json に冪等マージする管理キー (fragment)
```

## ルール

- **設定ファイルの追加**: `src/home/` に「`~` 内での配置と同じパス」で置くだけ。
  `make dotfile` が自動で拾う (例: `src/home/.config/ghostty/config` → `~/.config/ghostty/config`)。
- **秘密情報 (トークン等) と機体固有の設定**: git には入れず `~/.bashrc.local` に書く
  (bashrc が存在すれば source する)。`make dotfile` でシェル設定に差分が出たとき、
  「diff -> ~/.bashrc.local」を選ぶと local 側の差分行が git に入らず退避される。
  zsh 設定の場合は `~/.zshrc.local` が退避先になる。
- ログインシェルは bash。`src/home/.zshrc` は zsh を使うとき用に残しているが未使用
  (Ctrl-P/N の履歴メニューと Tab 補完のカーソル固定設定入り)。
- **claude code の `~/.claude/settings.json`**: claude code 自身が書き換える
  (モデル・権限など) ため丸ごとは同期しない。`make dotfile` が
  `src/claude/settings-fragment.json` のキー (statusLine・時刻表示hooks など)
  だけを冪等にディープマージする (他のキーは保持、変更時は `.bak` を残す)。
  時刻表示hooksは送信/完了時刻 (⏰/✅) を画面にだけ出す。モデルには送られない。
  fragment には env (NO_FLICKER)・tui・theme も含む。permissions や model は機体/気分で
  変えるものなので入れない。
  theme は `custom:dark-budou` (`src/home/.claude/themes/dark-budou.json`)。dark を土台に、
  自分の発言の背景色だけ葡萄色にして会話の中で見分けやすくしている (青系の選択色と被らない色)。
- **claude code の MCP サーバー (`~/.claude.json` の `mcpServers`)**: 同じ要領で
  `src/claude/mcp-fragment.json` をディープマージする (user スコープ相当。`claude mcp list` に出る)。
  マージは追加/上書きのみなので、fragment から消したサーバーは `claude mcp remove <name>` で手動削除。
  OAuth トークンは Keychain にあり git では運べないため、新しい PC では claude 起動後に
  `/mcp` → Authenticate を一度通す。`make dotfile` は claude を動かしていないときに実行する
  (claude 自身が両ファイルを書き換えるため)。
- **claude code の「← で agents 一覧を開く」は無効**: 同じ `mcp-fragment.json` に
  `leftArrowOpensAgents: false` を入れている (`~/.claude.json` のキー。`/config` の「← opens agents」と同じ)。
  空の入力欄で ← を押すと会話がバックグラウンドに回り、誤操作で会話を見失うため。
  agents 一覧そのものは `claude agents` で開ける。
