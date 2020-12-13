#!/bin/bash

EMACS_PATH=~/.emacs.d/init.el
EMACS_SET_FILE=./src/emacs.d_init.el

VIM_PATH=~/.vimrc
VIM_SET_FILE=./src/vimrc


# set emacs setting file
if hash emacs 2>/dev/null; then
    if [ -e $EMACS_PATH ]; then
        message="<error> emacs setting file exist, skipped, filepath:[$EMACS_PATH]"
        echo $'\e[31m' ${message} $'\e[0m'
    else
        echo "set emacs setting file ... "
        cp $EMACS_SET_FILE $EMACS_PATH
    fi
else
    message="<error> command 'emacs' not exist, you can use brew to install it \n         or install like here(centos): 'urlhttps://github.com/ukohank517/setting/blob/master/tmp/install_emacs.sh'"
    echo -e $'\e[31m' "${message}" $'\e[0m'
fi

# set vim setting file
if [ -e $VIM_PATH ]; then
    message="<error> vim setting file exist, skipped, filepath:[$VIM_PATH]"
    echo $'\e[31m' ${message} $'\e[0m'
else
    echo "set vim setting file ... "
    cp $VIM_SET_FILE $VIM_PATH
fi
