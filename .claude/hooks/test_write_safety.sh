#!/bin/bash

# write_safety_check.sh のテストスクリプト

HOOK="$(dirname "$0")/write_safety_check.sh"
pass=0
fail=0

test_hook() {
  local file_path="$1"
  local expected="$2"
  local desc="$3"
  local output
  output=$(jq -n --arg fp "$file_path" '{tool_input:{file_path:$fp}}' | bash "$HOOK" 2>/dev/null)
  local rc=$?
  local result
  if [ $rc -eq 0 ]; then
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
test_hook "src/main.rb" "pass" "通常のRubyファイル"
test_hook "config/database.yml" "pass" "YAML設定ファイル"
test_hook "app/models/user.rb" "pass" "モデルファイル"
test_hook "README.md" "pass" "READMEファイル"
test_hook "package.json" "pass" "package.json"

echo ""
echo "=== .envファイル ブロック ==="
test_hook ".env" "block" ".envファイル"
test_hook ".env.local" "block" ".env.localファイル"
test_hook ".env.production" "block" ".env.productionファイル"
test_hook "config/.env" "block" "サブディレクトリの.env"

echo ""
echo "=== 秘密鍵ファイル ブロック ==="
test_hook "server.pem" "block" "PEMファイル"
test_hook "private.key" "block" "KEYファイル"
test_hook "keystore.p12" "block" "P12ファイル"
test_hook "cert.pfx" "block" "PFXファイル"
test_hook "keystore.jks" "block" "JKSファイル"

echo ""
echo "=== SSH鍵ファイル ブロック ==="
test_hook "id_rsa" "block" "RSA鍵"
test_hook "id_ed25519" "block" "Ed25519鍵"
test_hook "id_ecdsa" "block" "ECDSA鍵"
test_hook "id_dsa" "block" "DSA鍵"
test_hook "id_rsa.pub" "block" "RSA公開鍵"

echo ""
echo "=== 認証情報ファイル ブロック ==="
test_hook "credentials" "block" "credentialsファイル"
test_hook "credentials.json" "block" "credentials.jsonファイル"
test_hook "gcp-credentials.json" "block" "GCP credentials.json"
test_hook "credentials.yml" "block" "credentials.ymlファイル"

echo ""
echo "=== 結果 ==="
total=$((pass + fail))
printf '合計: %d/%d (pass: %d, fail: %d)\n' "$pass" "$total" "$pass" "$fail"
[ $fail -eq 0 ] && printf '全テスト通過 ✓\n' || printf '失敗あり ✗\n'
exit $fail
