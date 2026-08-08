#!/bin/bash

# command_safety_check.shのテストスクリプト
# 絶対禁止と承認フローの迂回防止を検証する。

HOOK="$(cd "$(dirname "$0")" && pwd)/command_safety_check.sh"
pass=0
fail=0

# テンプレートを明示する。macOSのmktempはテンプレート未指定だとTMPDIRを無視してシステムの一時ディレクトリを使うため
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/command_safety_test.XXXXXX") || { echo "mktemp失敗: 一時ディレクトリを作成できません" >&2; exit 1; }
trap 'rm -rf "$TMPDIR_TEST"' EXIT
TEST_HOME="$TMPDIR_TEST/home"
mkdir -p "$TEST_HOME"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local desc="$3"
  if [ "$expected" = "$actual" ]; then
    printf '✓ %s\n' "$desc"
    (( pass++ ))
  else
    printf '✗ %s (expected: %s, actual: %s)\n' "$desc" "$expected" "$actual"
    (( fail++ ))
  fi
}

# 引数: $1=イベント名, $2=コマンド文字列
run_hook() {
  local event="$1" cmd="$2"
  jq -nc --arg evt "$event" --arg cmd "$cmd" '{hook_event_name: $evt, tool_input: {command: $cmd}}' | \
    HOME="$TEST_HOME" bash "$HOOK"
}

decision_of() {
  jq -r '.hookSpecificOutput.permissionDecision // ""'
}

echo "=== 固定チェック ==="

output=$(run_hook "PreToolUse" "ls -la")
assert_eq "" "$output" "安全なコマンドは出力なしで通過"

output=$(run_hook "PreToolUse" "sudo ls")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "sudoをdeny"

output=$(run_hook "PreToolUse" "cat .env")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" ".env読み取りをdeny"

output=$(run_hook "PreToolUse" "ls .git")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" ".git直接参照をdeny"

echo ""
echo "=== 絶対禁止 ==="

output=$(run_hook "PreToolUse" "terraform destroy")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "terraform destroyをdeny"

output=$(run_hook "PreToolUse" "git push origin main --force")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "引数途中のforce pushをdeny"

output=$(run_hook "PreToolUse" "rm target -r")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "引数途中の再帰削除をdeny"

output=$(run_hook "PreToolUse" "bundle exec rails db:drop")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "破壊的なRails DBタスクをdeny"

output=$(run_hook "PreToolUse" "bundle exec rake db:drop")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "破壊的なRake DBタスクをdeny"

output=$(run_hook "PreToolUse" "npm publish")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "パッケージ公開をdeny"

output=$(run_hook "PreToolUse" 'ls $(terraform destroy)')
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "埋め込みコマンド内の禁止操作をdeny"

echo ""
echo "=== 承認フローの迂回防止 ==="

output=$(run_hook "PreToolUse" "ls && git push origin main")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "チェーン内のaskコマンドをdeny（権限確認の迂回防止）"

output=$(run_hook "PreToolUse" "git push origin main")
assert_eq "" "$output" "単独のaskコマンドは通過（Codex側の承認フローに委ねる）"

output=$(run_hook "PreToolUse" 'gh pr create --base staging --title "title" --body "$(cat <<'"'"'EOF'"'"'
## 概要
本文
EOF
)"')
assert_eq "" "$output" "PR本文をヒアドキュメントで渡す単独gh pr createは通過"

output=$(run_hook "PreToolUse" 'gh pr create --base staging --title "title" --body "before | after"')
assert_eq "" "$output" "引用符内のパイプをコマンド列と誤判定しない"

output=$(run_hook "PreToolUse" $'ls\ngh pr create --base staging --title title --body body')
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "引用外改行後のgh pr createをdeny"

echo ""
echo "=== イベント別の出力形式 ==="

output=$(run_hook "PermissionRequest" "sudo ls")
behavior=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.decision.behavior // ""')
assert_eq "deny" "$behavior" "PermissionRequestではdecision.behavior形式でdeny"

echo ""
echo "=== 入力形式の互換性 ==="

output=$(jq -nc '{hook_event_name: "PreToolUse", toolArgs: "{\"command\":\"sudo ls\"}"}' | \
  HOME="$TEST_HOME" bash "$HOOK")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "toolArgs文字列形式の入力でもdeny"

echo ""
echo "=========================================="
printf '結果: %d passed, %d failed\n' "$pass" "$fail"
echo "=========================================="
[ "$fail" -gt 0 ] && exit 1
exit 0
