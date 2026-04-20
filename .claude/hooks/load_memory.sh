#!/bin/bash

# SessionStart (compact/clear/resume) 時にプロジェクトメモリファイルの内容を注入する。
# auto compaction後にメモリ内容が失われる問題への対策。

set -uo pipefail

source "$(dirname "$0")/_common.sh"

MAX_FILES=8
MAX_BODY_BYTES=4096

# --- メモリディレクトリの解決 ---
if [ -z "${MEMORY_DIR:-}" ]; then
  project_key=$(echo "${PWD}" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${project_key}/memory"
fi

if [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

# --- メモリファイルの収集（更新日時の新しい順、最大MAX_FILES件） ---
files=()
while IFS= read -r f; do
  [ ! -f "$f" ] && continue
  files+=("$f")
done < <(
  for f in "$MEMORY_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [ "$(basename "$f")" = "MEMORY.md" ] && continue
    echo "$f"
  done | xargs ls -t 2>/dev/null | head -n "$MAX_FILES"
)

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# --- メモリ内容の構築 ---
OUTPUT="## Auto-Memory (Project)\n\n"
LOADED_FILES=()

for f in "${files[@]}"; do
  name=$(parse_frontmatter "$f" "name")
  type=$(parse_frontmatter "$f" "type")
  body=$(strip_frontmatter "$f")

  [ -z "$body" ] && continue

  if [ ${#body} -gt $MAX_BODY_BYTES ]; then
    body=$(echo "$body" | head -c $MAX_BODY_BYTES)
    body+="..."
  fi

  name="${name:-$(basename "$f" .md)}"
  type="${type:-unknown}"

  OUTPUT+="### ${type}: ${name}\n\n${body}\n\n"
  LOADED_FILES+=("$(basename "$f")")
done

if [ ${#LOADED_FILES[@]} -eq 0 ]; then
  exit 0
fi

LOADED_LIST=$(IFS=','; echo "${LOADED_FILES[*]}" | sed 's/,/, /g')

CONTEXT=$(echo -e "$OUTPUT")
jq -n \
  --arg msg "[load_memory] Loaded: $LOADED_LIST" \
  --arg ctx "$CONTEXT" \
  '{
    systemMessage: $msg,
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
