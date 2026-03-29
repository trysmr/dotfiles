#!/bin/bash

# settings.json の構造整合性検証スクリプト

SETTINGS_FILE="${SETTINGS_FILE:-$(dirname "$0")/../settings.json}"
HOOKS_DIR="$(dirname "$0")"
SKILLS_DIR="$(dirname "$0")/../skills"
pass=0
fail=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "true" ]; then
    printf '✓ %s\n' "$desc"
    (( pass++ ))
  else
    printf '✗ %s\n' "$desc"
    (( fail++ ))
  fi
}

echo "=== JSON構文検証 ==="
if jq '.' "$SETTINGS_FILE" > /dev/null 2>&1; then
  check "settings.jsonはvalid JSON" "true"
else
  check "settings.jsonはvalid JSON" "false"
  printf '  エラー: %s\n' "$(jq '.' "$SETTINGS_FILE" 2>&1)"
  # JSON自体が壊れている場合、以降のチェックは不可
  echo ""
  echo "=== 結果 ==="
  printf '合計: 0/1 (pass: 0, fail: 1)\n'
  exit 1
fi

echo ""
echo "=== Hook参照ファイル存在確認 ==="
# hooks内の全commandフィールドを抽出して、ファイルの存在を確認
commands=$(jq -r '
  .hooks // {} | to_entries[] | .value[] | .hooks[]? | .command // empty
' "$SETTINGS_FILE" | sort -u)

while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  # ~/ を $HOME/ に展開
  expanded="${cmd/#\~\//$HOME/}"
  # コマンド引数を除去（最初のスペースまで）
  cmd_path="${expanded%% *}"
  if [ -f "$cmd_path" ]; then
    check "Hook存在: $cmd" "true"
  else
    check "Hook存在: $cmd" "false"
    printf '  ファイルが見つかりません: %s\n' "$cmd_path"
  fi
done <<< "$commands"

echo ""
echo "=== Skill参照ディレクトリ存在確認 ==="
# permissions.allow内のSkill(name)パターンからSkill名を抽出
skill_names=$(jq -r '
  .permissions.allow // [] | .[] |
  select(startswith("Skill(")) |
  sub("^Skill\\("; "") | sub("\\)$"; "") |
  sub(":.*$"; "")
' "$SETTINGS_FILE" | sort -u)

while IFS= read -r skill; do
  [ -z "$skill" ] && continue
  if [ -d "$SKILLS_DIR/$skill" ]; then
    check "Skill存在: $skill" "true"
  else
    check "Skill存在: $skill" "false"
    printf '  ディレクトリが見つかりません: %s/%s\n' "$SKILLS_DIR" "$skill"
  fi
done <<< "$skill_names"

echo ""
echo "=== permissions構造チェック ==="
# allow/deny/askが配列であること
for section in allow deny ask; do
  type=$(jq -r ".permissions.${section} | type" "$SETTINGS_FILE" 2>/dev/null)
  if [ "$type" = "array" ]; then
    check "permissions.${section} は配列" "true"
  elif [ "$type" = "null" ]; then
    check "permissions.${section} は配列（未定義、省略可）" "true"
  else
    check "permissions.${section} は配列" "false"
    printf '  実際の型: %s\n' "$type"
  fi
done

# deny と allow の明確な矛盾チェック（完全一致パターンの重複）
contradictions=$(jq -r '
  (.permissions.allow // []) as $allow |
  (.permissions.deny // []) as $deny |
  [$allow[] | select(. as $a | $deny[] | . == $a)]
  | unique | .[]
' "$SETTINGS_FILE" 2>/dev/null)

if [ -z "$contradictions" ]; then
  check "allow/deny間に完全一致の矛盾なし" "true"
else
  check "allow/deny間に完全一致の矛盾なし" "false"
  printf '  矛盾パターン: %s\n' "$contradictions"
fi

echo ""
echo "=== 結果 ==="
total=$((pass + fail))
printf '合計: %d/%d (pass: %d, fail: %d)\n' "$pass" "$total" "$pass" "$fail"
[ $fail -eq 0 ] && printf '全チェック通過 ✓\n' || printf '失敗あり ✗\n'
exit $fail
