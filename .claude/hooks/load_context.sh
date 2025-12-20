#!/bin/bash

# 最後の実行時刻を保存し、一定時間経過後に再実行
# プロジェクトごとにキャッシュを分離（PWDのハッシュ値を使用）
PROJECT_HASH=$(echo -n "$PWD" | md5 | cut -c1-8)
TIMESTAMP_FILE="/tmp/claude_context_timestamp_${PROJECT_HASH}"
RELOAD_INTERVAL=3600  # 1時間（3600秒）

if [ -f "$TIMESTAMP_FILE" ]; then
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
  echo -e "The following context has been loaded:\n\n$OUTPUT"
  # タイムスタンプを更新
  date +%s > "$TIMESTAMP_FILE"
fi
