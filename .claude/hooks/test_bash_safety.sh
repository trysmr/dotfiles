#!/bin/bash

# bash_safety_check.sh のテストスクリプト
# テスト用settings.jsonを一時作成して独立実行する

HOOK="$HOME/.claude/hooks/bash_safety_check.sh"
pass=0
fail=0

# テスト用settings.jsonを一時作成
TEMP_SETTINGS=$(mktemp)
trap 'rm -f "$TEMP_SETTINGS"' EXIT

cat > "$TEMP_SETTINGS" <<'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(git log:*)",
      "Bash(git add:*)",
      "Bash(git status:*)",
      "Bash(head:*)",
      "Bash(rg:*)"
    ],
    "deny": [
      "Bash(sudo:*)",
      "Bash(eval:*)",
      "Bash(git reset:*)",
      "Bash(git -C:*)"
    ],
    "ask": [
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(rm:*)",
      "Bash(git commit:*)"
    ]
  }
}
SETTINGS

export SETTINGS_FILE="$TEMP_SETTINGS"

test_hook() {
  local cmd="$1"
  local expected="$2"
  local desc="$3"
  local output
  output=$(jq -n --arg command "$cmd" '{tool_input:{command:$command}}' | bash "$HOOK" 2>/dev/null)
  local rc=$?
  local result
  if [ $rc -eq 0 ] && ! printf '%s' "$output" | grep -q '"permissionDecision":"deny"'; then
    result="pass"
  else
    result="block"
  fi
  if [ "$result" = "$expected" ]; then
    printf '✓ [%s] %s\n' "$expected" "$desc"
    (( pass++ ))
  else
    printf '✗ [%s→%s] %s\n' "$expected" "$result" "$desc"
    (( fail++ ))
  fi
}

echo "=== 通過すべきケース ==="
test_hook "ls -la" "pass" "単純なlsコマンド"
test_hook "ls && cat file.txt" "pass" "allow同士のチェーン"
test_hook 'echo "hello && world"' "pass" "クォート内の&&"
test_hook "git log --oneline | head -5" "pass" "allowのgit log | head"
test_hook "ls 2>&1" "pass" "リダイレクトの&"
test_hook "" "pass" "空コマンド"
test_hook 'git commit -m "$(cat <<'"'"'EOF'"'"'
git_chain_checkを拡張
EOF
)"' "pass" 'git commit -m $(cat <<EOF) パターン'

echo ""
echo "=== deny でブロック ==="
test_hook "ls && sudo whoami" "block" "allowチェーンdeny: sudo"
test_hook "ls && cat x && git reset --hard" "block" "チェーン内のgit reset"
test_hook "/usr/bin/sudo whoami" "pass" "絶対パス単独(permissions判定に委ねる)"
test_hook "ls && /usr/bin/sudo whoami" "block" "チェーン内の絶対パスsudo"
test_hook "ls && command sudo whoami" "block" "commandラッパー経由"
test_hook "ls && env -i sudo whoami" "block" "env -i経由"
test_hook "ls && env FOO=1 sudo whoami" "block" "env変数代入経由"
test_hook "cat file | sudo tee /etc/passwd" "block" "パイプ経由のsudo"
test_hook 'echo $(eval "bad")' "block" "サブシェル内のeval"
test_hook "git -C /tmp status" "block" "git -Cオプション"
test_hook $'ls && git\treset --hard' "block" "タブ区切りgit reset"

echo ""
echo "=== ask でブロック（チェーン内） ==="
test_hook "ls && curl https://example.com" "block" "チェーン内のcurl"
test_hook "cat file | rm foo.txt" "block" "パイプ内のrm"
test_hook "ls && wget https://example.com" "block" "チェーン内のwget"
test_hook "git log && git commit -m test" "block" "チェーン内のgit commit"

echo ""
echo "=== settings.json異常系 ==="
# settings.jsonが存在しない場合
SETTINGS_FILE="/nonexistent/path" test_hook "ls && sudo whoami" "pass" "settings.json不在→通過"

# settings.jsonが壊れている場合
BROKEN_SETTINGS=$(mktemp)
echo "{ broken json" > "$BROKEN_SETTINGS"
SETTINGS_FILE="$BROKEN_SETTINGS" test_hook "ls -la" "block" "settings.jsonパース失敗→ブロック"
rm -f "$BROKEN_SETTINGS"

echo ""
echo "=== 結果 ==="
echo "Pass: $pass / Fail: $fail"

[ "$fail" -gt 0 ] && exit 1
exit 0
