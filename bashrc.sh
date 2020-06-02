alias ls="ls -G"
alias dcstop="docker stop `docker ps \-a -q` "
#alias dcr="docker rm \'docker ps -a -q\'"                                                                             
#alias dcrmall="docker rm `docker ps -a -q`"                                                                           

# history上限追加
HISTSIZE=100000

# コマンド履歴操作
bind '"\C-n": history-search-forward'
bind '"\C-p": history-search-backward'
# 上矢印キー                                                                                                           
bind '"\e[A": history-search-backward'
# 下矢印キー                                                                                                           
bind '"\e[B": history-search-forward'


# bash自動補完                                                                                                         
# bash-completionが必要                                                                                                
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi



# MacPorts Installer addition on 2018-01-15_at_16:11:17: adding an appropriate PATH variable for use with MacPorts.    
export PATH=/usr/local/share/python:$PATH
export PATH=/usr/local/bin:$PATH
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.                                              


export GNUTERM=x11

alias cdi="cd ~/workspace/internview/internview-docker"
alias cds="cd ~/workspace/program/contest/contest"
alias live="curl parrot.live"
alias xcode="open -a xcode"
alias rm="trash"
#flumake for emacs : https://qiita.com/awakia/items/5c97b02dcc3c7fd20279                                               




GIT_PS1_SHOWDIRTYSTATE=true
export PS1='\[\033[32m\]\u@\h\[\033[00m\]:\[\033[31m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\n\$ '
# ターミナルの $マークの前の設定                                                                                       
# PS1="\u:\t \W $" # ユーザー名:時間 ディレクトリ名 $                                                                  
# PS1="\[\033[31m\]\u:\t \W $\[\033[0m\]"                                                                              


# nodebrew設定                                                                                                         
export PATH=$HOME/.nodebrew/current/bin:$PATH
export NODEBREW_ROOT=/usr/local/var/nodebrew
export PATH=$PATH:/usr/local/var/nodebrew/current/bin




export PATH=/usr/local/bin:$PATH


#export NVM_DIR="$HOME/.nvm"                                                                                           
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm                                                    
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion                  


#enscript --pretty-print=fortran_pp --color --line-numbers --fancy-header --landscape --columns=2 *.F90 -o sample.ps   

# ls -G                                                                                                                
# manual: man ls, find LSCOLORS                                                                                        
export LSCOLORS=Dxfxcxdxbxegexabagacad
