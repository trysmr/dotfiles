#!/bin/bash

# JSON構文検証（PostToolUseフック）
# Edit/Write後にJSONファイルの構文エラーを即座に検出する

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .file_path?
  ) // .toolInput.file_path? // .tool_input.file_path? // ""
')

# JSONファイル以外は早期終了
case "$file_path" in
  *.json) ;;
  *) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

if ! jq empty "$file_path" 2>/dev/null; then
  jq -n --arg msg "JSON構文エラー: $file_path を確認してください" \
    '{systemMessage: $msg}'
fi
