#!/bin/bash

# プロジェクトメモリファイルの内容を注入する。
# PreToolUse（1時間TTL）とSessionStart（--force）の両方で呼ばれる。

set -uo pipefail

source "$(dirname "$0")/_common.sh"

# --force が指定された場合はTTLチェックをスキップ
FORCE_RELOAD=false
if [ "${1:-}" = "--force" ]; then
  FORCE_RELOAD=true
fi

# TTLキャッシュ（プロジェクト+メモリディレクトリで分離）
CACHE_KEY="$(pwd):${MEMORY_DIR:-}"
PROJECT_HASH=$(echo -n "$CACHE_KEY" | md5 | cut -c1-8)
TIMESTAMP_FILE="/tmp/claude_memory_timestamp_${PROJECT_HASH}"
RELOAD_INTERVAL=3600  # 1時間

if [ "$FORCE_RELOAD" != "true" ] && [ -f "$TIMESTAMP_FILE" ]; then
  LAST_TIME=$(cat "$TIMESTAMP_FILE")
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - LAST_TIME))

  if [ $ELAPSED -lt $RELOAD_INTERVAL ]; then
    exit 0
  fi
fi

# --- メモリディレクトリの解決 ---
if [ -z "${MEMORY_DIR:-}" ]; then
  project_key=$(echo "${PWD}" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${project_key}/memory"
fi

if [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

# --- メモリファイルの収集（全件） ---
files=()
while IFS= read -r f; do
  [ ! -f "$f" ] && continue
  files+=("$f")
done < <(
  for f in "$MEMORY_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [ "$(basename "$f")" = "MEMORY.md" ] && continue
    printf '%s\n' "$f"
  done
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

  name="${name:-$(basename "$f" .md)}"
  type="${type:-unknown}"

  OUTPUT+="### ${type}: ${name}\n\n${body}\n\n"
  LOADED_FILES+=("$(basename "$f")")
done

if [ ${#LOADED_FILES[@]} -eq 0 ]; then
  exit 0
fi

LOADED_LIST=$(IFS=','; echo "${LOADED_FILES[*]}" | sed 's/,/, /g')

# 呼び出し元のイベントに応じてhookEventNameを切り替え
if [ "$FORCE_RELOAD" = "true" ]; then
  HOOK_EVENT="SessionStart"
else
  HOOK_EVENT="PreToolUse"
fi

CONTEXT=$(echo -e "$OUTPUT")
jq -n \
  --arg msg "[load_memory] Loaded: $LOADED_LIST" \
  --arg ctx "$CONTEXT" \
  --arg evt "$HOOK_EVENT" \
  '{
    systemMessage: $msg,
    hookSpecificOutput: {
      hookEventName: $evt,
      additionalContext: $ctx
    }
  }'

# タイムスタンプを更新
date +%s > "$TIMESTAMP_FILE"
