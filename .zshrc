# zshrc設定

# ---
# emacsモード
bindkey -e

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
# 24時間以内に生成されていれば再生成をスキップ
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit -d ~/.zcompdump
else
    compinit -C -d ~/.zcompdump
fi

setopt auto_list # 一覧表示
setopt auto_menu # タブで選択
setopt list_types # 種類を表示
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 大文字小文字無視
zstyle ':completion:*:default' menu select=1 # カーソルで選択
zstyle ':completion:*' list-colors di=34 ln=35 ex=31 # 候補に色付け

# -----
# Zshプラグイン
if [[ -z "$BREW_PREFIX" ]]; then
    export BREW_PREFIX="/opt/homebrew"
fi

# 履歴から補完
# brew install zsh-autosuggestions
if [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# シンタックスハイライト
# brew install zsh-syntax-highlighting
if [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# -----
# Git
# 補完
# mkdir ~/.zsh
# curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
# curl -o ~/.zsh/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
zstyle ':completion:*:*:git:*' script $HOME/.zsh/git-completion.bash
fpath=($HOME/.zsh $fpath)

# curl -o ~/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
if [[ -f "$HOME/.zsh/git-prompt.sh" ]]; then
    source "$HOME/.zsh/git-prompt.sh"
    PS1='%F{yellow}%n@%m%f: %F{cyan}%~%f%B%F{red}$(__git_ps1 " (%s)")%f%b
\$ '
    
    GIT_PS1_SHOWDIRTYSTATE=true # state
    GIT_PS1_SHOWUNTRACKEDFILES=true # untracked
    GIT_PS1_SHOWSTASHSTATE=true # stash
    GIT_PS1_SHOWUPSTREAM=auto # upstream
else
    PS1='%F{yellow}%n@%m%f: %F{cyan}%~%f
\$ '
fi

# -----
# rbenv
rbenv() {
    eval "$(command rbenv init - zsh)"
    rbenv "$@"
}

# PATHに最小限のrbenv設定
if [[ -d "$HOME/.rbenv/shims" ]]; then
    export PATH="$HOME/.rbenv/shims:$PATH"
fi

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
# Claude Code
alias jarvis='claude'
alias yolo='claude --dangerously-skip-permissions'

# -----
# tfenv
alias tfenv='GREP_OPTIONS="--color=never" tfenv'

# -----
# Glasgow Haskell Compiler
if [[ -f "$HOME/.ghcup/env" ]]; then
    ghc() {
        source "$HOME/.ghcup/env"
        ghc "$@"
    }
    ghci() {
        source "$HOME/.ghcup/env"
        ghci "$@"
    }
    cabal() {
        source "$HOME/.ghcup/env"
        cabal "$@"
    }
fi

# -----
# Deno
if [[ -s "$HOME/.deno/env" ]]; then
    deno() {
        source "$HOME/.deno/env"
        deno "$@"
    }
fi

# -----
# その他
export GREP_OPTIONS='--color=always' # grepに色をつける
setopt correct # typo検出
setopt auto_cd # cdを自動に（ディレクトリ名だけでcd）
function chpwd() { ls } # cd後に自動でls
setopt auto_pushd # 自動でpushd
setopt pushd_ignore_dups # pushdで重複を無視

