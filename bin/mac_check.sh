#!/bin/bash

DL_LINKS=()

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

function checkAapp() {
    printTitle "Application Check"

    # xcode
    if ! existInApplication Xcode.app ; then
        DL_LINKS+=("https://apps.apple.com/jp/app/xcode/id497799835")
    fi

    # tab memo light
    if ! existInApplication Tab\ Notes\ Free.app ; then
        DL_LINKS+=("https://apps.apple.com/jp/app/tab-notes-lite/id410479438")
    fi

    # vscode
    if ! existInApplication Visual\ Studio\ Code.app; then
        DL_LINKS+=("https://code.visualstudio.com")
    fi

    # docker
    if ! existInApplication Docker.app; then
        DL_LINKS+=("https://hub.docker.com/editions/community/docker-ce-desktop-mac")
    fi

    # postman
    if ! existInApplication Postman.app; then
        DL_LINKS+=("https://www.postman.com/downloads")
    fi

    # ShiftIt
    if ! existInApplication ShiftIt.app; then
        DL_LINKS+=("https://github.com/fikovnik/ShiftIt/releases")
    fi

    # Clipy
    if ! existInApplication Clipy.app; then
        DL_LINKS+=("https://clipy-app.com/")
    fi

    # gasmask
    if ! existInApplication Gas\ Mask.app; then
        DL_LINKS+=("https://github.com/2ndalpha/gasmask/releases")
    fi

    printTitle "Command Check"

    # brew
    if hash brew 2>/dev/null; then
        printInfo "you can use command: brew"
    else
        DL_LINKS+=("https://brew.sh/")
    fi
}

function openDlLink() {
    printTitle "Result"
    if [ ${#DL_LINKS[@]} -eq 0 ]; then
        # https://lazesoftware.com/tool/hugeaagen/
        echo "■■■■■■■■■■■■■■■■■■■■■■■■■   ■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■  ■■■■■■■■■■■■■■■■■ ■■■■■■"
        echo "■■■■■■■■■■■■■■■■■■■■■■■■  ■■■■■■■■■■■■■■■■  ■■■■■■"
        echo "■■■■ ■   ■■■■    ■■ ■      ■■    ■■■    ■     ■■■■"
        echo "■■■■  ■■  ■■  ■■ ■■   ■■  ■■  ■■ ■■  ■■ ■■  ■■■■■■"
        echo "■■■■  ■■■ ■■ ■■■■ ■  ■■■  ■■ ■■■■ ■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■  ■      ■ ■■■■  ■■      ■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■  ■ ■■■■■■ ■■■■  ■■ ■■■■■■ ■■■■■■  ■■■■■■"
        echo "■■■■ ■■■■ ■■ ■■■■■■ ■■■■  ■■ ■■■■■■ ■■■■■■  ■■■■■■"
        echo "■■■■  ■■  ■■  ■■■■■ ■■■■  ■■  ■■■■■  ■■ ■■■ ■■■■■■"
        echo "■■■■     ■■■■    ■■ ■■■■  ■■■    ■■■    ■■■   ■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
        echo "■■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
    else
        printInfo "Open DL pages form Chrome."
        COMMAND='open -na "Google Chrome" --args --new-window';
        i=0
        for link in ${DL_LINKS[@]}; do
            COMMAND+=' '$link
            let i++
        done
        eval $COMMAND
    fi
}

##########################################################
#                        ~ main ~                        #
##########################################################
printTitle "start"
printInfo "check apps that usually needs, for mac."
printInfo "now inform DL URL base-on chrome..."

# check Chrome first
printTitle "check applications DL Broser"
if existInApplication Google\ Chrome.app ; then
    echo "You have already had chrome, we'll show you DL URL by Chrome"
else
    echo "Please install Chrome first."
fi

checkAapp
openDlLink
