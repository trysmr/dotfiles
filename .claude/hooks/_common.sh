#!/bin/bash

# hooks共通ヘルパー関数
# 使用法: source ~/.claude/hooks/_common.sh

# stdinから読み取ったJSON入力のtool_inputフィールドを抽出
# Claude Code / Copilot両方のフィールド形式に対応
# 使用法: value=$(printf '%s' "$input" | extract_field "command")
extract_field() {
  local field="$1"
  jq -r "
    (.toolArgs? | fromjson? | .${field}?)
    // .toolInput.${field}?
    // .tool_input.${field}?
    // \"\"
  "
}

# Copilot互換のdeny関数
# 使用法: deny_action "メッセージ" "$is_copilot"
deny_action() {
  local message="$1"
  local is_copilot="$2"

  if [ "$is_copilot" = "true" ]; then
    jq -nc --arg msg "$message" \
      '{"permissionDecision":"deny","permissionDecisionReason":$msg}'
    exit 0
  fi

  printf '%s\n' "$message" >&2
  exit 2
}

# Copilot判定（toolNameフィールドの有無）
# 使用法: is_copilot=$(printf '%s' "$input" | detect_copilot)
detect_copilot() {
  jq -r 'has("toolName")'
}

# YAML frontmatterから指定キーの値を抽出（jq非依存）
# 使用法: value=$(parse_frontmatter "file.md" "type")
parse_frontmatter() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    /^---$/ { block++; next }
    block == 1 && $0 ~ "^" k " *:" {
      sub("^" k " *: *", "")
      print
      exit
    }
    block >= 2 { exit }
  ' "$file"
}

# YAML frontmatterを除去し本文のみ出力
# frontmatterがないファイルはそのまま全文出力
# 使用法: body=$(strip_frontmatter "file.md")
strip_frontmatter() {
  local file="$1"
  awk '
    NR == 1 && /^---$/ { in_fm = 1; next }
    in_fm && /^---$/ { in_fm = 0; next }
    !in_fm { print }
  ' "$file"
}
