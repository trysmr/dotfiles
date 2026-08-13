#!/bin/bash
set -e

dir="$(cd "$(dirname "$0")" && pwd -P)"

# ターミナル出力時のみ色を有効化（パイプやリダイレクト時は無色）
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

BREW_PREFIX="${BREW_PREFIX:-/opt/homebrew}"

# 不足パッケージをカテゴリ別配列に追加
# eval や bash 4+ の ${^^} を避け、case文で bash 3.2 互換を維持
add_missing() {
  local brew_name="$1" category="$2"
  MISSING_PKGS+=("$brew_name")
  case "$category" in
    required)    MISSING_REQUIRED+=("$brew_name") ;;
    recommended) MISSING_RECOMMENDED+=("$brew_name") ;;
    optional)    MISSING_OPTIONAL+=("$brew_name") ;;
  esac
}

# コマンドの存在チェック（結果を配列に蓄積）
# 引数: $1=表示名, $2=brewパッケージ名, $3=カテゴリ(required/recommended/optional), $4=補足メッセージ(任意)
check_command() {
  local name="$1" brew_name="$2" category="$3" note="${4:-}"
  if command -v "$name" &> /dev/null; then
    echo -e "  ${GREEN}✓${RESET} $name"
  else
    local msg="  ${RED}✗${RESET} $name (${CYAN}brew install $brew_name${RESET})"
    [[ -n "$note" ]] && msg+=" ← $note"
    echo -e "$msg"
    add_missing "$brew_name" "$category"
    return 1
  fi
}

# ファイル存在チェック（zshプラグイン用）
# 引数: $1=表示名, $2=brewパッケージ名, $3=チェック対象ファイルパス, $4=カテゴリ
check_file() {
  local name="$1" brew_name="$2" filepath="$3" category="$4"
  if [[ -f "$filepath" ]]; then
    echo -e "  ${GREEN}✓${RESET} $name"
  else
    echo -e "  ${RED}✗${RESET} $name (${CYAN}brew install $brew_name${RESET})"
    add_missing "$brew_name" "$category"
    return 1
  fi
}

# 依存関係チェックのメイン処理
check_dependencies() {
  local has_required_missing=false

  MISSING_PKGS=()
  MISSING_REQUIRED=()
  MISSING_RECOMMENDED=()
  MISSING_OPTIONAL=()

  echo ""
  echo -e "${BOLD}依存関係チェック${RESET}"
  echo "─────────────────────────────────"
  echo ""

  # 必須ツール
  echo -e "${BOLD}[必須]${RESET} インストールに必要なツール"
  check_command git git required || has_required_missing=true
  check_command curl curl required || has_required_missing=true
  echo ""

  # 推奨ツール
  echo -e "${BOLD}[推奨]${RESET} シェル体験を向上させるツール"
  check_command starship starship recommended || true
  check_command fzf fzf recommended || true
  check_command zoxide zoxide recommended || true
  check_command delta git-delta recommended "未インストール時、git diff/logでエラーになります" || true
  check_command jq jq recommended "Claude Code/Codex hookで使用" || true
  check_command mmdc mermaid-cli recommended "Mermaid自動レンダリングhookで使用" || true
  check_file zsh-autosuggestions zsh-autosuggestions \
    "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" recommended || true
  check_file zsh-syntax-highlighting zsh-syntax-highlighting \
    "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" recommended || true
  echo ""

  # 任意ツール
  echo -e "${BOLD}[任意]${RESET} 開発ツール（設定ファイルあり）"
  check_command ghq ghq optional || true
  check_command rbenv rbenv optional || true
  check_command nvim neovim optional || true
  check_command yazi yazi optional || true
  check_command fd fd optional "yaziの検索機能(/)で使用" || true
  check_command rg ripgrep optional "yaziのコンテンツ検索(?)で使用" || true
  echo ""

  echo "─────────────────────────────────"

  # 不足パッケージのサマリー表示
  if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}全ての依存ツールがインストール済みです${RESET}"
    echo ""
    return 0
  fi

  echo ""
  if [[ ${#MISSING_RECOMMENDED[@]} -gt 0 ]]; then
    echo -e "${YELLOW}推奨ツールの一括インストール:${RESET}"
    echo -e "  ${CYAN}brew install ${MISSING_RECOMMENDED[*]}${RESET}"
    echo ""
  fi
  if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
    echo -e "${YELLOW}任意ツールの一括インストール:${RESET}"
    echo -e "  ${CYAN}brew install ${MISSING_OPTIONAL[*]}${RESET}"
    echo ""
  fi
  if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo -e "${BOLD}全て一括:${RESET}"
    echo -e "  ${CYAN}brew install ${MISSING_PKGS[*]}${RESET}"
    echo ""
  fi

  # 必須ツール不足時は続行確認
  if [[ "$has_required_missing" = true ]]; then
    echo -e "${RED}必須ツールが不足しています。インストール処理に問題が発生する可能性があります。${RESET}"
    if [[ -t 0 ]]; then
      read -p "続行しますか？ [y/N] " answer
      [[ "$answer" =~ ^[Yy]$ ]] || exit 1
    else
      echo "非対話環境のため中断します。必須ツールをインストール後に再実行してください。"
      exit 1
    fi
  fi
}

# --skip-check が指定されていなければ依存チェックを実行
if [[ "$1" != "--skip-check" ]]; then
  check_dependencies
fi

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

# 既存の実体を退避先へ移動する（退避先が埋まっている場合は上書きせず1を返す）
# 退避の成否は呼び出し側が判断するため、失敗してもスクリプト全体は中断しない
move_aside() {
  local dest="$1"
  local backup_dest="$2"
  local label="$3"

  if [[ -e "$backup_dest" || -L "$backup_dest" ]]; then
    echo "Warning: $backup_dest already exists, skipping... Move it before running install.sh again." >&2
    return 1
  fi

  mkdir -p "$(dirname "$backup_dest")" || return 1
  mv "$dest" "$backup_dest" || return 1
  echo "Moved existing $label to $backup_dest"
}

# 内容が一致する既存ディレクトリだけを退避する（内容が異なる場合は保持して1を返す）
backup_matching_directory() {
  local src="$1"
  local dest="$2"
  local backup_dest="$3"

  [[ -d "$dest" && ! -L "$dest" ]] || return 0

  if ! diff -qr "$src" "$dest" > /dev/null; then
    echo "Warning: $dest differs from $src, skipping..."
    return 1
  fi

  move_aside "$dest" "$backup_dest" "directory"
}

# 内容が一致する既存ディレクトリを退避してシンボリックリンクへ切り替える
safe_symlink_matching_directory() {
  local src="$1"
  local dest="$2"
  local backup_dest="$3"

  backup_matching_directory "$src" "$dest" "$backup_dest" || return 0

  safe_symlink "$src" "$dest"
}

# SKILL.mdを持つスキルディレクトリかどうかを判定する
is_skill_dir() {
  local skill_dir="$1"

  [[ -d "$skill_dir" ]] || return 1
  [[ "$(basename "$skill_dir")" != .* ]] || return 1
  [[ -f "$skill_dir/SKILL.md" ]]
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

# rulesディレクトリのシンボリックリンクを作成する
safe_symlink "$dir/.claude/rules" "$HOME/.claude/rules"

# agentsディレクトリのシンボリックリンクを作成する
safe_symlink "$dir/.claude/agents" "$HOME/.claude/agents"

# .codexディレクトリを作成
mkdir -p "$HOME/.codex"

# AGENTS.mdのシンボリックリンクを作成する
safe_symlink "$dir/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

# config.tomlのシンボリックリンクを作成する
safe_symlink "$dir/.codex/config.toml" "$HOME/.codex/config.toml"

# コマンド実行ルールのシンボリックリンクを作成する
mkdir -p "$HOME/.codex/rules"
safe_symlink "$dir/.codex/rules/default.rules" "$HOME/.codex/rules/default.rules"

# hooks設定とhooksディレクトリのシンボリックリンクを作成する
safe_symlink "$dir/.codex/hooks.json" "$HOME/.codex/hooks.json"
safe_symlink "$dir/.codex/hooks" "$HOME/.codex/hooks"

# Herdr公式integrationの検出先からdotfiles管理のhookを参照する
safe_symlink "$dir/.codex/hooks/herdr-agent-state.sh" "$HOME/.codex/herdr-agent-state.sh"

# .copilotディレクトリを作成
mkdir -p "$HOME/.copilot"

# copilot-instructions.mdのシンボリックリンクを作成する
safe_symlink "$dir/.codex/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# Copilot USERスコープのskillsディレクトリを作成
mkdir -p "$HOME/.copilot/skills"

# Claude CodeのスキルをCopilot USERスコープへ連携する
for skill_dir in "$dir/.claude/skills"/*; do
  is_skill_dir "$skill_dir" || continue
  skill_name="$(basename "$skill_dir")"
  safe_symlink_matching_directory \
    "$skill_dir" \
    "$HOME/.copilot/skills/$skill_name" \
    "$HOME/.copilot/skills.before-dotfiles/$skill_name"
done

# Copilot USERスコープのhooksディレクトリを作成
mkdir -p "$HOME/.copilot/hooks"

# Claude CodeのhooksをCopilot USERスコープへ連携する
for hook_script in "$dir/.claude/hooks"/*; do
  [[ -f "$hook_script" ]] || continue
  safe_symlink "$hook_script" "$HOME/.copilot/hooks/$(basename "$hook_script")"
done

# Copilot用hooks設定ファイルを配置する（各プロジェクトの .github/hooks から参照可能）
safe_symlink "$dir/.github/hooks/claude-compatible.json" "$HOME/.copilot/hooks/claude-compatible.json"

# Codex USERスコープのskillsディレクトリを作成
mkdir -p "$HOME/.agents/skills"

# Codexスキルの共通リファレンスを連携する
safe_symlink "$dir/.agents/skills/_shared" "$HOME/.agents/skills/_shared"

# Codex用スキルをUSERスコープへ連携する
for skill_dir in "$dir/.agents/skills"/*; do
  is_skill_dir "$skill_dir" || continue
  skill_name="$(basename "$skill_dir")"
  # 旧配置の.codex/skillsは退避するだけでリンクは張らず、.agents/skillsへ一本化する
  backup_matching_directory \
    "$skill_dir" \
    "$HOME/.codex/skills/$skill_name" \
    "$HOME/.codex/skills.before-dotfiles/$skill_name" || true
  safe_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
done

for f in "$dir"/.??*; do
  filename="$(basename "$f")"
  [[ "$filename" = ".git" ]] && continue
  [[ "$filename" = ".claude" ]] && continue
  [[ "$filename" = ".codex" ]] && continue
  [[ "$filename" = ".copilot" ]] && continue
  [[ "$filename" = ".agents" ]] && continue

  # .configの場合はディレクトリを対象にする
  if [[ "$filename" = ".config" ]]; then
    mkdir -p "$HOME/.config"

    for config in "$dir/$filename"/*; do
      config_name="$(basename "$config")"
      config_dest="$HOME/.config/$config_name"

      # Herdrは実行時データが混ざり内容一致しないため、内容を問わず退避する
      if [[ "$config_name" = "herdr" && -d "$config_dest" && ! -L "$config_dest" ]]; then
        if move_aside "$config_dest" "$config_dest.before-dotfiles" "Herdr data"; then
          echo "セッション履歴とdotfiles管理外のPlugin登録は引き継がれません。必要な場合は $config_dest.before-dotfiles から手動で戻してください"
          echo "稼働中のHerdrはソケットの参照先が変わるため、再起動してください"
        fi
      fi

      safe_symlink "$config" "$config_dest"
    done
    continue
  fi

  safe_symlink "$dir/$filename" "$HOME/$filename"
done

# Herdrがインストール済みの場合はdotfiles管理のPluginを登録する
if command -v herdr &> /dev/null; then
  for plugin_manifest in "$dir"/.config/herdr/plugins/*/herdr-plugin.toml; do
    [[ -f "$plugin_manifest" ]] || continue
    plugin_dir="${plugin_manifest%/herdr-plugin.toml}"
    herdr plugin link "$plugin_dir" > /dev/null
  done
fi

# Git補完ファイルのダウンロード（インストール済みGitのバージョンに合わせる）
# 補完は任意機能のため、失敗しても続行
# DOTFILES_SKIP_GIT_COMPLETION=1 でスキップ（テストをネットワーク非依存にするため）
if [[ -z "${DOTFILES_SKIP_GIT_COMPLETION:-}" ]] && command -v git &> /dev/null && command -v curl &> /dev/null; then
  mkdir -p "$HOME/.zsh"
  GIT_VERSION=$(git --version | awk '{print $3}')
  GIT_COMPLETION_URL="https://raw.githubusercontent.com/git/git/v${GIT_VERSION}/contrib/completion"

  # タグが存在するか確認（Apple Gitなどは存在しない場合あり）
  if curl -fsSL --head "${GIT_COMPLETION_URL}/git-completion.bash" &> /dev/null; then
    if curl -fsSL -o "$HOME/.zsh/git-completion.bash" "${GIT_COMPLETION_URL}/git-completion.bash" && \
       curl -fsSL -o "$HOME/.zsh/_git" "${GIT_COMPLETION_URL}/git-completion.zsh" && \
       curl -fsSL -o "$HOME/.zsh/git-prompt.sh" "${GIT_COMPLETION_URL}/git-prompt.sh"; then
      echo "Git completion and prompt files downloaded for v${GIT_VERSION}"
    else
      echo "Warning: Failed to download git completion files, skipping..."
    fi
  else
    echo "Warning: Git completion files not found for v${GIT_VERSION}, skipping..."
  fi
fi
