#!/bin/bash

# --force が指定された場合はTTLチェックをスキップ
FORCE_RELOAD=false
if [ "${1:-}" = "--force" ]; then
  FORCE_RELOAD=true
fi

# 最後の実行時刻を保存し、一定時間経過後に再実行
# プロジェクトごとにキャッシュを分離（PWDのハッシュ値を使用）
PROJECT_HASH=$(echo -n "$(pwd)" | md5 | cut -c1-8)
TIMESTAMP_FILE="/tmp/claude_context_timestamp_${PROJECT_HASH}"
RELOAD_INTERVAL=3600  # 1時間

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

OUTPUT=""

# ユーザーメモリが存在する場合、内容を追加
if [ -f "$USER_MEMORY" ]; then
  OUTPUT+="## User Memory (Global)\n\n"
  OUTPUT+="$(cat "$USER_MEMORY")\n\n"
fi

# プロジェクトメモリを探す（優先順位: ./CLAUDE.md > ./.claude/CLAUDE.md）
PROJECT_MEMORY=""
if [ -f "CLAUDE.md" ]; then
  PROJECT_MEMORY="CLAUDE.md"
elif [ -f ".claude/CLAUDE.md" ]; then
  PROJECT_MEMORY=".claude/CLAUDE.md"
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
fi

# README.mdが存在する場合、内容を追加
if [ -f "$README" ]; then
  OUTPUT+="## README\n\n"
  OUTPUT+="$(cat "$README")\n\n"
fi

# 何か読み込んだ内容があれば出力
if [ -n "$OUTPUT" ]; then
  # 読み込んだファイル一覧を作成
  LOADED_FILES=()
  [ -f "$USER_MEMORY" ] && LOADED_FILES+=("~/.claude/CLAUDE.md")
  [ -n "$PROJECT_MEMORY" ] && [ -f "$PROJECT_MEMORY" ] && LOADED_FILES+=("$PROJECT_MEMORY")
  [ -f "$README" ] && LOADED_FILES+=("$README")
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
