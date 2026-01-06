#!/bin/bash

# gitコマンドのチェーン実行を防止するPreToolUseフック
# 許可リストのgitコマンドが && や ; と組み合わせて実行されることを防ぐ

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

# settings.jsonからgit関連の許可パターンを動的に取得
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

# permissions.allowから"Bash(git "で始まるエントリを抽出し、gitコマンド部分を取得
# 例: "Bash(git add:*)" -> "git add"
allowed_git_commands=$(jq -r '.permissions.allow[]? // empty' "$SETTINGS_FILE" 2>/dev/null | \
  grep --color=never '^Bash(git ' | \
  sed 's/^Bash(\(git [^:]*\).*/\1/')

# 許可リストが空の場合は何もしない
if [ -z "$allowed_git_commands" ]; then
  exit 0
fi

# gitコマンドからグローバルオプションをスキップしてサブコマンドを抽出
# 例: "git -C /path status --short" -> "git status"
extract_git_subcommand() {
  local cmd="$1"
  local words=()

  # コマンドを単語に分割（glob展開を無効化）
  set -f
  read -ra words <<< "$cmd"
  set +f

  # 最初の単語が "git" でなければ空を返す
  if [[ "${words[0]}" != "git" ]]; then
    echo ""
    return
  fi

  local i=1
  local len=${#words[@]}

  # グローバルオプションをスキップ
  while (( i < len )); do
    local word="${words[$i]}"
    case "$word" in
      # 引数を取るオプション（次の単語もスキップ）
      -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env)
        (( i += 2 ))
        ;;
      # 引数を取るオプション（=で結合された形式）
      -C=*|--git-dir=*|--work-tree=*|--namespace=*|-c=*|--config-env=*)
        (( i += 1 ))
        ;;
      # 引数を取らないオプション
      --bare|--no-replace-objects|--literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs|--no-optional-locks|-p|--paginate|-P|--no-pager|--version|--help|--html-path|--man-path|--info-path|--exec-path|--exec-path=*)
        (( i += 1 ))
        ;;
      # オプションでない単語 = サブコマンド
      *)
        echo "git ${words[$i]}"
        return
        ;;
    esac
  done

  # サブコマンドが見つからなかった場合
  echo ""
}

# gitコマンドを正規化してサブコマンドを取得
normalized_git_cmd=$(extract_git_subcommand "$command")

# 許可されたgitコマンドで始まるかチェック
is_allowed_git=false
if [[ -n "$normalized_git_cmd" ]]; then
  while IFS= read -r git_cmd; do
    if [[ "$normalized_git_cmd" == "$git_cmd"* ]]; then
      is_allowed_git=true
      break
    fi
  done <<< "$allowed_git_commands"
fi

# 許可されたgitコマンドの場合、チェーンをブロック
if [ "$is_allowed_git" = true ]; then
  if [[ "$command" =~ \&\& ]] || [[ "$command" =~ \; ]]; then
    echo "gitコマンドを他のコマンドとチェーンで実行することは許可されていません。コマンドは個別に実行してください。" >&2
    exit 2
  fi
fi

exit 0
