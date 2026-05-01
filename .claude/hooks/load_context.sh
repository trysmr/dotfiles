#!/bin/bash

# CLAUDE.md / rules / README.md / 自動メモリをまとめてコンテキストとして注入する。
# PreToolUse(2時間TTL)とSessionStart(--force)の両方で呼ばれる。

set -uo pipefail

source "$(dirname "$0")/_common.sh"

# --force が指定された場合はTTLチェックをスキップ
FORCE_RELOAD=false
if [ "${1:-}" = "--force" ]; then
  FORCE_RELOAD=true
fi

# 最後の実行時刻を保存し、一定時間経過後に再実行
# プロジェクト+メモリディレクトリでキャッシュを分離（MEMORY_DIR上書き時も再走するため）
CACHE_KEY="$(pwd):${MEMORY_DIR:-}"
PROJECT_HASH=$(echo -n "$CACHE_KEY" | md5 | cut -c1-8)
TIMESTAMP_FILE="/tmp/claude_context_timestamp_${PROJECT_HASH}"
RELOAD_INTERVAL=7200  # 2時間

if [ "$FORCE_RELOAD" != "true" ] && [ -f "$TIMESTAMP_FILE" ]; then
  LAST_TIME=$(cat "$TIMESTAMP_FILE")
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - LAST_TIME))

  if [ $ELAPSED -lt $RELOAD_INTERVAL ]; then
    exit 0
  fi
fi

# ユーザーメモリファイルのパス
USER_MEMORY="$HOME/.claude/CLAUDE.md"
# README.mdのパス
README="README.md"
# グローバルrulesディレクトリ
RULES_DIR="$HOME/.claude/rules"

OUTPUT=""
LOADED_FILES=()

# ユーザーメモリが存在する場合、内容を追加
if [ -f "$USER_MEMORY" ]; then
  OUTPUT+="## User Memory (Global)\n\n"
  OUTPUT+="$(cat "$USER_MEMORY")\n\n"
  LOADED_FILES+=("~/.claude/CLAUDE.md")
fi

# プロジェクトメモリを探す（優先順位: ./CLAUDE.md > ./.claude/CLAUDE.md）
PROJECT_MEMORY=""
if [ -f "CLAUDE.md" ]; then
  PROJECT_MEMORY="CLAUDE.md"
elif [ -f ".claude/CLAUDE.md" ]; then
  PROJECT_MEMORY=".claude/CLAUDE.md"
fi

# ローカルメモリ（gitignore対象、個人専用）
PROJECT_LOCAL_MEMORY=""
if [ -f "CLAUDE.local.md" ]; then
  PROJECT_LOCAL_MEMORY="CLAUDE.local.md"
fi

# プロジェクトメモリが存在する場合、内容を追加
# シンボリックリンクで同一ファイルを指している場合はスキップ
if [ -n "$PROJECT_MEMORY" ] && [ -f "$PROJECT_MEMORY" ] && [ -f "$USER_MEMORY" ]; then
  USER_REAL=$(realpath "$USER_MEMORY" 2>/dev/null || true)
  PROJ_REAL=$(realpath "$PROJECT_MEMORY" 2>/dev/null || true)
  if [ -n "$USER_REAL" ] && [ "$USER_REAL" = "$PROJ_REAL" ]; then
    PROJECT_MEMORY=""
  fi
fi

if [ -n "$PROJECT_MEMORY" ] && [ -f "$PROJECT_MEMORY" ]; then
  OUTPUT+="## Project Memory\n\n"
  OUTPUT+="$(cat "$PROJECT_MEMORY")\n\n"
  LOADED_FILES+=("$PROJECT_MEMORY")
fi

if [ -n "$PROJECT_LOCAL_MEMORY" ] && [ -f "$PROJECT_LOCAL_MEMORY" ]; then
  OUTPUT+="## Project Memory (Local)\n\n"
  OUTPUT+="$(cat "$PROJECT_LOCAL_MEMORY")\n\n"
  LOADED_FILES+=("$PROJECT_LOCAL_MEMORY")
fi

# グローバルrulesの読み込み（pathsフロントマターがないファイルのみ）
if [ -d "$RULES_DIR" ]; then
  for rule_file in "$RULES_DIR"/*.md; do
    [ ! -f "$rule_file" ] && continue
    if grep -q "^paths:" "$rule_file" 2>/dev/null; then
      continue
    fi
    OUTPUT+="## Rule: $(basename "$rule_file" .md)\n\n"
    OUTPUT+="$(cat "$rule_file")\n\n"
    LOADED_FILES+=("rules/$(basename "$rule_file")")
  done
fi

# README.mdが存在する場合、内容を追加
if [ -f "$README" ]; then
  OUTPUT+="## README\n\n"
  OUTPUT+="$(cat "$README")\n\n"
  LOADED_FILES+=("$README")
fi

# --- 自動メモリの読み込み ---
# MEMORY_DIRが未指定ならPWDから導出
if [ -z "${MEMORY_DIR:-}" ]; then
  project_key=$(echo "${PWD}" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${project_key}/memory"
fi

if [ -d "$MEMORY_DIR" ]; then
  memory_files=()
  while IFS= read -r f; do
    [ ! -f "$f" ] && continue
    memory_files+=("$f")
  done < <(
    for f in "$MEMORY_DIR"/*.md; do
      [ ! -f "$f" ] && continue
      [ "$(basename "$f")" = "MEMORY.md" ] && continue
      printf '%s\n' "$f"
    done
  )

  if [ ${#memory_files[@]} -gt 0 ]; then
    MEMORY_OUTPUT=""
    for f in "${memory_files[@]}"; do
      name=$(parse_frontmatter "$f" "name")
      type=$(parse_frontmatter "$f" "type")
      body=$(strip_frontmatter "$f")

      [ -z "$body" ] && continue

      name="${name:-$(basename "$f" .md)}"
      type="${type:-unknown}"

      MEMORY_OUTPUT+="### ${type}: ${name}\n\n${body}\n\n"
      LOADED_FILES+=("memory/$(basename "$f")")
    done

    if [ -n "$MEMORY_OUTPUT" ]; then
      OUTPUT+="## Auto-Memory (Project)\n\n${MEMORY_OUTPUT}"
    fi
  fi
fi

# 何か読み込んだ内容があれば出力
if [ -n "$OUTPUT" ]; then
  LOADED_LIST=$(IFS=','; echo "${LOADED_FILES[*]}" | sed 's/,/, /g')

  # 呼び出し元のイベントに応じてhookEventNameを切り替え
  # --force はSessionStartからのみ渡される
  if [ "$FORCE_RELOAD" = "true" ]; then
    HOOK_EVENT="SessionStart"
  else
    HOOK_EVENT="PreToolUse"
  fi

  # JSON形式で出力（systemMessage: ユーザー通知、additionalContext: アシスタントへのコンテキスト注入）
  CONTEXT=$(echo -e "The following context has been loaded:\n\n$OUTPUT")
  jq -n \
    --arg msg "[load_context] Loaded: $LOADED_LIST" \
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
fi
