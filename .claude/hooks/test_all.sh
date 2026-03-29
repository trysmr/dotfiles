#!/bin/bash
# 統合テストランナー
# 使用法: bash test_all.sh
#
# 既存の個別テスト（bash_safety / write_safety / settings_integrity）を
# 順次実行し、統合サマリーを表示する。
# テスト追加は tests 配列に "名前:スクリプト" を1行追加するだけ。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 前提条件チェック ---
if ! command -v jq &>/dev/null; then
  printf '✗ jq が見つかりません。brew install jq でインストールしてください。\n' >&2
  exit 1
fi

# --- テスト定義 (名前:スクリプト) ---
tests=(
  "bash_safety:test_bash_safety.sh"
  "write_safety:test_write_safety.sh"
  "settings_integrity:test_settings_integrity.sh"
)

total=0
failed=0
results=()

printf '========================================\n'
printf '統合テスト実行\n'
printf '========================================\n'

for entry in "${tests[@]}"; do
  name="${entry%%:*}"
  script="${entry##*:}"

  printf '\n--- %s ---\n' "$name"

  if [ ! -f "$SCRIPT_DIR/$script" ]; then
    printf '✗ スクリプトが見つかりません: %s\n' "$SCRIPT_DIR/$script" >&2
    results+=("$name:FAIL")
    (( total++ ))
    (( failed++ ))
    continue
  fi

  rc=0
  bash "$SCRIPT_DIR/$script" || rc=$?

  (( total++ ))
  if [ $rc -eq 0 ]; then
    results+=("$name:PASS")
  else
    results+=("$name:FAIL")
    (( failed++ ))
  fi
done

printf '\n========================================\n'
printf '統合サマリー\n'
printf '========================================\n'

for r in "${results[@]}"; do
  name="${r%%:*}"
  status="${r##*:}"
  if [ "$status" = "PASS" ]; then
    printf '  %-22s ✓ PASS\n' "$name"
  else
    printf '  %-22s ✗ FAIL\n' "$name"
  fi
done

printf '\n結果: %d/%d テストスイート通過\n' "$((total - failed))" "$total"
[ "$failed" -gt 0 ] && exit 1
exit 0
