#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
event=$(printf '%s' "$input" | hook_event_name)
file_path=$(printf '%s' "$input" | extract_field "file_path")
command=$(printf '%s' "$input" | extract_field "command")

deny_path() {
  local path="$1"
  deny_current_event "機密または危険なパスへの書き込み、またはパスの検査に失敗した書き込みは禁止されています。" "$event"
}

if [ -n "$file_path" ] && ! python3 "$(dirname "$0")/shell_token_check.py" --path "$file_path"; then
  deny_path "$file_path"
fi

if [ -n "$command" ]; then
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! python3 "$(dirname "$0")/shell_token_check.py" --path "$path"; then
      deny_path "$path"
    fi
  done < <(printf '%s\n' "$command" | extract_patch_paths)
fi

exit 0
