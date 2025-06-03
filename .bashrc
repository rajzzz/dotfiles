#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

PS1='[\u@\h \W]\$ '
export PATH="$HOME/.cargo/bin:$PATH"

export PATH=$PATH:/home/raj/.spicetify
source /usr/share/nvm/init-nvm.sh
export PATH="$HOME/.local/bin:$PATH"
export PATH="/snap/bin:$PATH"

