#!/bin/bash

# ドキュメント鮮度チェック（PostToolUseフック）
# コード変更後に、同/親ディレクトリのREADME.mdの更新を促す
# .mdファイル自体の編集時はスキップ（ドキュメント更新中のノイズ防止）

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .file_path?
  ) // .toolInput.file_path? // .tool_input.file_path? // ""
')

# パスが空、またはMarkdownファイル自体の編集はスキップ
[ -z "$file_path" ] && exit 0
case "$file_path" in
  *.md) exit 0 ;;
esac

# 変更ファイルのディレクトリを取得
dir=$(dirname "$file_path")

# 同ディレクトリまたは親ディレクトリにREADME.mdが存在するか確認
readme=""
if [ -f "$dir/README.md" ]; then
  readme="$dir/README.md"
elif [ -f "$(dirname "$dir")/README.md" ]; then
  readme="$(dirname "$dir")/README.md"
fi

[ -z "$readme" ] && exit 0

# 頻度制限: 同一ディレクトリに対してセッション内で1回のみ通知
# タイムスタンプファイルを使用（セッション開始時に/tmpがクリアされる前提）
hash=$(printf '%s' "$dir" | md5 | cut -c1-8)
stamp_file="/tmp/claude_doc_freshness_${hash}"

if [ -f "$stamp_file" ]; then
  exit 0
fi

# タイムスタンプを記録
date +%s > "$stamp_file"

jq -n --arg readme "$readme" \
  '{systemMessage: ("[doc_freshness] " + $readme + " の更新が必要かもしれません。変更内容に合わせてドキュメントの確認を検討してください。")}'
