#!/bin/bash

PROMPT_COMMAND='PS1_CMD1=$(git branch --show-current 2>/dev/null)';
PS1='\[\e[33m\]\u@\h: \[\e[32m\]\w\[\e[0m\[\e[31m(${PS1_CMD1})\[\e[0m\n\$ '

# ls
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"

# alias
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
