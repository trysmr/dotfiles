#!/bin/bash

PROMPT_COMMAND='PS1_CMD1=$(git branch --show-current 2>/dev/null)';
PS1='\u@\h: \w(${PS1_CMD1})\\$ '

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
