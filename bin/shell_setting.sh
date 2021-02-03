if ! hash brew 2>/dev/null; then
    echo "Please install brew first."
    exit 1
fi

# I'm tired....
`brew upgrade`
`brew install emacs mysql trash wget bash-completion`


BASHRC_PATH=~/.bashrc
BASHPROFILE_PATH=~/.bash_profile
BASHRC_SET_FILE=./src/bashrc.sh
BASHPROFILE_SET_FILE=./src/bash_profile.sh

# set vim setting file
if [ -e $BASHRC_PATH ] || [ -e $BASHPROFILE_PATH ]; then
    message="[error] shell setting file already exist, skipped, check filepath:[$BASHRC_PATH][$BASHPROFILE_PATH]"
    echo $'\e[31m' ${message} $'\e[0m'
else
    echo "start..."
    cp $BASHPROFILE_SET_FILE $BASHPROFILE_PATH
    echo "bash_profile down"
    cp $BASHRC_SET_FILE $BASHRC_PATH
    echo "bashrc down"
    echo "end"
fi