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

if ! error_msg=$(jq '.' "$file_path" 2>&1 >/dev/null); then
  jq -n --arg msg "JSON構文エラー ($file_path): $error_msg" \
    '{systemMessage: $msg}'
fi
