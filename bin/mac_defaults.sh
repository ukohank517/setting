#!/bin/bash

# macOS defaults (システム設定値) のチェックと適用。
# 望みの値と違うときだけ defaults write する。設定を増やすときはここに1行足す。
#   make defaults : このファイル単体で実行
#   make mac      : mac_check.sh から source されて実行

# 表示関数: mac_check.sh から source された場合はそちらの定義を使う
if ! type printInfo >/dev/null 2>&1; then
    function printInfo(){
        echo "  [info]" $1
    }
fi
if ! type printTitle >/dev/null 2>&1; then
    function printTitle(){
        echo "##################################################" # len: 50
        TITLE_LEN=${#1}
        LEFT_LEN=$(( (50-TITLE_LEN)/2 ))
        RIGHT_LEN=$(( 50-TITLE_LEN-LEFT_LEN ))
        printf "%-${LEFT_LEN-1}s" '#'
        printf "${1}"
        printf "%${RIGHT_LEN-1}s" '#'
        printf "\n"
        echo "##################################################"
    }
fi

# $1: domain (-g for global), $2: key, $3: type option, $4: value to write,
# $5: expected value from `defaults read`
function setMacDefault() {
    CURRENT=$(defaults read "$1" "$2" 2>/dev/null)
    if [ "$CURRENT" = "$5" ]; then
        printInfo "already set: $2 = $CURRENT"
    else
        printInfo "set: $2 -> $4 (was: ${CURRENT:-<not set>})"
        defaults write "$1" "$2" "$3" "$4"
        DEFAULTS_CHANGED=1
    fi
}

# same as setMacDefault but for per-host (-currentHost) preferences
function setMacDefaultHost() {
    CURRENT=$(defaults -currentHost read "$1" "$2" 2>/dev/null)
    if [ "$CURRENT" = "$5" ]; then
        printInfo "already set: $2 = $CURRENT"
    else
        printInfo "set: $2 -> $4 (was: ${CURRENT:-<not set>})"
        defaults -currentHost write "$1" "$2" "$3" "$4"
        DEFAULTS_CHANGED=1
    fi
}

function setupMacDefaults() {
    printTitle "macOS Defaults Check"
    DEFAULTS_CHANGED=0

    ### キーリピート
    setMacDefault -g ApplePressAndHoldEnabled -bool false 0   # キー長押しでアクセント文字メニューを出さず、リピート入力する
    setMacDefault -g InitialKeyRepeat        -int  15    15   # リピート開始までの待ち時間 (15 = 225ms, GUIの最小値)
    setMacDefault -g KeyRepeat               -int  1     1    # リピート間隔 (1 = 15ms, GUIの最小値2より速い)

    ### トラックパッド: タップでクリック
    setMacDefault com.apple.AppleMultitouchTrackpad Clicking -bool true 1                  # 内蔵トラックパッド
    setMacDefault com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true 1 # 外付け(Bluetooth)トラックパッド
    setMacDefaultHost -g com.apple.mouse.tapBehavior -int 1 1                              # ログイン画面などにも効くホスト単位の設定

    ### トラックパッド: 3本指ドラッグ
    setMacDefault com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true 1                  # 内蔵トラックパッド
    setMacDefault com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true 1 # 外付け(Bluetooth)トラックパッド

    ### 入力: コードやコマンドを勝手に「修正」させない
    setMacDefault -g NSAutomaticSpellingCorrectionEnabled -bool false 0  # スペル自動修正をオフ
    setMacDefault -g NSAutomaticCapitalizationEnabled     -bool false 0  # 文頭の自動大文字化をオフ
    setMacDefault -g NSAutomaticPeriodSubstitutionEnabled -bool false 0  # スペース2回で「.」を入れる機能をオフ
    setMacDefault -g NSAutomaticQuoteSubstitutionEnabled  -bool false 0  # " を “ ” に変換しない (コード貼り付け事故防止)
    setMacDefault -g NSAutomaticDashSubstitutionEnabled   -bool false 0  # -- を — に変換しない

    ### Finder
    setMacDefault -g AppleShowAllExtensions -bool true 1                              # 全ファイルの拡張子を常に表示
    setMacDefault com.apple.finder AppleShowAllFiles -bool true 1                     # 隠しファイル(dotfile)を表示 (cmd+shift+. でトグル可)
    setMacDefault com.apple.finder ShowPathbar       -bool true 1                     # ウィンドウ下部にパスバーを表示
    setMacDefault com.apple.desktopservices DSDontWriteNetworkStores -bool true 1     # ネットワークドライブに .DS_Store を作らない

    ### スクリーンショット
    mkdir -p "$HOME/Desktop/screenshot"
    setMacDefault com.apple.screencapture location -string "~/Desktop/screenshot" "~/Desktop/screenshot" # 保存先 (デスクトップ散らかり防止)
    setMacDefault com.apple.screencapture disable-shadow -bool true 1                                    # ウィンドウ撮影時の影を付けない

    ### Dock
    setMacDefault com.apple.dock autohide -bool true 1                   # 自動的に隠す
    setMacDefault com.apple.dock autohide-delay         -float 0   0     # マウスを寄せたら即表示 (デフォルトは0.5秒待つ)
    setMacDefault com.apple.dock autohide-time-modifier -float 0.5 0.5   # 出入りのアニメーションを2倍速に

    ### Ghostty
    setMacDefault com.mitchellh.ghostty SecureInput -bool true 1  # Secure Keyboard Entry 常時オン (他アプリのキー入力盗み見を防ぐ)

    if [ "$DEFAULTS_CHANGED" -eq 1 ]; then
        printInfo "restarting Dock/Finder/SystemUIServer to apply..."
        killall Dock Finder SystemUIServer 2>/dev/null
        printInfo "note: keyboard/trackpad changes need re-login to apply."
    fi
}

# 直接実行されたときはそのまま適用する (make defaults)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    setupMacDefaults
fi
