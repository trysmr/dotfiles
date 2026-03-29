#!/bin/bash

# Edit/Writeの対象ファイル安全性チェック（PreToolUseフック）
# 機密ファイルや危険パスへの書き込みをdeterministicにブロック
# permissions.denyを補完し、Edit経由のバイパスを防ぐ

source "$(dirname "$0")/_common.sh"

input=$(cat)
is_copilot=$(printf '%s' "$input" | detect_copilot)
file_path=$(printf '%s' "$input" | extract_field "file_path")

[ -z "$file_path" ] && exit 0

deny() { deny_action "$1" "$is_copilot"; }

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
