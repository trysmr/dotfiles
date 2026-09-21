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
  check_command tree-sitter tree-sitter-cli optional "nvim-treesitterのパーサーコンパイルで使用" || true
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

for f in "$dir"/.??*; do
  filename="$(basename "$f")"
  [[ "$filename" = ".git" ]] && continue
    # AI coding tool settings are installed from ~/Codes/agent-config.
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
