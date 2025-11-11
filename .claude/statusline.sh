#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
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

    CHANGES=""
    [ "$STAGED" -gt 0 ] && CHANGES="${CHANGES}+${STAGED}"
    [ "$UNSTAGED" -gt 0 ] && CHANGES="${CHANGES} ~${UNSTAGED}"
    [ "$UNTRACKED" -gt 0 ] && CHANGES="${CHANGES} ?${UNTRACKED}"

    # 前回のコミット時刻
    LAST_COMMIT=""
    if git log -1 --format=%cr > /dev/null 2>&1; then
        LAST_COMMIT_TIME=$(git log -1 --format=%cr 2>/dev/null)
        LAST_COMMIT=" | ⏰ ${LAST_COMMIT_TIME}"
    fi

    if [ -n "$CHANGES" ]; then
        GIT_INFO=" | 🌿 ${BRANCH} (${CHANGES})"
    else
        GIT_INFO=" | 🌿 ${BRANCH}"
    fi
    GIT_INFO="${GIT_INFO}${LAST_COMMIT}"
fi

# Docker/環境情報
ENV_INFO=""
if [ -f "docker-compose.yml" ] || [ -f "compose.yml" ]; then
    # Dockerコンテナの状態をチェック
    if command -v docker > /dev/null 2>&1; then
        RUNNING=$(docker compose ps --quiet 2>/dev/null | wc -l | xargs)
        if [ "$RUNNING" -gt 0 ] 2>/dev/null; then
            ENV_INFO=" | 🐳 running"
        else
            ENV_INFO=" | 🐳 stopped"
        fi
    else
        ENV_INFO=" | 🐳"
    fi
elif [ -f "Gemfile" ]; then
    # Railsプロジェクト
    if grep -q "rails" Gemfile 2>/dev/null; then
        ENV_INFO=" | 💎 rails"
    else
        ENV_INFO=" | 💎 ruby"
    fi
elif [ -f "package.json" ]; then
    # Node.jsプロジェクト
    ENV_INFO=" | 📦 node"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    # Pythonプロジェクト
    ENV_INFO=" | 🐍 python"
fi

echo "[$MODEL] 📁 ${DIR_NAME}${GIT_INFO}${ENV_INFO}"
