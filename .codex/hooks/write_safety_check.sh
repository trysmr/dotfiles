#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
event=$(printf '%s' "$input" | hook_event_name)
file_path=$(printf '%s' "$input" | extract_field "file_path")
command=$(printf '%s' "$input" | extract_field "command")

deny_path() {
  local path="$1"
  deny_current_event "機密または危険なパスへの書き込みは禁止されています: $path" "$event"
}

if [ -n "$file_path" ] && is_sensitive_path "$file_path"; then
  deny_path "$file_path"
fi

if [ -n "$command" ]; then
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if is_sensitive_path "$path"; then
      deny_path "$path"
    fi
  done < <(printf '%s\n' "$command" | extract_patch_paths)
fi

exit 0
