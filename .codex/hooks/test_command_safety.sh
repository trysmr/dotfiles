#!/bin/bash

# command_safety_check.sh のテストスクリプト
# 固定チェック（.git/.env/sudo等）と、bash_safety_check.shエンジンへの
# settings.jsonポリシー委譲の両方を検証する。

HOOK="$(cd "$(dirname "$0")" && pwd)/command_safety_check.sh"
ENGINE="$(cd "$(dirname "$0")" && pwd)/../../.claude/hooks/bash_safety_check.sh"
pass=0
fail=0

# テンプレートを明示する。macOSのmktempはテンプレート未指定だとTMPDIRを無視してシステムの一時ディレクトリを使うため
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/command_safety_test.XXXXXX") || { echo "mktemp失敗: 一時ディレクトリを作成できません" >&2; exit 1; }
trap 'rm -rf "$TMPDIR_TEST"' EXIT

if [ ! -f "$ENGINE" ]; then
  ENGINE="$HOME/.claude/hooks/bash_safety_check.sh"
fi
if [ ! -f "$ENGINE" ]; then
  echo "bash_safety_check.shが見つかりません: $ENGINE" >&2
  exit 1
fi

# テスト用のポリシー定義（実運用のsettings.jsonには依存しない）
FIXTURE_SETTINGS="$TMPDIR_TEST/settings.json"
cat > "$FIXTURE_SETTINGS" <<'EOF'
{
  "permissions": {
    "deny": [
      "Bash(*terraform destroy*)"
    ],
    "ask": [
      "Bash(rm:*)"
    ]
  }
}
EOF

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
    SETTINGS_FILE="$FIXTURE_SETTINGS" COMMAND_SAFETY_ENGINE="$ENGINE" bash "$HOOK"
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
echo "=== settings.jsonポリシー委譲 ==="

output=$(run_hook "PreToolUse" "terraform destroy")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "settings.jsonのdenyパターンをdeny"
printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "禁止コマンド"
assert_eq "0" "$?" "denyの理由にエンジンのメッセージが入る"

output=$(run_hook "PreToolUse" "ls && rm foo.txt")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "チェーン内のaskコマンドをdeny（権限確認の迂回防止）"

output=$(run_hook "PreToolUse" "rm foo.txt")
assert_eq "" "$output" "単独のaskコマンドは通過（Codex側の承認フローに委ねる）"

output=$(run_hook "PreToolUse" 'ls $(terraform destroy)')
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "埋め込みコマンド内のdenyパターンをdeny"

echo ""
echo "=== イベント別の出力形式 ==="

output=$(run_hook "PermissionRequest" "sudo ls")
behavior=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.decision.behavior // ""')
assert_eq "deny" "$behavior" "PermissionRequestではdecision.behavior形式でdeny"

echo ""
echo "=== 入力形式の互換性 ==="

output=$(jq -nc '{hook_event_name: "PreToolUse", toolArgs: "{\"command\":\"sudo ls\"}"}' | \
  SETTINGS_FILE="$FIXTURE_SETTINGS" COMMAND_SAFETY_ENGINE="$ENGINE" bash "$HOOK")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "toolArgs文字列形式の入力でもdeny"

echo ""
echo "=== エンジン不在時のフォールバック ==="

output=$(jq -nc '{hook_event_name: "PreToolUse", tool_input: {command: "sudo ls"}}' | \
  SETTINGS_FILE="$FIXTURE_SETTINGS" COMMAND_SAFETY_ENGINE="$TMPDIR_TEST/nonexistent.sh" bash "$HOOK")
assert_eq "deny" "$(printf '%s' "$output" | decision_of)" "エンジン不在でも固定チェックは機能する"

output=$(jq -nc '{hook_event_name: "PreToolUse", tool_input: {command: "terraform destroy"}}' | \
  SETTINGS_FILE="$FIXTURE_SETTINGS" COMMAND_SAFETY_ENGINE="$TMPDIR_TEST/nonexistent.sh" bash "$HOOK")
assert_eq "" "$output" "エンジン不在時はsettings.jsonポリシーが効かない（フォールバック仕様の明文化）"

echo ""
echo "=========================================="
printf '結果: %d passed, %d failed\n' "$pass" "$fail"
echo "=========================================="
[ "$fail" -gt 0 ] && exit 1
exit 0
