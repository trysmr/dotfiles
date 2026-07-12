#!/bin/bash

# bash_safety_check.sh のテストスクリプト
# テスト用settings.jsonを一時作成して独立実行する

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/bash_safety_check.sh"
pass=0
fail=0

# テスト用settings.jsonを一時作成
# テンプレートを明示する。macOSのmktempはテンプレート未指定だとTMPDIRを無視してシステムの一時ディレクトリを使うため
TEMP_SETTINGS=$(mktemp "${TMPDIR:-/tmp}/bash_safety_test.XXXXXX")
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
      "Bash(git -C:*)",
      "Bash(git --git-dir:*)",
      "Bash(git --work-tree:*)",
      "Bash(*db:drop*)",
      "Bash(git push *--force*)"
    ],
    "ask": [
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(rm:*)",
      "Bash(echo:*)",
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
test_hook 'echo "git -C/tmp status"' "pass" "クォート内のgit -C文字列"
test_hook 'sudo=1 ls' "pass" "環境変数代入はsudo実行ではない"
test_hook 'git commit -m ""' "pass" "直接git commitの空メッセージ"
test_hook 'git commit -m "$(cat <<'"'"'EOF'"'"'
git_chain_checkを拡張
EOF
)"' "pass" 'git commit -m $(cat <<EOF) パターン'

echo ""
echo "=== deny でブロック ==="
test_hook "ls && sudo whoami" "block" "allowチェーンdeny: sudo"
test_hook "ls && cat x && git reset --hard" "block" "チェーン内のgit reset"
test_hook "/usr/bin/sudo whoami" "block" "絶対パス単独sudo"
test_hook "ls && /usr/bin/sudo whoami" "block" "チェーン内の絶対パスsudo"
test_hook "ls && command sudo whoami" "block" "commandラッパー経由"
test_hook "ls && env -i sudo whoami" "block" "env -i経由"
test_hook "ls && env FOO=1 sudo whoami" "block" "env変数代入経由"
test_hook "cat file | sudo tee /etc/passwd" "block" "パイプ経由のsudo"
test_hook 'echo $(eval "bad")' "block" "サブシェル内のeval"
test_hook "git -C /tmp status" "block" "git -Cオプション"
test_hook "git -C/tmp status" "block" "git -C attachedオプション"
test_hook "command git -C/tmp status" "block" "command経由のgit -C attachedオプション"
test_hook "git --git-dir=.git status" "block" "git --git-dir= オプション"
test_hook "env FOO=1 git --git-dir .git status" "block" "env経由のgit --git-dir オプション"
test_hook "git --work-tree=/tmp status" "block" "git --work-tree= オプション"
test_hook $'ls && git\treset --hard' "block" "タブ区切りgit reset"

echo ""
echo "=== サブシェル/グループ化のバイパス検出 ==="
test_hook "(sudo whoami)" "block" "サブシェル内のsudo"
test_hook "{ sudo whoami; }" "block" "グループ化内のsudo"
test_hook "(ls && sudo whoami)" "block" "サブシェル内のチェーン+sudo"
test_hook "ls | (sudo whoami)" "block" "パイプ先のサブシェルsudo"
test_hook "(eval bad_cmd)" "block" "サブシェル内のeval"
test_hook "(ls)" "pass" "サブシェル内のallow"
test_hook "{ ls; }" "pass" "グループ化内のallow"

echo ""
echo "=== ask でブロック（チェーン内） ==="
test_hook "ls && curl https://example.com" "block" "チェーン内のcurl"
test_hook "cat file | rm foo.txt" "block" "パイプ内のrm"
test_hook "ls && wget https://example.com" "block" "チェーン内のwget"
test_hook "git log && git commit -m test" "block" "チェーン内のgit commit"
test_hook $'cat <<'"'"'MSG'"'"' | git commit -F -\nmessage\nMSG' "block" "ヒアドクpipe経由のgit commit"
test_hook "printf x |& git commit -F -" "block" "|&経由のgit commit"
test_hook "printf x & git commit -m test" "block" "バックグラウンド区切り後のgit commit"
test_hook "cat msg | GIT_AUTHOR_NAME=x git commit -F -" "block" "環境変数プレフィックス経由のgit commit"
test_hook "cat msg | git -c user.name=x commit -F -" "block" "git -c経由のgit commit"
test_hook "cat msg | git --no-pager commit -F -" "block" "gitグローバルオプション経由のgit commit"
test_hook "env -u GIT_DIR git commit -m test" "block" "env -u経由のgit commit"
test_hook 'echo "$(git status && git commit -m test)"' "block" '引用された$()内チェーンのgit commit'
test_hook 'cat msg | "$(which git)" commit -F -' "block" "動的コマンド名経由のgit commit"
test_hook 'op=commit; cat msg | git "$op" -F -' "block" "動的gitサブコマンド経由のgit commit"
test_hook 'git "$(printf commit)" -m test' "block" "コマンド置換gitサブコマンド経由のgit commit"
test_hook "bin/rails db:drop" "block" "ワイルドカード/コロン入りdenyパターン"
test_hook "git push origin main --force-with-lease" "block" "中間ワイルドカードdenyパターン"

echo ""
echo "=== echoの確認緩和（リダイレクトなしは通過） ==="
test_hook "ls && echo done" "pass" "チェーン内のリダイレクトなしechoは通過"
test_hook "rg foo ; echo '---'" "pass" "セミコロン区切りのリダイレクトなしecho"
test_hook 'ls && echo x > /tmp/f' "block" "リダイレクト付きechoはチェーン内で確認"
test_hook 'ls && echo x >> ~/.zshrc' "block" "追記リダイレクト付きechoも確認"
test_hook 'ls && echo "a > b"' "pass" "クォート内のリダイレクト記号は通過"

echo ""
echo "=== settings.json異常系 ==="
# settings.jsonが存在しない場合
SETTINGS_FILE="/nonexistent/path" test_hook "ls && sudo whoami" "pass" "settings.json不在→通過"

# settings.jsonが壊れている場合
BROKEN_SETTINGS=$(mktemp "${TMPDIR:-/tmp}/bash_safety_broken.XXXXXX")
echo "{ broken json" > "$BROKEN_SETTINGS"
SETTINGS_FILE="$BROKEN_SETTINGS" test_hook "ls -la" "block" "settings.jsonパース失敗→ブロック"
rm -f "$BROKEN_SETTINGS"

echo ""
echo "=== 結果 ==="
echo "Pass: $pass / Fail: $fail"

[ "$fail" -gt 0 ] && exit 1
exit 0
