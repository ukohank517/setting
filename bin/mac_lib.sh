#!/bin/bash

# shared print helpers for bin/mac_*.sh

function printError(){
    # $'\e[31m' : red color font
    # $'\e[0m'  : reset font
    echo $'\e[31m [error]'$1$'\e[0m'
}

function printInfo(){
    echo "  [info]" $1
}

# next-action banner: green + bold so it stands out at the end of a long run
function printNext(){
    echo $'\e[1;32m'
    echo " ╔══════════════════════════════════════════════╗"
    printf " ║ ➜ NEXT: %-37s║\n" "$1"
    echo " ╚══════════════════════════════════════════════╝"
    echo $'\e[0m'
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
