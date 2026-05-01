#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
file_path=$(printf '%s' "$input" | extract_field "file_path")
command=$(printf '%s' "$input" | extract_field "command")
paths=()

[ -n "$file_path" ] && paths+=("$file_path")

if [ -n "$command" ]; then
  while IFS= read -r path; do
    paths+=("$path")
  done < <(printf '%s\n' "$command" | extract_patch_paths)
fi

for path in "${paths[@]}"; do
  [ -n "$path" ] || continue
  case "$path" in
    *.md) continue ;;
  esac

  dir=$(dirname "$path")
  readme=""
  if [ -f "$dir/README.md" ]; then
    readme="$dir/README.md"
  elif [ -f "$(dirname "$dir")/README.md" ]; then
    readme="$(dirname "$dir")/README.md"
  fi

  [ -n "$readme" ] || continue

  hash=$(printf '%s' "$dir" | md5 | cut -c1-8)
  stamp_file="/tmp/codex_doc_freshness_${hash}"
  [ -f "$stamp_file" ] && continue

  date +%s > "$stamp_file"
  system_message "[doc_freshness] $readme の更新が必要かもしれません。変更内容に合わせてドキュメントの確認を検討してください。"
  exit 0
done

exit 0
