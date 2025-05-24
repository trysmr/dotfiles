# ----
# サウンド
alias beep="afplay /System/Library/Sounds/Glass.aiff"

# -----
# 文字コード
export LANG=ja_JP.UTF-8
setopt print_eight_bit

# -----
# 変数を有効に
setopt PROMPT_SUBST

# -----
# 色を有効に
autoload -Uz colors && colors

# -----
# claude
export EDITOR=vi

# -----
# 補完機能を有効に
autoload -Uz compinit && compinit
setopt auto_list # 一覧表示
setopt auto_menu # タブで選択
setopt list_types # 種類を表示
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 大文字小文字無視
zstyle ':completion:*:default' menu select=1 # カーソルで選択
zstyle ':completion:*' list-colors di=34 ln=35 ex=31 # 候補に色付け

# -----
# Zshプラグイン
# 履歴から補完
# brew install zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# シンタックスハイライト
# brew install zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# -----
# Git
# 補完
# mkdir ~/.zsh
# curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
# curl -o ~/.zsh/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
zstyle ':completion:*:*:git:*' script $HOME/.zsh/git-completion.bash
fpath=($HOME/.zsh $fpath)

# curl -o ~/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
source $HOME/.zsh/git-prompt.sh
PS1='%F{yellow}%n@%m%f: %F{cyan}%~%f%B%F{red}$(__git_ps1 " (%s)")%f%b
\$ '

GIT_PS1_SHOWDIRTYSTATE=true # state
GIT_PS1_SHOWUNTRACKEDFILES=true # untracked
GIT_PS1_SHOWSTASHSTATE=true # stash
GIT_PS1_SHOWUPSTREAM=auto # upstream

# -----
# 履歴
export HISTSIZE=1000 # メモリに保存される履歴の件数
export SAVEHIST=10000 # 履歴ファイルに保存される履歴の件数
setopt share_history
setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_no_store

function history-all { history -E 1 }


# -----
# ls
export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls='ls -GF' # lsに色付けと種類の表示

# -----
# その他
export GREP_OPTIONS='--color=always' # grepに色をつける
setopt correct # typo検出
setopt auto_cd # cdを自動に（ディレクトリ名だけでcd）
function chpwd() { ls } # cd後に自動でls
setopt auto_pushd # 自動でpushd
setopt pushd_ignore_dups # pushdで重複を無視

# -----
# rbenv
eval "$(rbenv init - zsh)"

# -----
# tfenv
alias tfenv='GREP_OPTIONS="--color=never" tfenv'

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env
