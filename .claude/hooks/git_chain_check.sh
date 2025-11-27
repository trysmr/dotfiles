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

# 許可されたgitコマンドで始まるかチェック
is_allowed_git=false
while IFS= read -r git_cmd; do
  if [[ "$command" == "$git_cmd"* ]]; then
    is_allowed_git=true
    break
  fi
done <<< "$allowed_git_commands"

# 許可されたgitコマンドの場合、チェーンをブロック
if [ "$is_allowed_git" = true ]; then
  if [[ "$command" =~ \&\& ]] || [[ "$command" =~ \; ]]; then
    echo "gitコマンドを他のコマンドとチェーンで実行することは許可されていません。コマンドは個別に実行してください。" >&2
    exit 2
  fi
fi

exit 0
