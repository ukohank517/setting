#!/bin/bash

# install shell related packages via brew.
# setting files (bashrc etc.) are synced by 'make dotfile'.

if ! hash brew 2>/dev/null; then
    echo "Please install brew first."
    exit 1
fi

brew upgrade
brew install emacs mysql trash wget bash-completion
