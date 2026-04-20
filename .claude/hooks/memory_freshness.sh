#!/bin/bash
# メモリファイル鮮度管理
# 使用法: bash memory_freshness.sh
#
# メモリファイルの一覧・鮮度チェック・MEMORY.md整合性検証を行う。
# 環境変数 MEMORY_DIR でメモリディレクトリを指定可能。

set -uo pipefail

# --- 共通関数の読み込み ---
source "$(dirname "$0")/_common.sh"

# --- デフォルトのメモリディレクトリ ---
# PWDベースのプロジェクトディレクトリを動的に解決
if [ -z "${MEMORY_DIR:-}" ]; then
  project_key=$(echo "${PWD}" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${project_key}/memory"
fi

# --- type別鮮度閾値（日数） ---
get_threshold() {
  case "$1" in
    project)   echo 30 ;;
    reference) echo 60 ;;
    feedback)  echo 90 ;;
    user)      echo 90 ;;
    *)         echo 60 ;;
  esac
}

# --- ファイル更新日からの経過日数（macOS/Linux両対応） ---
calc_age_days() {
  local file="$1"
  local now mtime
  now=$(date +%s)
  if [[ "$(uname)" == "Darwin" ]]; then
    mtime=$(stat -f '%m' "$file")
  else
    mtime=$(stat -c '%Y' "$file")
  fi
  echo $(( (now - mtime) / 86400 ))
}

# --- メモリディレクトリ存在確認 ---
if [ ! -d "$MEMORY_DIR" ]; then
  printf '✗ メモリディレクトリが見つかりません: %s\n' "$MEMORY_DIR" >&2
  exit 1
fi

warn=0
file_count=0
stale_entries=()

printf '========================================\n'
printf 'メモリファイル鮮度チェック\n'
printf '========================================\n'
printf 'ディレクトリ: %s\n' "$MEMORY_DIR"

# --- ファイル一覧 + 鮮度判定 ---
printf '\n--- ファイル一覧 ---\n'

has_files=false
for f in "$MEMORY_DIR"/*.md; do
  [ ! -f "$f" ] && continue
  basename_f=$(basename "$f")
  [ "$basename_f" = "MEMORY.md" ] && continue
  has_files=true
  (( file_count++ ))

  type=$(parse_frontmatter "$f" "type")
  name=$(parse_frontmatter "$f" "name")
  age=$(calc_age_days "$f")
  threshold=$(get_threshold "$type")

  if [ "$age" -gt "$threshold" ]; then
    symbol="⚠"
    stale_entries+=("${basename_f}:${age}:${threshold}")
  else
    symbol="✓"
  fi
  printf '  %-10s %3d日  %s  %s\n' "${type:-unknown}" "$age" "$symbol" "${name:-$basename_f}"
done

if [ "$has_files" = false ]; then
  printf '  (メモリファイルなし)\n'
fi

# --- 鮮度警告 ---
printf '\n--- 鮮度警告 ---\n'
if [ ${#stale_entries[@]} -eq 0 ]; then
  printf '  (なし)\n'
else
  for entry in "${stale_entries[@]}"; do
    file="${entry%%:*}"
    rest="${entry#*:}"
    age="${rest%%:*}"
    threshold="${rest##*:}"
    printf '  ⚠ %s (%d日経過, 閾値: %d日)\n' "$file" "$age" "$threshold"
    printf '    → レビューを推奨\n'
    (( warn++ ))
  done
fi

# --- MEMORY.md 整合性チェック ---
printf '\n--- MEMORY.md 整合性 ---\n'

memory_index="$MEMORY_DIR/MEMORY.md"
if [ ! -f "$memory_index" ]; then
  printf '  ⚠ MEMORY.md が見つかりません\n'
  (( warn++ ))
else
  # インデックスにあるがファイルがないケース
  while IFS= read -r linked_file; do
    [ -z "$linked_file" ] && continue
    if [ ! -f "$MEMORY_DIR/$linked_file" ]; then
      printf '  ✗ インデックスにあるがファイルなし: %s\n' "$linked_file"
      (( warn++ ))
    fi
  done < <(grep -oE '\([^)]+\.md\)' "$memory_index" | tr -d '()')

  # ファイルがあるがインデックスにないケース
  for f in "$MEMORY_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    basename_f=$(basename "$f")
    [ "$basename_f" = "MEMORY.md" ] && continue
    if ! grep -q "$basename_f" "$memory_index"; then
      printf '  ✗ ファイルがあるがインデックスにない: %s\n' "$basename_f"
      (( warn++ ))
    fi
  done

  if [ "$warn" -eq 0 ]; then
    printf '  ✓ インデックスとファイルが一致\n'
  fi
fi

# --- サマリー ---
printf '\n========================================\n'
printf 'サマリー: %dファイル, %d件の警告\n' "$file_count" "$warn"
printf '========================================\n'

exit 0
