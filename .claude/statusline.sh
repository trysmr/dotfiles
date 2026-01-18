#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name' 2>/dev/null)
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir' 2>/dev/null)
DIR_NAME=""
if [ -n "$CURRENT_DIR" ] && [ "$CURRENT_DIR" != "null" ]; then
    DIR_NAME=$(basename "$CURRENT_DIR" 2>/dev/null)
fi

# Git情報
GIT_INFO=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)

    # 未コミットの変更数
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | xargs)
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | xargs)
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | xargs)

    CHANGES="${CHANGES}+${STAGED}"
    CHANGES="${CHANGES},~${UNSTAGED}"
    CHANGES="${CHANGES},?${UNTRACKED}"

    if [ -n "$CHANGES" ]; then
        GIT_INFO="${BRANCH} (${CHANGES})"
    else
        GIT_INFO="${BRANCH}"
    fi
fi

# コンテキスト
CONTEXT_INFO=""
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size' 2>/dev/null)
USAGE=$(echo "$input" | jq '.context_window.current_usage' 2>/dev/null)

if [ "$USAGE" != "null" ] && [ -n "$CONTEXT_SIZE" ] && [ "$CONTEXT_SIZE" != "null" ] && [ "$CONTEXT_SIZE" -gt 0 ] 2>/dev/null; then
    # current_usageからコンテキスト使用量を計算（キャッシュ含む）
    INPUT_TOKENS=$(echo "$USAGE" | jq -r '.input_tokens // 0' 2>/dev/null)
    CACHE_CREATE=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0' 2>/dev/null)
    CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0' 2>/dev/null)
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    CONTEXT_INFO="${PERCENT_USED}%"
fi

# コスト
COST_INFO=""
TOTAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd' 2>/dev/null)
if [ -n "$TOTAL_COST" ] && [ "$TOTAL_COST" != "null" ]; then
    # 小数点以下4桁まで表示
    COST_INFO="\$$(printf "%.4f" "$TOTAL_COST")"
fi

RED_BOLD='\033[1;31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE_BOLD='\033[1;34m'
MAGENTA_BOLD='\033[1;35m'
CYAN='\033[1;36m'
RESET='\033[0m'

echo -e "[${BLUE_BOLD}${MODEL}${RESET}] ${CYAN}${DIR_NAME}${RESET} | ${RED_BOLD}${GIT_INFO}${RESET} | ${GREEN}${CONTEXT_INFO}${RESET} | ${YELLOW}${COST_INFO}${RESET}"
