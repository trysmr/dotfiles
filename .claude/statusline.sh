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
WHITE_BOLD='\033[1;37m'
LIGHT_BLUE='\033[94m'
RESET='\033[0m'

echo -e "[${BLUE_BOLD}${MODEL}${RESET}] ${CYAN}${DIR_NAME}${RESET} | ${RED_BOLD}${GIT_INFO}${RESET} | ${GREEN}${CONTEXT_INFO}${RESET} | ${YELLOW}${COST_INFO}${RESET}"
if [ -n "$SESSION_ID" ]; then
    echo -e "  Session: ${MAGENTA_BOLD}${SESSION_ID}${RESET}"
fi

# --- Usage情報（セッション・週間クォータ） ---

USAGE_CACHE="/tmp/claude-usage-cache.json"
USAGE_CACHE_TTL=360

# OAuthトークン取得
get_oauth_token() {
    security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
        | jq -r '.claudeAiOauth.accessToken' 2>/dev/null
}

# キャッシュの有効性チェック（有効なら0、無効なら1）
is_cache_valid() {
    [ -f "$USAGE_CACHE" ] || return 1
    local cached_at
    cached_at=$(jq -r '.cached_at // 0' "$USAGE_CACHE" 2>/dev/null)
    local now
    now=$(date +%s)
    [ $((now - cached_at)) -lt "$USAGE_CACHE_TTL" ]
}

# usage APIからデータ取得（キャッシュ付き）
fetch_usage() {
    if is_cache_valid; then
        cat "$USAGE_CACHE"
        return 0
    fi

    local token
    token=$(get_oauth_token)
    [ -n "$token" ] && [ "$token" != "null" ] || return 1

    local response
    response=$(curl -sf --max-time 5 \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
        # キャッシュに保存（cached_atを付与）
        echo "$response" | jq --arg ts "$(date +%s)" '. + {cached_at: ($ts | tonumber)}' > "$USAGE_CACHE" 2>/dev/null
        cat "$USAGE_CACHE"
        return 0
    fi

    # APIエラー時: 期限切れキャッシュがあれば使用
    if [ -f "$USAGE_CACHE" ]; then
        cat "$USAGE_CACHE"
        return 0
    fi
    return 1
}

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

# ISO 8601からUNIXタイムスタンプへ変換
iso_to_epoch() {
    local iso_time=$1
    # +00:00 や .xxx を除去してUTC時刻として解釈
    local cleaned
    cleaned=$(echo "$iso_time" | sed 's/\+.*//; s/\..*//')
    TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$cleaned" "+%s" 2>/dev/null
}

# リセット時刻フォーマット（ISO 8601 → Asia/Tokyo）
# セッション用: "9pm"
format_reset_time_short() {
    local iso_time=$1
    [ -n "$iso_time" ] && [ "$iso_time" != "null" ] || return 1
    local epoch
    epoch=$(iso_to_epoch "$iso_time")
    [ -n "$epoch" ] || return 1
    LC_ALL=C TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%-l%p" 2>/dev/null \
        | sed 's/AM/am/; s/PM/pm/'
}

# 週間用: "Mar 6 at 1pm"
format_reset_time_long() {
    local iso_time=$1
    [ -n "$iso_time" ] && [ "$iso_time" != "null" ] || return 1
    local epoch
    epoch=$(iso_to_epoch "$iso_time")
    [ -n "$epoch" ] || return 1
    LC_ALL=C TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%b %-d at %-l%p" 2>/dev/null \
        | sed 's/AM/am/; s/PM/pm/'
}

# Usage情報の表示
USAGE_DATA=$(fetch_usage 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$USAGE_DATA" ]; then
    FIVE_HOUR_UTIL=$(echo "$USAGE_DATA" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
    FIVE_HOUR_RESET=$(echo "$USAGE_DATA" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    SEVEN_DAY_UTIL=$(echo "$USAGE_DATA" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
    SEVEN_DAY_RESET=$(echo "$USAGE_DATA" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

    if [ -n "$FIVE_HOUR_UTIL" ]; then
        PCT_5H=$(printf "%.0f" "$FIVE_HOUR_UTIL")
        BAR_5H=$(make_progress_bar "$PCT_5H")
        COLOR_5H=$(usage_color "$PCT_5H")
        RESET_5H=$(format_reset_time_short "$FIVE_HOUR_RESET")
        RESET_5H_DISPLAY=""
        if [ -n "$RESET_5H" ]; then
            RESET_5H_DISPLAY="Resets ${RESET_5H} (Asia/Tokyo)"
        fi
        echo -e "  ${WHITE_BOLD}5h${RESET}  ${COLOR_5H}${BAR_5H}  ${PCT_5H}%${RESET}  ${RESET_5H_DISPLAY}"
    fi

    if [ -n "$SEVEN_DAY_UTIL" ]; then
        PCT_7D=$(printf "%.0f" "$SEVEN_DAY_UTIL")
        BAR_7D=$(make_progress_bar "$PCT_7D")
        COLOR_7D=$(usage_color "$PCT_7D")
        RESET_7D=$(format_reset_time_long "$SEVEN_DAY_RESET")
        RESET_7D_DISPLAY=""
        if [ -n "$RESET_7D" ]; then
            RESET_7D_DISPLAY="Resets ${RESET_7D} (Asia/Tokyo)"
        fi
        echo -e "  ${LIGHT_BLUE}7d${RESET}  ${COLOR_7D}${BAR_7D}  ${PCT_7D}%${RESET}  ${RESET_7D_DISPLAY}"
    fi
fi
