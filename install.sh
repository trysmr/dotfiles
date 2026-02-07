#!/bin/bash
set -e

dir="$(cd "$(dirname "$0")" && pwd -P)"

# シンボリックリンクを安全に作成する関数
# 既存の実ディレクトリがある場合は警告してスキップ
safe_symlink() {
  local src="$1"
  local dest="$2"

  if [[ -d "$dest" && ! -L "$dest" ]]; then
    echo "Warning: $dest exists and is not a symlink, skipping..."
    return 0
  fi

  ln -snf "$src" "$dest"
}

# .claudeディレクトリを作成（認証情報保護のため700）
mkdir -p "$HOME/.claude"
chmod 700 "$HOME/.claude"

# CLAUDE.mdのシンボリックリンクを作成する
safe_symlink "$dir/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# settings.jsonのシンボリックリンクを作成する
safe_symlink "$dir/.claude/settings.json" "$HOME/.claude/settings.json"

# hooksディレクトリのシンボリックリンクを作成する
safe_symlink "$dir/.claude/hooks" "$HOME/.claude/hooks"

# skillsディレクトリのシンボリックリンクを作成する
safe_symlink "$dir/.claude/skills" "$HOME/.claude/skills"

# statusline.shのシンボリックリンクを作成する
safe_symlink "$dir/.claude/statusline.sh" "$HOME/.claude/statusline.sh"

# .codexディレクトリを作成
mkdir -p "$HOME/.codex"

# AGENTS.mdのシンボリックリンクを作成する
safe_symlink "$dir/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"

# Codex USERスコープのskillsディレクトリを作成
mkdir -p "$HOME/.agents/skills"

# Claude CodeのスキルをCodex USERスコープへ連携する
for skill_dir in "$dir/.claude/skills"/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  [[ "$skill_name" = .* ]] && continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  safe_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
done

for f in "$dir"/.??*; do
  filename="$(basename "$f")"
  [[ "$filename" = ".git" ]] && continue
  [[ "$filename" = ".claude" ]] && continue

  # .configの場合はディレクトリを対象にする
  if [[ "$filename" = ".config" ]]; then
    mkdir -p "$HOME/.config"

    for config in "$dir/$filename"/*; do
      safe_symlink "$config" "$HOME/.config/$(basename "$config")"
    done
    continue
  fi

  safe_symlink "$dir/$filename" "$HOME/$filename"
done

# Git補完ファイルのダウンロード（インストール済みGitのバージョンに合わせる）
# 補完は任意機能のため、失敗しても続行
if command -v git &> /dev/null && command -v curl &> /dev/null; then
  mkdir -p "$HOME/.zsh"
  GIT_VERSION=$(git --version | awk '{print $3}')
  GIT_COMPLETION_URL="https://raw.githubusercontent.com/git/git/v${GIT_VERSION}/contrib/completion"

  # タグが存在するか確認（Apple Gitなどは存在しない場合あり）
  if curl -fsSL --head "${GIT_COMPLETION_URL}/git-completion.bash" &> /dev/null; then
    if curl -fsSL -o "$HOME/.zsh/git-completion.bash" "${GIT_COMPLETION_URL}/git-completion.bash" && \
       curl -fsSL -o "$HOME/.zsh/_git" "${GIT_COMPLETION_URL}/git-completion.zsh"; then
      echo "Git completion files downloaded for v${GIT_VERSION}"
    else
      echo "Warning: Failed to download git completion files, skipping..."
    fi
  else
    echo "Warning: Git completion files not found for v${GIT_VERSION}, skipping..."
  fi
fi
