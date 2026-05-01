#!/bin/bash

# 契約検証（PostToolUseフック）
# 特定ファイル変更時に追加アクションを促す

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .file_path?
  ) // .toolInput.file_path? // .tool_input.file_path? // ""
')

[ -z "$file_path" ] && exit 0

case "$file_path" in
  *settings.json)
    jq -n '{systemMessage: "[contract_check] settings.jsonが変更されました。test_all.shの実行を推奨します: bash .claude/hooks/test_all.sh"}'
    ;;
  */.claude/plans/*.md)
    if [ -f "$file_path" ] && ! grep -q '^## TODO' "$file_path"; then
      jq -n '{systemMessage: "[contract_check] 計画ファイルに ## TODO セクションがありません。workflow.mdの計画ファイル構造を確認してください。"}'
    fi
    ;;
esac
