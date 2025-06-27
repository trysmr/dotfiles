#!/bin/bash

source $HOME/.zsh/git-completion.bash
source $HOME/.zsh/git-prompt.sh
PS1='\[\e[33m\]\u@\h: \[\e[32m\]\w\[\e[0m\[\e[31m$(__git_ps1 " (%s)")\[\e[0m\n\$ '

# -----
# ls
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"

# -----
# Deno
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# -----
# alias
alias ls='ls $LS_OPTIONS'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
