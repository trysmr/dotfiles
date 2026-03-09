#!/bin/bash

# Bashコマンドの安全性チェック（PreToolUseフック）
# チェーン実行（&&, ||, ;, |, 改行）でdeny/askパターンがバイパスされることを防ぐ
# 既知の制限: ネストされた$()、プロセス置換<()、変数展開$cmd、エイリアスは検出不可

input=$(cat)
is_copilot=$(printf '%s' "$input" | jq -r 'has("toolName")')
command=$(printf '%s' "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .command?
  ) // .toolInput.command? // .tool_input.command? // ""
')

# 空コマンドは早期終了
[ -z "$command" ] && exit 0

deny() {
  local message="$1"

  if [ "$is_copilot" = "true" ]; then
    jq -nc --arg msg "$message" \
      '{"permissionDecision":"deny","permissionDecisionReason":$msg}'
    exit 0
  fi

  printf '%s\n' "$message" >&2
  exit 2
}

# --- settings.jsonからdeny/askパターンを抽出 ---

SETTINGS_FILE="${SETTINGS_FILE:-$HOME/.claude/settings.json}"

if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

# パースチェックを抽出より先に実行（fail-closed）
if ! jq -e '.permissions' "$SETTINGS_FILE" >/dev/null 2>&1; then
  deny "settings.jsonのパースに失敗しました。安全のため実行をブロックします。"
fi

# Bashパターンを抽出: "Bash(sudo:*)" → "sudo"
extract_patterns() {
  local key="$1"
  jq -r ".permissions.${key}[]? // empty" "$SETTINGS_FILE" | \
    grep --color=never '^Bash(' | \
    sed 's/^Bash(//; s/)$//; s/:.*$//'
}

deny_patterns=$(extract_patterns "deny")
ask_patterns=$(extract_patterns "ask")

# deny/askパターンが両方空なら早期終了
if [ -z "$deny_patterns" ] && [ -z "$ask_patterns" ]; then
  exit 0
fi

# --- git -C チェック（既存ロジック維持） ---

if [[ "$command" =~ git[[:space:]]+-C[[:space:]=] ]]; then
  deny "-Cオプションは禁止されています。現在のディレクトリでgitコマンドを実行してください。"
fi

# --- サブコマンド正規化 ---

normalize_subcmd() {
  local cmd="$1"

  # 1. 空白正規化（タブ→スペース、複数スペース→単一、先頭末尾除去）
  cmd=$(printf '%s' "$cmd" | tr '\t' ' ' | sed 's/  */ /g; s/^ //; s/ $//')

  # 2. command/env ラッパーを除去
  while true; do
    case "$cmd" in
      command\ *) cmd="${cmd#command }" ;;
      env\ -*)
        # envのオプション（-i等）をスキップ
        cmd="${cmd#env }"
        while [[ "$cmd" == -* ]]; do
          cmd="${cmd#* }"
        done
        ;;
      env\ *=*)
        # env KEY=VALUE ... の形式
        cmd="${cmd#env }"
        while [[ "$cmd" == *=* ]]; do
          local first_word="${cmd%% *}"
          if [[ "$first_word" == *=* ]]; then
            if [ "$cmd" = "$first_word" ]; then
              cmd=""
              break
            fi
            cmd="${cmd#* }"
          else
            break
          fi
        done
        ;;
      env\ *) cmd="${cmd#env }" ;;
      *) break ;;
    esac
  done

  # 3. 絶対パス → ベース名
  if [[ "$cmd" == /* ]]; then
    local first_word="${cmd%% *}"
    local rest=""
    if [ "$cmd" != "$first_word" ]; then
      rest="${cmd#"$first_word"}"
    fi
    local basename="${first_word##*/}"
    cmd="${basename}${rest}"
  fi

  printf '%s' "$cmd"
}

# --- クォート考慮のコマンド分割 ---
# 結果はグローバル配列 SPLIT_RESULTS に格納（改行を含むサブコマンドに対応）

SPLIT_RESULTS=()

split_command() {
  local cmd="$1"
  local len=${#cmd}
  local i=0
  local in_single=false
  local in_double=false
  local escaped=false
  local current=""
  local results=()

  while (( i < len )); do
    local char="${cmd:$i:1}"

    if $escaped; then
      current+="$char"
      escaped=false
      (( i++ ))
      continue
    fi

    if [ "$char" = "\\" ] && ! $in_single; then
      escaped=true
      current+="$char"
      (( i++ ))
      continue
    fi

    if [ "$char" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      current+="$char"
      (( i++ ))
      continue
    fi

    if [ "$char" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      current+="$char"
      (( i++ ))
      continue
    fi

    # クォート外でのみ演算子を検出
    if ! $in_single && ! $in_double; then
      local next="${cmd:$((i+1)):1}"

      # && 検出
      if [ "$char" = "&" ] && [ "$next" = "&" ]; then
        results+=("$current")
        current=""
        (( i += 2 ))
        continue
      fi

      # || 検出
      if [ "$char" = "|" ] && [ "$next" = "|" ]; then
        results+=("$current")
        current=""
        (( i += 2 ))
        continue
      fi

      # | 検出（単独、||ではない）
      if [ "$char" = "|" ] && [ "$next" != "|" ]; then
        results+=("$current")
        current=""
        (( i++ ))
        continue
      fi

      # ; 検出
      if [ "$char" = ";" ]; then
        results+=("$current")
        current=""
        (( i++ ))
        continue
      fi
    fi

    current+="$char"
    (( i++ ))
  done

  results+=("$current")

  # 改行でさらに分割（ヒアドク内は分割しない）
  SPLIT_RESULTS=()
  local heredoc_terminator=""
  local heredoc_just_ended=false
  local last_idx
  local close_re='^[)"'"'"']+$'
  for part in "${results[@]}"; do
    while IFS= read -r line; do
      if [ -n "$heredoc_terminator" ]; then
        local trimmed
        trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ "$trimmed" = "$heredoc_terminator" ]; then
          heredoc_terminator=""
          heredoc_just_ended=true
        fi
        # ヒアドク内の行は前のコマンドに結合（Bash 3.2互換）
        last_idx=$(( ${#SPLIT_RESULTS[@]} - 1 ))
        SPLIT_RESULTS[$last_idx]="${SPLIT_RESULTS[$last_idx]}"$'\n'"$line"
        continue
      fi
      # ヒアドク終端直後の閉じ括弧行（例: )"）も前のコマンドに結合
      if $heredoc_just_ended; then
        heredoc_just_ended=false
        local close_trimmed
        close_trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [[ "$close_trimmed" =~ $close_re ]] || [ -z "$close_trimmed" ]; then
          last_idx=$(( ${#SPLIT_RESULTS[@]} - 1 ))
          SPLIT_RESULTS[$last_idx]="${SPLIT_RESULTS[$last_idx]}"$'\n'"$line"
          continue
        fi
      fi
      heredoc_just_ended=false
      # 空行はスキップ（<<<ヒアストリングの末尾改行対策）
      local line_trimmed
      line_trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$line_trimmed" ] && continue
      # ヒアドク開始を検出: <<EOF, <<'EOF', <<"EOF", <<-EOF 等
      if [[ "$line" =~ \<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]? ]]; then
        heredoc_terminator="${BASH_REMATCH[1]}"
      fi
      SPLIT_RESULTS+=("$line")
    done <<< "$part"
  done
}

# --- パターン照合 ---

check_against_patterns() {
  local subcmd
  subcmd=$(normalize_subcmd "$1")

  [ -z "$subcmd" ] && return 1

  local pattern
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if [[ "$subcmd" == "$pattern" || "$subcmd" == "$pattern "* ]]; then
      printf '%s' "deny:$pattern"
      return 0
    fi
  done <<< "$deny_patterns"

  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if [[ "$subcmd" == "$pattern" || "$subcmd" == "$pattern "* ]]; then
      printf '%s' "ask:$pattern"
      return 0
    fi
  done <<< "$ask_patterns"

  return 1
}

# --- メイン処理: コマンド分割と照合 ---

split_command "$command"

if (( ${#SPLIT_RESULTS[@]} > 1 )); then
  for subcmd in "${SPLIT_RESULTS[@]}"; do
    result=$(check_against_patterns "$subcmd")
    if [ $? -eq 0 ]; then
      case "$result" in
        deny:*)
          pattern="${result#deny:}"
          deny "禁止コマンド「${pattern}」がチェーン内に含まれています。コマンドは個別に実行してください。"
          ;;
        ask:*)
          pattern="${result#ask:}"
          deny "確認が必要なコマンド「${pattern}」がチェーン内に含まれています。コマンドは個別に実行してください。"
          ;;
      esac
    fi
  done
fi

# --- 埋め込みコマンドチェック（$()・バッククォート） ---
# 既知の制限: ネストされた$()は外側のみ検出

check_embedded() {
  local cmd="$1"

  # $(...) 内のコマンドを抽出（簡易: ネストは非対応）
  local embedded
  embedded=$(printf '%s' "$cmd" | grep -oE '\$\([^)]+\)' | sed 's/^\$(//' | sed 's/)$//')

  # バッククォート内も抽出
  local backtick
  backtick=$(printf '%s' "$cmd" | grep -oE '`[^`]+`' | sed 's/^`//' | sed 's/`$//')

  local all_embedded="${embedded}
${backtick}"

  while IFS= read -r emb; do
    [ -z "$emb" ] && continue
    # 正規化して先頭コマンドで判定（部分一致による誤検出を防止）
    local normalized
    normalized=$(normalize_subcmd "$emb")
    [ -z "$normalized" ] && continue
    local pattern
    while IFS= read -r pattern; do
      [ -z "$pattern" ] && continue
      if [[ "$normalized" == "$pattern" || "$normalized" == "$pattern "* ]]; then
        deny "埋め込みコマンド内に禁止パターン「${pattern}」が検出されました。"
      fi
    done <<< "$deny_patterns"
    while IFS= read -r pattern; do
      [ -z "$pattern" ] && continue
      if [[ "$normalized" == "$pattern" || "$normalized" == "$pattern "* ]]; then
        deny "埋め込みコマンド内に確認が必要なパターン「${pattern}」が検出されました。"
      fi
    done <<< "$ask_patterns"
  done <<< "$all_embedded"
}

check_embedded "$command"

exit 0
