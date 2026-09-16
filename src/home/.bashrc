########################################################
#################### global setting ####################
########################################################

# bash prompt sytle
# PS1="\u:\t \W $" # username:time direcotry-name
GIT_PS1_SHOWDIRTYSTATE=true
export PS1='\n\[\033[32m\]\u@\h\[\033[00m\]:\[\033[33m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\] \[\033[36m\]$(date +\%H:\%M:\%S)\[\033[00m\]\n\$ '

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

# ghostty shell integration: window title = cwd, new tab inherits cwd.
# GHOSTTY_RESOURCES_DIR is only set inside ghostty, so this is a no-op elsewhere.
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

# herdr: show current directory on this pane's border (like tmux pane-border-format)
# and refresh the workspace's pane-path list in the sidebar spaces rows
# (~/.config/herdr/report-pane-paths.sh, $path1.. tokens in herdr config.toml).
# HERDR_PANE_ID is only set inside herdr panes, so this is a no-op elsewhere.
if [ -n "${HERDR_PANE_ID}" ]; then
    function __herdr_pane_title() {
        [ "$__herdr_last_pwd" = "$PWD" ] && return
        __herdr_last_pwd=$PWD
        (herdr pane rename "$HERDR_PANE_ID" "${PWD/#$HOME/~}" >/dev/null 2>&1 &)
        ("$HOME/.config/herdr/report-pane-paths.sh" "$HERDR_PANE_ID" "$PWD" >/dev/null 2>&1 &)
    }
    PROMPT_COMMAND="__herdr_pane_title${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

######################################################
#################### user setting ####################
######################################################

# `claude` prefers a launcher the project ships, so a repo can pin its own
# CLAUDE_CONFIG_DIR (= which account), model, or flags. only ./bin/claude.sh
# is looked at, so this applies at the repo root and nowhere else.
#
# the fallback is deliberately limited to "this directory ships no launcher".
# bin/claude.sh ends up exec'ing claude, so its exit status IS claude's --
# falling back on a non-zero exit would relaunch claude every time you ctrl-c
# out of it. `command` is required too: a bare `claude` re-enters this function.
function claude() {
    if [ -r ./bin/claude.sh ]; then
        sh ./bin/claude.sh "$@"
        return $?
    fi
    command claude "$@"
}

alias memo="echo '[TODO]: set memo file path'" #b coder
#flumake for emacs : https://qiita.com/awakia/items/5c97b02dcc3c7fd20279

source ~/.git-branches

# machine-local settings and secrets (tokens etc.) live here, OUTSIDE of
# git management. make dotfile offers to move local-only diff lines of
# this file into it instead of committing them.
if [ -f ~/.bashrc.local ]; then
    source ~/.bashrc.local
fi
