#!/bin/bash

# Read/Edit/Writeの対象ファイル安全性チェック（PreToolUseフック）
# 機密ファイルや危険パスへの書き込みをdeterministicにブロック
# permissions.denyを補完し、Edit経由のバイパスを防ぐ

source "$(dirname "$0")/_common.sh" || exit 2

input=$(cat)
is_copilot=$(printf '%s' "$input" | detect_copilot)
file_path=$(printf '%s' "$input" | extract_field "file_path")

deny() { deny_action "$1" "$is_copilot"; }

if ! result=$(printf '%s' "$input" | python3 "$(dirname "$0")/argument_safety_check.py" --write 2>/dev/null); then
  deny "${result:-書き込み先の安全性を確認できないため拒否しました。}"
fi

basename_lower=$(basename "$file_path" | tr '[:upper:]' '[:lower:]')

# 秘密鍵・認証情報ファイルへの書き込みブロック
case "$basename_lower" in
  *.pem|*.key|*.p12|*.pfx|*.jks)
    deny "秘密鍵ファイルへの書き込みはブロックされています: $file_path" ;;
  id_rsa*|id_ed25519*|id_ecdsa*|id_dsa*)
    deny "SSH鍵ファイルへの書き込みはブロックされています: $file_path" ;;
  credentials|credentials.*|*credentials.json)
    deny "認証情報ファイルへの書き込みはブロックされています: $file_path" ;;
esac
