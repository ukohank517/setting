#!/bin/bash

DL_LINKS=()          # apps that cannot be installed automatically
BREW_CASKS=()        # apps that can be installed via brew cask
CASK_FALLBACKS=()    # manual DL page for each cask (same index as BREW_CASKS)
BREW_FORMULAE=()     # CLI tools that can be installed via brew
FORMULA_FALLBACKS=() # manual page for each formula (same index as BREW_FORMULAE)

function printError(){
    # $'\e[31m' : red color font
    # $'\e[0m'  : reset font
    echo $'\e[31m [error]'$1$'\e[0m'
}

function printInfo(){
    echo "  [info]" $1
}

function printTitle(){
    echo "##################################################" # len: 50
    TITLE_LEN=${#1}
    LEFT_LEN=$(( (50-TITLE_LEN)/2 ))
    RIGHT_LEN=$(( 50-TITLE_LEN-LEFT_LEN ))
    printf "%-${LEFT_LEN-1}s" '#' # left shap
    printf "${1}"                 # title
    printf "%${RIGHT_LEN-1}s" '#' # right shap
    printf "\n"                   # new line
    echo "##################################################"
}

function existInApplication() {
    if [ -d "/Applications/$1" ]; then
        printInfo "you can use application: $1"
        return 0 # true
    else
        printError "you cannot use application: $1"
        return 1 # false
    fi
}

function setupBrew() {
    printTitle "Homebrew Check"

    if ! hash brew 2>/dev/null; then
        # brew may be installed but not in PATH yet
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    if hash brew 2>/dev/null; then
        printInfo "you can use command: brew"
        return 0
    fi

    printInfo "brew not found. installing Homebrew automatically..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # add brew to PATH for this session (Apple Silicon / Intel)
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if hash brew 2>/dev/null; then
        printInfo "Homebrew installed successfully."
        return 0
    else
        printError "failed to install Homebrew. install it manually: https://brew.sh/"
        return 1
    fi
}

# $1: application name (in /Applications), $2: brew cask name, $3: manual DL page
function checkCaskApp() {
    if ! existInApplication "$1"; then
        BREW_CASKS+=("$2")
        CASK_FALLBACKS+=("$3")
    fi
}

# $1: brew cask name (font etc, not an app in /Applications), $2: manual page
function checkBrewCask() {
    if brew list --cask "$1" >/dev/null 2>&1; then
        printInfo "you can use cask: $1"
    else
        printError "you cannot use cask: $1"
        BREW_CASKS+=("$1")
        CASK_FALLBACKS+=("$2")
    fi
}

# $1: command name, $2: brew formula name, $3: manual page
function checkBrewCmd() {
    if hash "$1" 2>/dev/null; then
        printInfo "you can use command: $1"
    else
        printError "you cannot use command: $1"
        BREW_FORMULAE+=("$2")
        FORMULA_FALLBACKS+=("$3")
    fi
}

function checkAapp() {
    printTitle "Application Check"

    checkCaskApp "Google Chrome.app"       "google-chrome"       "https://www.google.com/chrome/"
    checkCaskApp "Visual Studio Code.app"  "visual-studio-code"  "https://code.visualstudio.com"
    checkCaskApp "Docker.app"              "docker"              "https://hub.docker.com/editions/community/docker-ce-desktop-mac"
    checkCaskApp "Postman.app"             "postman"             "https://www.postman.com/downloads"
    checkCaskApp "Hammerspoon.app"         "hammerspoon"         "https://www.hammerspoon.org/"
    checkCaskApp "Clipy.app"               "clipy"               "https://clipy-app.com/"
    checkCaskApp "Ghostty.app"             "ghostty"             "https://ghostty.org/"

    # runcat (Mac App Store only, cannot install via brew)
    if ! existInApplication RunCat.app; then
        DL_LINKS+=("https://apps.apple.com/jp/app/runcat/id1429033973")
    fi

    printTitle "Font Check"

    # terminal font used by ghostty config (src/ghostty_config)
    checkBrewCask "font-hackgen-nerd" "https://github.com/yuru7/HackGen/releases"

    printTitle "Command Check"

    checkBrewCmd "herdr" "herdr" "https://herdr.dev/"
}

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

function installBrewPackages() {
    if [ $(( ${#BREW_CASKS[@]} + ${#BREW_FORMULAE[@]} )) -eq 0 ]; then
        return 0
    fi

    printTitle "Auto Install (brew)"

    if ! hash brew 2>/dev/null; then
        printError "brew is not available, cannot auto-install. open DL pages instead."
        # fall back to manual download links
        DL_LINKS+=("${CASK_FALLBACKS[@]}" "${FORMULA_FALLBACKS[@]}")
        return 1
    fi

    for i in "${!BREW_CASKS[@]}"; do
        cask=${BREW_CASKS[$i]}
        printInfo "installing: $cask"
        if brew install --cask "$cask"; then
            printInfo "installed: $cask"
        else
            printError "failed to install: $cask"
            DL_LINKS+=("${CASK_FALLBACKS[$i]}")
        fi
    done

    for i in "${!BREW_FORMULAE[@]}"; do
        formula=${BREW_FORMULAE[$i]}
        printInfo "installing: $formula"
        if brew install "$formula"; then
            printInfo "installed: $formula"
        else
            printError "failed to install: $formula"
            DL_LINKS+=("${FORMULA_FALLBACKS[$i]}")
        fi
    done
}

function openDlLink() {
    printTitle "Result"
    if [ ${#DL_LINKS[@]} -eq 0 ]; then
        # https://lazesoftware.com/tool/hugeaagen/
        echo "■■■■■■■■■■■■■■■■■■■■■■■■■   ■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■  ■■■■■■■■■■■■■■■■■ ■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■  ■■■■■■■■■■■■■■■■  ■■■■■■"
        echo "■■■■ ■   ■■■■    ■■ ■      ■■    ■■■    ■     ■■■■"
        echo "■■■■  ■■  ■■  ■■ ■■   ■■  ■■  ■■ ■■  ■■ ■■  ■■■■■■"
        echo "■■■■  ■■■ ■■ ■■■■ ■  ■■■  ■■ ■■■■ ■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■  ■      ■ ■■■■  ■■      ■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■  ■ ■■■■■■ ■■■■  ■■ ■■■■■■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■ ■■ ■■■■■■ ■■■■  ■■ ■■■■■■ ■■■■■■  ■■■■■■"
        echo "■■■■  ■■  ■■  ■■■■■ ■■■■  ■■  ■■■■■  ■■ ■■■ ■■■■■■"
        echo "■■■■     ■■■■    ■■ ■■■■  ■■■    ■■■    ■■■   ■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
    else
        printInfo "These cannot be auto-installed. Open DL pages."
        for link in "${DL_LINKS[@]}"; do
            open "$link"
        done
    fi
}

##########################################################
#                        ~ main ~                        #
##########################################################
printTitle "start"
printInfo "check apps that usually needs, for mac."
printInfo "auto-install via brew when possible."

setupBrew
checkAapp
installBrewPackages
setupMacDefaults
openDlLink
