#!/bin/bash

# load_memory.sh のテストスクリプト

HOOK="$(dirname "$0")/load_memory.sh"
pass=0
fail=0

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

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

# --- テスト用メモリファイルの作成 ---
create_memory_file() {
  local dir="$1" name="$2" type="$3" body="$4"
  cat > "$dir/$name" <<MEMEOF
---
name: test-${name%.md}
description: test description
type: $type
---

$body
MEMEOF
}

echo "=== 正常系: frontmatter付きファイル ==="

TEST_DIR="$TMPDIR_TEST/normal"
mkdir -p "$TEST_DIR"
create_memory_file "$TEST_DIR" "feedback_test.md" "feedback" "テスト用フィードバック内容"
create_memory_file "$TEST_DIR" "user_test.md" "user" "テスト用ユーザー情報"

output=$(MEMORY_DIR="$TEST_DIR" bash "$HOOK")
rc=$?
assert_eq "0" "$rc" "正常終了"

# JSON妥当性
echo "$output" | jq . > /dev/null 2>&1
assert_eq "0" "$?" "JSON出力が妥当"

# body内容が含まれる
echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "テスト用フィードバック内容"
assert_eq "0" "$?" "フィードバック内容が含まれる"

echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "テスト用ユーザー情報"
assert_eq "0" "$?" "ユーザー情報が含まれる"

# type/nameヘッダーが含まれる
echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "### feedback: test-feedback_test"
assert_eq "0" "$?" "feedbackヘッダーが含まれる"

echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "### user: test-user_test"
assert_eq "0" "$?" "userヘッダーが含まれる"

# systemMessage
echo "$output" | jq -r '.systemMessage' | grep -q "load_memory"
assert_eq "0" "$?" "systemMessageにload_memoryが含まれる"

echo ""
echo "=== frontmatter除去 ==="

ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
echo "$ctx" | grep -q "^---$"
assert_eq "1" "$?" "frontmatterの---行が出力に含まれない"

echo "$ctx" | grep -q "^type:"
assert_eq "1" "$?" "type:行が出力に含まれない"

echo "$ctx" | grep -q "^description:"
assert_eq "1" "$?" "description:行が出力に含まれない"

echo ""
echo "=== MEMORY.md除外 ==="

TEST_DIR2="$TMPDIR_TEST/memindex"
mkdir -p "$TEST_DIR2"
create_memory_file "$TEST_DIR2" "user_test.md" "user" "通常ファイル"
cat > "$TEST_DIR2/MEMORY.md" <<'EOF'
# Memory Index
- [test](user_test.md)
EOF

output2=$(MEMORY_DIR="$TEST_DIR2" bash "$HOOK")
ctx2=$(echo "$output2" | jq -r '.hookSpecificOutput.additionalContext')
echo "$ctx2" | grep -q "Memory Index"
assert_eq "1" "$?" "MEMORY.mdの内容が出力に含まれない"

echo "$ctx2" | grep -q "通常ファイル"
assert_eq "0" "$?" "通常メモリファイルは含まれる"

echo ""
echo "=== 空ディレクトリ ==="

TEST_DIR3="$TMPDIR_TEST/empty"
mkdir -p "$TEST_DIR3"
output3=$(MEMORY_DIR="$TEST_DIR3" bash "$HOOK")
rc3=$?
assert_eq "0" "$rc3" "空ディレクトリでexit 0"
assert_eq "" "$output3" "空ディレクトリで出力なし"

echo ""
echo "=== ディレクトリ不存在 ==="

output4=$(MEMORY_DIR="$TMPDIR_TEST/nonexistent" bash "$HOOK")
rc4=$?
assert_eq "0" "$rc4" "不存在ディレクトリでexit 0"
assert_eq "" "$output4" "不存在ディレクトリで出力なし"

echo ""
echo "=== 大ファイル（制限なし・全文出力） ==="

TEST_DIR5="$TMPDIR_TEST/large"
mkdir -p "$TEST_DIR5"
large_body=$(python3 -c "print('X' * 5000)")
create_memory_file "$TEST_DIR5" "large_test.md" "reference" "$large_body"

output5=$(MEMORY_DIR="$TEST_DIR5" bash "$HOOK")
ctx5=$(echo "$output5" | jq -r '.hookSpecificOutput.additionalContext')
body_len=$(echo "$ctx5" | grep -o 'X' | wc -l | tr -d ' ')
assert_eq "5000" "$body_len" "大ファイルが切り詰められず全文出力される"

echo ""
echo "=== MEMORY.mdのみのディレクトリ ==="

TEST_DIR6="$TMPDIR_TEST/indexonly"
mkdir -p "$TEST_DIR6"
cat > "$TEST_DIR6/MEMORY.md" <<'EOF'
# Index
EOF

output6=$(MEMORY_DIR="$TEST_DIR6" bash "$HOOK")
assert_eq "" "$output6" "MEMORY.mdのみで出力なし"

echo ""
echo "=========================================="
printf '結果: %d passed, %d failed\n' "$pass" "$fail"
echo "=========================================="
[ "$fail" -gt 0 ] && exit 1
exit 0
