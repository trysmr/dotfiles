#!/bin/bash

# japanese_write_check.pyの回帰テスト
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/japanese_write_check.py"
# テンプレートを明示する。macOSのmktempはテンプレート未指定だとTMPDIRを無視してシステムの一時ディレクトリを使うため
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/japanese_write_test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

pass=0
fail=0

check() {
  local description="$1"
  local actual="$2"
  local expected="$3"

  if [ "$actual" = "$expected" ]; then
    printf '✓ %s\n' "$description"
    pass=$((pass + 1))
  else
    printf '✗ %s\n' "$description"
    fail=$((fail + 1))
  fi
}

run_hook() {
  local content="$1"
  local file_name="${2:-fixture.rb}"
  local patch_path="${3:-$file_name}"
  local event_id="${4:-}"
  local patch
  local input

  mkdir -p "$TEST_DIR/$(dirname "$file_name")"
  printf '%s\n' "$content" > "$TEST_DIR/$file_name"
  patch=$(printf '%s\n' '*** Begin Patch' "*** Update File: $patch_path" '*** End Patch')
  if [ -n "$event_id" ]; then
    input=$(jq -n --arg cwd "$TEST_DIR" --arg command "$patch" --arg id "$event_id" '{cwd: $cwd, session_id: "test-session", turn_id: $id, tool_use_id: $id, tool_name: "apply_patch", tool_input: {command: $command}}')
  else
    input=$(jq -n --arg cwd "$TEST_DIR" --arg command "$patch" '{cwd: $cwd, tool_name: "apply_patch", tool_input: {command: $command}}')
  fi
  (
    cd "$TEST_DIR"
    printf '%s' "$input" | python3 "$HOOK"
  )
}

echo '=== 自然な日本語 ==='
output=$(run_hook $'# 非同期処理を開始する\nraise "保存に失敗しました"' 'fixture.rb' "$TEST_DIR/fixture.rb")
check '自然なコメントとエラーメッセージは指摘しない' "$output" ''

echo ''
echo '=== 不自然な日本語 ==='
output=$(run_hook $'# 未充足の設定を確認する\nraise "次エッジを選択してください"' 'fixture.rb' "$TEST_DIR/fixture.rb")
check '検出結果はJSONで返す' "$(printf '%s' "$output" | jq -r 'has("hookSpecificOutput")')" 'true'
context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
check '漢語接頭辞の造語を示す' "$(printf '%s' "$context" | grep -c '未充足')" '1'
check '漢語接頭辞の言い換え案を示す' "$(printf '%s' "$context" | grep -c '満たしていない')" '1'
check '助詞省略を示す' "$(printf '%s' "$context" | grep -c '次エッジ')" '1'
check '助詞省略の言い換え案を示す' "$(printf '%s' "$context" | grep -c '次のエッジ')" '1'
check 'ファイルと行番号を示す' "$(printf '%s' "$context" | grep -c 'fixture.rb:')" '2'

echo ''
echo '=== 日本語なし ==='
output=$(run_hook $'# Validate configuration\nraise "Invalid input"')
check '日本語を含まないファイルは成功扱い' "$output" ''

echo ''
echo '=== プロジェクト用語 ==='
output=$(run_hook $'# Herdrセッションを開始する\nlabel = "Codex設定"')
check '確立済みのプロジェクト用語は指摘しない' "$output" ''

mkdir -p "$TEST_DIR/.codex"
printf '%s\n' '未充足' > "$TEST_DIR/.codex/japanese_domain_terms.txt"
output=$(run_hook '未充足の状態を表示する')
check '登録済みのドメイン用語は指摘しない' "$output" ''

echo ''
echo '=== 機密パス ==='
output=$(run_hook '未充足の設定' '.env')
check '.envは読み取らず成功扱い' "$output" ''

echo ''
echo '=== 重複起動 ==='
event_id="$TEST_DIR-duplicate"
output=$(run_hook '次エッジを選択してください' 'fixture.rb' 'fixture.rb' "$event_id")
check '同一tool callの最初の実行は報告する' "$(printf '%s' "$output" | jq -r 'has("hookSpecificOutput")')" 'true'
output=$(run_hook '次エッジを選択してください' 'fixture.rb' 'fixture.rb' "$event_id")
check '同一tool callの重複実行は報告しない' "$output" ''

echo ''
printf '結果: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
