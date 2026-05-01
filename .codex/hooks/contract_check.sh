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
  case "$path" in
    *.codex/config.toml|*.codex/hooks.json|*.codex/hooks/*|.codex/config.toml|.codex/hooks.json|.codex/hooks/*)
      system_message "[contract_check] Codex設定またはhookが変更されました。Codex CLIの再起動とhook単体テストを推奨します。"
      exit 0
      ;;
    */.agents/skills/*/SKILL.md|.agents/skills/*/SKILL.md)
      if [ -f "$path" ] && ! sed -n '1,8p' "$path" | grep -q '^name:'; then
        system_message "[contract_check] skill frontmatterにnameが見つかりません: $path"
        exit 0
      fi
      ;;
  esac
done

exit 0
