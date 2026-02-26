# fzf カスタム関数（Git/ghq/zoxide 連携）

# =============================================================================
# Git 連携関数
# =============================================================================

# Git ブランチ切替（プレビュー付き）
fzf-git-branches() {
  # Git リポジトリ内かチェック
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Gitリポジトリ内で実行してください"
    return 1
  fi

  local branches branch
  branches=$(git branch --all --sort=-committerdate | grep -v HEAD) &&
  branch=$(echo "$branches" |
    fzf --height=60% \
        --ansi \
        --preview 'git log --oneline --graph --color=always --date=short --pretty="format:%C(auto)%h %C(blue)%ad %C(yellow)%an %C(auto)%d %s" $(echo {} | sed "s/.* //" | sed "s#remotes/[^/]*/##") | head -50' \
        --preview-window='right:60%:wrap:border-left' \
        --header='🌿 ブランチを選択 | Enter: チェックアウト | Esc: キャンセル') &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
alias gb='fzf-git-branches'

# Git コミット検索
fzf-git-commits() {
  # Git リポジトリ内かチェック
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Gitリポジトリ内で実行してください"
    return 1
  fi

  local commit
  commit=$(git log --oneline --color=always --date=short --pretty="format:%C(yellow)%h %C(blue)%ad %C(green)%an %C(auto)%s" |
    fzf --ansi \
        --height=80% \
        --preview 'git show --color=always --stat --patch {1}' \
        --preview-window='right:60%:wrap:border-left' \
        --header='📝 コミットを選択 | Enter: ハッシュをコピー | Ctrl-Y: コピー' \
        --bind='ctrl-y:execute-silent(echo -n {1} | pbcopy)+abort' |
    awk '{print $1}')

  if [[ -n "$commit" ]]; then
    echo -n "$commit" | pbcopy
    echo "✓ コミットハッシュをコピーしました: $commit"
  fi
}
alias gco='fzf-git-commits'

# Git 変更ファイルの差分表示
fzf-git-diff() {
  # Git リポジトリ内かチェック
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Gitリポジトリ内で実行してください"
    return 1
  fi

  local file
  file=$(git diff --name-only |
    fzf --height=80% \
        --preview 'git diff --color=always {}' \
        --preview-window='right:60%:wrap:border-left' \
        --header='📊 変更ファイルを選択 | Enter: パスをコピー')

  if [[ -n "$file" ]]; then
    echo -n "$file" | pbcopy
    echo "✓ ファイルパスをコピーしました: $file"
  fi
}
alias gd='fzf-git-diff'

# Git インタラクティブステージング
fzf-git-add() {
  # Git リポジトリ内かチェック
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Gitリポジトリ内で実行してください"
    return 1
  fi

  local files
  files=$(git status --short |
    fzf --multi \
        --height=80% \
        --preview 'if [[ {1} == "??" ]]; then cat {2} 2>/dev/null; else git diff --color=always {2}; fi' \
        --preview-window='right:60%:wrap:border-left' \
        --header='➕ ステージするファイルを選択（Tab: 複数選択）| Enter: git add' |
    awk '{print $2}')

  if [[ -n "$files" ]]; then
    echo "$files" | xargs git add
    echo "✓ 以下のファイルをステージしました:"
    echo "$files" | sed 's/^/  /'
  fi
}
alias ga='fzf-git-add'

# =============================================================================
# ghq 連携関数（ghq がインストールされている場合のみ定義）
# =============================================================================

if command -v ghq &> /dev/null; then
  # ghq リポジトリ検索・移動
  fzf-ghq() {
    local repo
    repo=$(ghq list | fzf --height=60% \
      --preview 'ls -la $(ghq root)/{} 2>/dev/null' \
      --preview-window='right:50%:wrap:border-left' \
      --header='📦 リポジトリを選択して移動')

    if [[ -n "$repo" ]]; then
      cd "$(ghq root)/$repo"
    fi
  }
  alias repos='fzf-ghq'

  # ghq リポジトリを VSCode で開く
  fzf-ghq-code() {
    if ! command -v code &> /dev/null; then
      echo "⚠️  VSCode (code コマンド) が見つかりません"
      return 1
    fi

    local repo
    repo=$(ghq list | fzf --height=60% \
      --preview 'ls -la $(ghq root)/{} 2>/dev/null' \
      --preview-window='right:50%:wrap:border-left' \
      --header='📦 リポジトリを選択して VSCode で開く')

    if [[ -n "$repo" ]]; then
      code "$(ghq root)/$repo"
    fi
  }
  alias reposc='fzf-ghq-code'
fi

# =============================================================================
# zoxide 連携（zoxide がインストールされている場合のみ定義）
# =============================================================================

if command -v zoxide &> /dev/null; then
  # ghq管理リポジトリでzoxideに未登録のものを登録
  # zoxide query --list と ghq list -p の差分から未登録を検出
  __zoxide_add_missing_ghq() {
    command -v ghq &> /dev/null || return
    comm -13 <(zoxide query --list | sort) <(ghq list -p | sort) | \
      while IFS= read -r dir; do
        zoxide add "$dir"
      done
  }

  # zoxide インタラクティブモード（ghq連携付き）
  zi() {
    # zoxide未初期化の場合は初期化（cd より先に zi が呼ばれるケース対応）
    if typeset -f __ensure_zoxide_init > /dev/null 2>&1; then
      __ensure_zoxide_init
    fi
    __zoxide_add_missing_ghq
    cdi "$@" || true
  }
fi

# =============================================================================
# tmux 連携関数
# =============================================================================

# tmux セッションを選択して削除
fzf-tmux-kill-session() {
  local sessions
  sessions=$(tmux list-sessions -F "#{session_name}: #{session_windows} windows (created #{session_created_string})" 2>/dev/null)

  if [[ -z "$sessions" ]]; then
    echo "⚠️  tmux セッションがありません"
    return 1
  fi

  local selected
  selected=$(echo "$sessions" |
    fzf --multi \
        --height=60% \
        --header='🗑️  削除するセッションを選択（Tab: 複数選択）| Enter: 削除' |
    cut -d: -f1)

  if [[ -n "$selected" ]]; then
    echo "$selected" | while read -r session; do
      tmux kill-session -t "$session"
      echo "✓ セッションを削除しました: $session"
    done
  fi
}
alias tks='fzf-tmux-kill-session'
