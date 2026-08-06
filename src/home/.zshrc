########################################################
#################### global setting ####################
########################################################

# zsh prompt style (same look as bashrc: user@host:path (branch) time)
setopt PROMPT_SUBST
GIT_PS1_SHOWDIRTYSTATE=true
PROMPT=$'\n%F{green}%n@%m%f:%F{yellow}%~%f%F{red}$(__git_ps1)%f %F{cyan}%*%f\n%(!.#.$) '

# shell system language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ls color
export LSCOLORS=Dxfxcxdxbxegexabagacad
alias ls="ls -G"

# command history (unlike bash, zsh needs HISTFILE/SAVEHIST to persist)
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY # write each command as it runs, not only on exit

# command history operation.
# up/down arrow: classic one-by-one prefix search, cursor stays where it is.
bindkey '^[[A' history-beginning-search-backward # up-arrow-key
bindkey '^[[B' history-beginning-search-forward # down-arrow-key

# Ctrl-P/N: list matching history lines in a Tab-style menu below the
# prompt (menu-select), navigate with Ctrl-P/N, Enter to pick.
# the completion system and history recall are separate in zsh, so this
# custom widget feeds history lines into the completion menu.
zmodload -i zsh/complist
_history_line_menu() {
    local -a lines
    lines=(${(f)"$(fc -lnr 1 2>/dev/null)"})   # all history, newest first
    lines=(${(u)${(M)lines:#${(b)_hlm_prefix}*}}) # match typed prefix, dedupe
    (( $#lines )) || return 1
    # -l -d: list one candidate per line so up/down moves one item at a time
    # -S '': no trailing space when a line is applied
    compadd -U -Q -2 -S '' -V history -l -d lines -- "${lines[@]}"
}
zle -C _history_line_menu_complete menu-select _history_line_menu
# while the menu is open, pin the cursor (display included) right after
# the typed prefix on every redraw: candidates splice in around it.
_hlm_pin_cursor() { CURSOR=$#_hlm_prefix }
history-line-menu() {
    _hlm_prefix=$LBUFFER # search on the text left of the cursor only
    local orig_buffer=$BUFFER orig_cursor=$CURSOR
    BUFFER=""
    local st
    zle -N zle-line-pre-redraw _hlm_pin_cursor
    {
        zle _history_line_menu_complete
        st=$?
    } always {
        zle -D zle-line-pre-redraw # never leave the pin hook behind
    }
    if (( st != 0 )) || [ -z "$BUFFER" ] || [ "${BUFFER% }" = "$_hlm_prefix" ]; then
        BUFFER=$orig_buffer # no match, aborted, or empty choice: keep typed line
        CURSOR=$orig_cursor
    else
        CURSOR=$#_hlm_prefix # cursor stays where typing stopped
    fi
}
zle -N history-line-menu
bindkey '^P' history-line-menu
bindkey '^N' history-line-menu
bindkey -M menuselect '^P' up-line-or-history # move inside the menu
bindkey -M menuselect '^N' down-line-or-history
# Ctrl-F/B/A/E inside the menu: move the input cursor, not the selection.
# the plain cursor-movement widgets are special-cased to move the menu
# mark, so wrap them under other names: these exit the menu keeping the
# current candidate, then move the cursor.
menu-keep-forward-char() { zle .forward-char }
menu-keep-backward-char() { zle .backward-char }
menu-keep-beginning-of-line() { zle .beginning-of-line }
menu-keep-end-of-line() { zle .end-of-line }
zle -N menu-keep-forward-char
zle -N menu-keep-backward-char
zle -N menu-keep-beginning-of-line
zle -N menu-keep-end-of-line
bindkey -M menuselect '^F' menu-keep-forward-char
bindkey -M menuselect '^B' menu-keep-backward-char
bindkey -M menuselect '^A' menu-keep-beginning-of-line
bindkey -M menuselect '^E' menu-keep-end-of-line

######################################################
#################### brew setting ####################
######################################################

# trash, `rm` command to mv file into trash box
alias rm="trash"

# completion: zsh ships its own (git included), bash-completion not needed
autoload -Uz compinit && compinit

# Tab: same fixed-cursor rule as the Ctrl-P/N history menu. the first Tab
# opens the interactive menu right away (menu-select widget, so the
# in-menu keys Ctrl-F/B/A/E and Tab-to-cycle work as usual) and the cursor
# stays where typing stopped while candidates are cycled.
tab-complete-stay() {
    _hlm_prefix=$LBUFFER # pin where typing stopped
    zle -N zle-line-pre-redraw _hlm_pin_cursor
    {
        zle menu-select
    } always {
        zle -D zle-line-pre-redraw # never leave the pin hook behind
    }
    CURSOR=$#_hlm_prefix
}
zle -N tab-complete-stay
bindkey '^I' tab-complete-stay

# git prompt for PROMPT above (__git_ps1 supports zsh)
source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh

# ghostty shell integration: window title = cwd, new tab inherits cwd.
# GHOSTTY_RESOURCES_DIR is only set inside ghostty, so this is a no-op elsewhere.
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

# herdr: show current directory on this pane's border (like tmux pane-border-format).
# HERDR_PANE_ID is only set inside herdr panes, so this is a no-op elsewhere.
if [ -n "${HERDR_PANE_ID}" ]; then
    function __herdr_pane_title() {
        [ "$__herdr_last_pwd" = "$PWD" ] && return
        __herdr_last_pwd=$PWD
        (herdr pane rename "$HERDR_PANE_ID" "${PWD/#$HOME/~}" >/dev/null 2>&1 &)
    }
    precmd_functions+=(__herdr_pane_title)
fi

######################################################
#################### user setting ####################
######################################################

alias memo="echo '[TODO]: set memo file path'" #b coder

# git-branches is written in bash (${!arr[@]} etc. do not work in zsh).
# it only operates in subshells, so delegating to a child bash is safe.
function git-branches() {
    bash -c 'source ~/.git-branches && git-branches "$@"' git-branches "$@"
}

# machine-local settings and secrets (tokens etc.) live here, OUTSIDE of
# git management. make dotfile offers to move local-only diff lines of
# shell rc files into this file instead of committing them.
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
