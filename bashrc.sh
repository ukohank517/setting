########################################################
#################### global setting ####################
########################################################

# bash prompt sytle
# PS1="\u:\t \W $" # username:time direcotry-name
GIT_PS1_SHOWDIRTYSTATE=true
export PS1='\n\[\033[32m\]\u@\h\[\033[00m\]:\[\033[33m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\n\$ '

# bash system language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ls color
export LSCOLORS=Dxfxcxdxbxegexabagacad
alias ls="ls -G"

# upper ls-history limit
HISTSIZE=100000

# command history operation
bind '"\C-n": history-search-forward'
bind '"\C-p": history-search-backward'
bind '"\e[A": history-search-backward' # up-arrow-key
bind '"\e[B": history-search-forward' # down-arrow-key

######################################################
#################### brew setting ####################
######################################################

# trash, `rm` command to mv file into trash box
alias rm="trash"

# bash-completion, auto fill in the blank
source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh # bash profile prompt
source /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash # auto completion for git

######################################################
#################### user setting ####################
######################################################

alias memo="echo '[TODO]: set memo file path'" #b coder
#flumake for emacs : https://qiita.com/awakia/items/5c97b02dcc3c7fd20279