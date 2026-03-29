#!/bin/bash

# Edit/Writeの対象ファイル安全性チェック（PreToolUseフック）
# 機密ファイルや危険パスへの書き込みをdeterministicにブロック
# permissions.denyを補完し、Edit経由のバイパスを防ぐ

input=$(cat)
is_copilot=$(printf '%s' "$input" | jq -r 'has("toolName")')
file_path=$(printf '%s' "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .file_path?
  ) // .toolInput.file_path? // .tool_input.file_path? // ""
')

[ -z "$file_path" ] && exit 0

deny() {
  local message="$1"

  if [ "$is_copilot" = "true" ]; then
    jq -nc --arg msg "$message" \
      '{"permissionDecision":"deny","permissionDecisionReason":$msg}'
    exit 0
  fi

  printf '%s\n' "$message" >&2
  exit 2
}

basename_lower=$(basename "$file_path" | tr '[:upper:]' '[:lower:]')

# .envファイルへの書き込みブロック
case "$basename_lower" in
  .env|.env.*)
    deny "環境変数ファイルへの書き込みはブロックされています: $file_path" ;;
esac

# 秘密鍵・認証情報ファイルへの書き込みブロック
case "$basename_lower" in
  *.pem|*.key|*.p12|*.pfx|*.jks)
    deny "秘密鍵ファイルへの書き込みはブロックされています: $file_path" ;;
  id_rsa*|id_ed25519*|id_ecdsa*|id_dsa*)
    deny "SSH鍵ファイルへの書き込みはブロックされています: $file_path" ;;
  credentials|credentials.*|*credentials.json)
    deny "認証情報ファイルへの書き込みはブロックされています: $file_path" ;;
esac
