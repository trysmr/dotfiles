#!/bin/bash

INPUT=$(cat)
DATE=$(date +%Y-%m-%d)
LOG_DIR="$HOME/.claude/tool_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$DATE.jsonl"

# 1行JSONとして追記（公式な JSONL 形式）
echo "$INPUT" | jq -c '.' >> "$LOG_FILE"