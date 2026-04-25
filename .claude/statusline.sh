#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name' 2>/dev/null)
SESSION_ID=$(echo "$input" | jq -r '.session_id' 2>/dev/null)
if [ "$SESSION_ID" = "null" ] || [ -z "$SESSION_ID" ]; then
    SESSION_ID=""
fi
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir' 2>/dev/null)
DIR_NAME=""
if [ -n "$CURRENT_DIR" ] && [ "$CURRENT_DIR" != "null" ]; then
    DIR_NAME=$(basename "$CURRENT_DIR" 2>/dev/null)
fi

# Git情報
GIT_INFO=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)

    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | xargs)
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | xargs)
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | xargs)

    CHANGES="+${STAGED},~${UNSTAGED},?${UNTRACKED}"

    if [ -n "$CHANGES" ]; then
        GIT_INFO="${BRANCH} (${CHANGES})"
    else
        GIT_INFO="${BRANCH}"
    fi
fi

# コンテキスト使用率（built-in）
CONTEXT_INFO=""
CONTEXT_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
if [ -n "$CONTEXT_PCT" ]; then
    CONTEXT_INFO="${CONTEXT_PCT}%"
fi

# コスト
COST_INFO=""
TOTAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd' 2>/dev/null)
if [ -n "$TOTAL_COST" ] && [ "$TOTAL_COST" != "null" ]; then
    COST_INFO="\$$(printf "%.4f" "$TOTAL_COST")"
fi

# 色定義
RED_BOLD='\033[1;31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE_BOLD='\033[1;34m'
MAGENTA_BOLD='\033[1;35m'
CYAN='\033[1;36m'
WHITE_BOLD='\033[1;37m'
LIGHT_BLUE='\033[94m'
RESET='\033[0m'

echo -e "[${BLUE_BOLD}${MODEL}${RESET}] ${CYAN}${DIR_NAME}${RESET} | ${RED_BOLD}${GIT_INFO}${RESET} | ${GREEN}${CONTEXT_INFO}${RESET} | ${YELLOW}${COST_INFO}${RESET}"
if [ -n "$SESSION_ID" ]; then
    echo -e "  Session: ${MAGENTA_BOLD}${SESSION_ID}${RESET}"
fi

# --- Usage情報（built-in rate_limits から取得） ---

# プログレスバー生成（引数: 使用率0-100）
make_progress_bar() {
    local pct=$1
    local filled=$((pct / 10))
    local empty=$((10 - filled))
    local bar=""
    for ((i = 0; i < filled; i++)); do bar+="●"; done
    for ((i = 0; i < empty; i++)); do bar+="○"; done
    echo "$bar"
}

# 使用率に応じた色（0-49:緑, 50-79:黄, 80-100:赤）
usage_color() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        echo "$RED_BOLD"
    elif [ "$pct" -ge 50 ]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# リセット時刻フォーマット（Unix epoch -> Asia/Tokyo）
format_reset_long() {
    local epoch=$1
    [ -n "$epoch" ] && [ "$epoch" != "null" ] || return 1
    TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%-m/%-d %H:%M" 2>/dev/null
}

# 5時間クォータ
PCT_5H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
RESET_5H_EPOCH=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)

if [ -n "$PCT_5H" ]; then
    PCT_5H_INT=$(printf "%.0f" "$PCT_5H")
    BAR_5H=$(make_progress_bar "$PCT_5H_INT")
    COLOR_5H=$(usage_color "$PCT_5H_INT")
    RESET_5H=$(format_reset_long "$RESET_5H_EPOCH")
    RESET_5H_DISPLAY=""
    if [ -n "$RESET_5H" ]; then
        RESET_5H_DISPLAY="Resets ${RESET_5H} (Asia/Tokyo)"
    fi
    PCT_5H_FMT=$(printf "%3d" "$PCT_5H_INT")
    echo -e "  ${WHITE_BOLD}5h${RESET}  ${COLOR_5H}${BAR_5H} ${PCT_5H_FMT}%${RESET}  ${RESET_5H_DISPLAY}"
fi

# 7日間クォータ
PCT_7D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
RESET_7D_EPOCH=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

if [ -n "$PCT_7D" ]; then
    PCT_7D_INT=$(printf "%.0f" "$PCT_7D")
    BAR_7D=$(make_progress_bar "$PCT_7D_INT")
    COLOR_7D=$(usage_color "$PCT_7D_INT")
    RESET_7D=$(format_reset_long "$RESET_7D_EPOCH")
    RESET_7D_DISPLAY=""
    if [ -n "$RESET_7D" ]; then
        RESET_7D_DISPLAY="Resets ${RESET_7D} (Asia/Tokyo)"
    fi
    PCT_7D_FMT=$(printf "%3d" "$PCT_7D_INT")
    echo -e "  ${LIGHT_BLUE}7d${RESET}  ${COLOR_7D}${BAR_7D} ${PCT_7D_FMT}%${RESET}  ${RESET_7D_DISPLAY}"
fi
