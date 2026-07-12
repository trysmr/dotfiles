#!/bin/bash

# japanese_commit_check.py のテストスクリプト
# 入力形式の互換性（tool_input / toolInput / toolArgs）と定型違反の検出を検証する。

HOOK="$(cd "$(dirname "$0")" && pwd)/japanese_commit_check.py"
pass=0
fail=0

assert_rc() {
  local expected="$1"
  local input="$2"
  local desc="$3"
  printf '%s' "$input" | python3 "$HOOK" > /dev/null 2>&1
  local actual=$?
  if [ "$expected" = "$actual" ]; then
    printf '✓ %s\n' "$desc"
    (( pass++ ))
  else
    printf '✗ %s (expected rc: %s, actual rc: %s)\n' "$desc" "$expected" "$actual"
    (( fail++ ))
  fi
}

echo "=== 入力形式の互換性 ==="

assert_rc 2 '{"tool_input":{"command":"git commit -m \"Rails 8 対応を追加\""}}' \
  "tool_input形式で英日間の空白を検出"

assert_rc 2 '{"toolInput":{"command":"git commit -m \"Rails 8 対応を追加\""}}' \
  "toolInput形式で英日間の空白を検出"

assert_rc 2 '{"toolArgs":"{\"command\":\"git commit -m \\\"Rails 8 対応を追加\\\"\"}"}' \
  "toolArgs文字列形式で英日間の空白を検出"

echo ""
echo "=== 検出対象の違反 ==="

assert_rc 2 '{"tool_input":{"command":"git commit -m \"未pushの変更を退避\""}}' \
  "漢語接頭辞と英字の混成を検出"

assert_rc 2 '{"tool_input":{"command":"git commit -m \"未充足の条件を検証\""}}' \
  "造語ブロックリストの語を検出"

assert_rc 2 '{"tool_input":{"command":"gh pr create --title \"API 連携を追加\""}}' \
  "gh prコマンドも検査対象"

echo ""
echo "=== 検査対象外のスキップ ==="

assert_rc 0 '{"tool_input":{"command":"git commit -m \"N+1クエリをeager loadingで解消\""}}' \
  "違反のないコミットメッセージは通過"

assert_rc 0 '{"tool_input":{"command":"ls -la 日本語ファイル 名前.txt"}}' \
  "commit/PR以外のコマンドは対象外"

assert_rc 0 '{"tool_input":{"command":"git commit -m \"fix typo\""}}' \
  "日本語を含まないコマンドは対象外"

assert_rc 0 '{"tool_input":{}}' "commandがない入力は対象外"

assert_rc 0 'broken json' "壊れたJSON入力はスキップ"

echo ""
echo "=== 両ディレクトリの同一性 ==="

CODEX_HOOK="$(cd "$(dirname "$0")" && pwd)/../../.codex/hooks/japanese_commit_check.py"
if [ ! -f "$CODEX_HOOK" ]; then
  CODEX_HOOK="$HOME/.codex/hooks/japanese_commit_check.py"
fi
if [ -f "$CODEX_HOOK" ]; then
  if diff -q "$HOOK" "$CODEX_HOOK" > /dev/null 2>&1; then
    printf '✓ .claude版と.codex版が同一内容\n'
    (( pass++ ))
  else
    printf '✗ .claude版と.codex版が同一内容 (diffあり: %s)\n' "$CODEX_HOOK"
    (( fail++ ))
  fi
else
  printf '✓ .codex版が見つからないため同一性チェックをスキップ\n'
  (( pass++ ))
fi

echo ""
echo "=========================================="
printf '結果: %d passed, %d failed\n' "$pass" "$fail"
echo "=========================================="
[ "$fail" -gt 0 ] && exit 1
exit 0
