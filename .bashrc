#!/bin/bash

# Git補完とプロンプト（存在する場合のみ読み込み）
[[ -f "$HOME/.zsh/git-completion.bash" ]] && source "$HOME/.zsh/git-completion.bash"
[[ -f "$HOME/.zsh/git-prompt.sh" ]] && source "$HOME/.zsh/git-prompt.sh"
if type __git_ps1 &> /dev/null; then
  PS1='\[\e[33m\]\u@\h: \[\e[32m\]\w\[\e[0m\]\[\e[31m$(__git_ps1 " (%s)")\[\e[0m\]\n\$ '
else
  PS1='\[\e[33m\]\u@\h: \[\e[32m\]\w\[\e[0m\]\n\$ '
fi

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
