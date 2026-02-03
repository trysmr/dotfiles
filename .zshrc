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
# Git補完
# mkdir ~/.zsh
# curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
# curl -o ~/.zsh/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
zstyle ':completion:*:*:git:*' script $HOME/.zsh/git-completion.bash
fpath=($HOME/.zsh $fpath)

# -----
# starship（プロンプト）
# brew install starship
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
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
alias ls='ls -GF'
alias ll='ls -la'

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
# zoxide
# brew install zoxide
if command -v zoxide &> /dev/null; then
    cd() {
        unfunction cd
        eval "$(zoxide init zsh --cmd cd)"
        cd "$@"
    }
fi

# -----
# fzf
# brew install fzf
if command -v fzf &> /dev/null; then
    # カスタム関数は起動時にロード（gb, repos などをすぐに使えるように）
    [[ -f "$HOME/.zsh/fzf-functions.zsh" ]] && source "$HOME/.zsh/fzf-functions.zsh"

    # fzf の設定を遅延ロード（初回キーバインド使用時にロード）
    __fzf_init() {
        unfunction __fzf_init

        # 環境変数設定をロード
        [[ -f "$HOME/.zsh/fzf.zsh" ]] && source "$HOME/.zsh/fzf.zsh"

        # Homebrew の fzf shell integration をロード
        if [[ -f "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
            source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
        fi
        if [[ -f "$BREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
            source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"
        fi
    }

    # キーバインド使用時に初回ロード
    fzf-file-widget() {
        __fzf_init
        zle fzf-file-widget
    }
    fzf-cd-widget() {
        __fzf_init
        zle fzf-cd-widget
    }
    fzf-history-widget() {
        __fzf_init
        zle fzf-history-widget
    }

    zle -N fzf-file-widget
    zle -N fzf-cd-widget
    zle -N fzf-history-widget

    bindkey '^T' fzf-file-widget
    bindkey '\ec' fzf-cd-widget
    bindkey '^R' fzf-history-widget
fi

# -----
# その他
alias grep='grep --color=auto' # grepに色をつける
setopt correct # typo検出
setopt auto_cd # cdを自動に（ディレクトリ名だけでcd）
function chpwd() { ls } # cd後に自動でls
setopt auto_pushd # 自動でpushd
setopt pushd_ignore_dups # pushdで重複を無視

export PATH="$HOME/.local/bin:$PATH"
