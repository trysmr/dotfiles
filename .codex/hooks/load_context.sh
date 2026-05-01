#!/bin/bash

set -u

force=false
if [ "${1:-}" = "--force" ]; then
  force=true
fi

project_hash=$(printf '%s' "$(pwd)" | md5 | cut -c1-8)
timestamp_file="/tmp/codex_context_timestamp_${project_hash}"
reload_interval=3600

if [ "$force" != "true" ] && [ -f "$timestamp_file" ]; then
  last_time=$(cat "$timestamp_file")
  current_time=$(date +%s)
  elapsed=$((current_time - last_time))
  [ "$elapsed" -lt "$reload_interval" ] && exit 0
fi

output=""
loaded=()

if [ -d ".codex/rules" ]; then
  for rule_file in .codex/rules/*.md; do
    [ -f "$rule_file" ] || continue
    output+="## Codex Rule: $(basename "$rule_file" .md)\n\n"
    output+="$(cat "$rule_file")\n\n"
    loaded+=("$rule_file")
  done
fi

if [ -f "README.md" ]; then
  output+="## README\n\n"
  output+="$(cat README.md)\n\n"
  loaded+=("README.md")
fi

[ -n "$output" ] || exit 0

loaded_list=$(IFS=','; echo "${loaded[*]}" | sed 's/,/, /g')
context=$(printf 'The following Codex context has been loaded:\n\n%b' "$output")

jq -n \
  --arg msg "[load_context] Loaded: $loaded_list" \
  --arg ctx "$context" \
  '{
    systemMessage: $msg,
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'

date +%s > "$timestamp_file"
