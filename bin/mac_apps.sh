#!/bin/bash

# app / font / CLI checks and auto-install via brew.
# sourced by bin/mac_check.sh (needs bin/mac_lib.sh).

DL_LINKS=()          # apps that cannot be installed automatically
BREW_CASKS=()        # apps that can be installed via brew cask
CASK_FALLBACKS=()    # manual DL page for each cask (same index as BREW_CASKS)
BREW_FORMULAE=()     # CLI tools that can be installed via brew
FORMULA_FALLBACKS=() # manual page for each formula (same index as BREW_FORMULAE)

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
    checkCaskApp "AltTab.app"              "alt-tab"             "https://alt-tab.app/"

    # runcat (Mac App Store only, cannot install via brew)
    if ! existInApplication RunCat.app; then
        DL_LINKS+=("https://apps.apple.com/jp/app/runcat/id1429033973")
    fi

    printTitle "Font Check"

    # terminal font used by ghostty config (src/home/.config/ghostty/config)
    checkBrewCask "font-hackgen-nerd" "https://github.com/yuru7/HackGen/releases"

    printTitle "Command Check"

    checkBrewCmd "herdr" "herdr" "https://herdr.dev/"
    checkBrewCmd "emacs" "emacs" "https://formulae.brew.sh/formula/emacs"
    checkBrewCmd "mysql" "mysql" "https://formulae.brew.sh/formula/mysql"
    checkBrewCmd "wget"  "wget"  "https://formulae.brew.sh/formula/wget"
    checkBrewCmd "trash" "trash" "https://formulae.brew.sh/formula/trash" # rm alias (newer macOS ships /usr/bin/trash)
}

# $1: app name, $2: app path — ログイン時に自動起動するアプリを登録する
function checkLoginItem() {
    if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q "$1"; then
        printInfo "login item exists: $1"
    else
        printInfo "add login item: $1"
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$2\", hidden:false}" >/dev/null
    fi
}

function checkLoginItems() {
    printTitle "Login Item Check"

    checkLoginItem "Hammerspoon" "/Applications/Hammerspoon.app"
    checkLoginItem "Clipy"       "/Applications/Clipy.app"
    checkLoginItem "RunCat"      "/Applications/RunCat.app"
    checkLoginItem "AltTab"      "/Applications/AltTab.app"

    # herdr server: ログイン時に常駐させる (brew services)
    if brew services list 2>/dev/null | grep -E '^herdr' | grep -qE 'started'; then
        printInfo "herdr service: already managed by brew services"
    elif herdr status 2>/dev/null | grep -q 'status: running'; then
        # 手動起動のサーバーが動いている間に brew services を始めるとソケットが競合する
        printInfo "herdr server is running manually. to manage it at login:"
        printInfo "  stop it first, then run: brew services start herdr"
    else
        printInfo "starting herdr service (auto start at login)"
        brew services start herdr
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
