#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
file_path=$(printf '%s' "$input" | extract_field "file_path")
command=$(printf '%s' "$input" | extract_field "command")
paths=()

if [ -n "$file_path" ]; then
  paths+=("$file_path")
fi

if [ -n "$command" ]; then
  while IFS= read -r path; do
    paths+=("$path")
  done < <(printf '%s\n' "$command" | extract_patch_paths)
fi

for path in "${paths[@]}"; do
  case "$path" in
    *.json) ;;
    *) continue ;;
  esac

  [ -f "$path" ] || continue

  if ! error_msg=$(jq '.' "$path" 2>&1 >/dev/null); then
    system_message "JSON構文エラー ($path): $error_msg"
    exit 0
  fi
done

exit 0
