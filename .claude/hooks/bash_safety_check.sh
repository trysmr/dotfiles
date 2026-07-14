#!/bin/bash

# Bashコマンドの安全性チェック（PreToolUseフック）
# チェーン実行（&&, ||, ;, |, 改行）でdeny/askパターンがバイパスされることを防ぐ
# 動的コマンド名は解決できないためfail-closedでブロックする

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

# Bashパターンを抽出: "Bash(sudo:*)" -> "sudo"
# コマンド自体に含まれる ":" や "*" は保持する。
extract_patterns() {
  local key="$1"
  local spec
  jq -r ".permissions.${key}[]? // empty" "$SETTINGS_FILE" | \
    grep --color=never '^Bash(' | \
    sed 's/^Bash(//; s/)$//' | \
    while IFS= read -r spec; do
      case "$spec" in
        *':*') printf '%s\n' "${spec%:*}" ;;
        *) printf '%s\n' "$spec" ;;
      esac
    done
}

deny_patterns=$(extract_patterns "deny")
ask_patterns=$(extract_patterns "ask")

# deny/askパターンが両方空なら早期終了
if [ -z "$deny_patterns" ] && [ -z "$ask_patterns" ]; then
  exit 0
fi

# --- サブコマンド正規化 ---

trim_space() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

first_command_line() {
  local line
  local trimmed

  while IFS= read -r line; do
    trimmed=$(trim_space "$line")
    if [ -n "$trimmed" ]; then
      printf '%s' "$line"
      return
    fi
  done <<< "$1"
}

WORDS=()

parse_words() {
  local cmd="$1"
  local len=${#cmd}
  local i=0
  local char
  local word=""
  local in_single=false
  local in_double=false
  local escaped=false

  WORDS=()

  while (( i < len )); do
    char="${cmd:$i:1}"

    if $escaped; then
      word+="$char"
      escaped=false
      (( i++ ))
      continue
    fi

    if [ "$char" = "\\" ] && ! $in_single; then
      escaped=true
      (( i++ ))
      continue
    fi

    if [ "$char" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      (( i++ ))
      continue
    fi

    if [ "$char" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      (( i++ ))
      continue
    fi

    if ! $in_single && ! $in_double && [[ "$char" =~ [[:space:]] ]]; then
      if [ -n "$word" ]; then
        WORDS+=("$word")
        word=""
      fi
      (( i++ ))
      continue
    fi

    word+="$char"
    (( i++ ))
  done

  if [ -n "$word" ]; then
    WORDS+=("$word")
  fi
}

is_assignment_word() {
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]
}

word_basename() {
  local word="$1"

  case "$word" in
    *'$('*|*'`'*|'$'*|'${'*)
      printf '%s' "$word"
      ;;
    */*)
      printf '%s' "${word##*/}"
      ;;
    *)
      printf '%s' "$word"
      ;;
  esac
}

join_words_from() {
  local start="$1"
  local total="${#WORDS[@]}"
  local i="$start"
  local out=""
  local word

  while (( i < total )); do
    word="${WORDS[$i]}"
    if (( i == start )); then
      word=$(word_basename "$word")
    fi
    if [ -z "$out" ]; then
      out="$word"
    else
      out="$out $word"
    fi
    (( i++ ))
  done

  printf '%s' "$out"
}

NEXT_INDEX=0
NORMALIZE_DYNAMIC=false

skip_env_wrapper() {
  local i="$1"
  local total="${#WORDS[@]}"
  local word

  (( i++ ))

  while (( i < total )); do
    word="${WORDS[$i]}"

    if is_assignment_word "$word"; then
      (( i++ ))
      continue
    fi

    case "$word" in
      --)
        (( i++ ))
        break
        ;;
      -i|--ignore-environment|-0|--null)
        (( i++ ))
        ;;
      -u|-C|--unset|--chdir)
        (( i += 2 ))
        ;;
      --unset=*|--chdir=*)
        (( i++ ))
        ;;
      -S|--split-string|--split-string=*)
        NORMALIZE_DYNAMIC=true
        NEXT_INDEX="$total"
        return
        ;;
      -*)
        (( i++ ))
        ;;
      *)
        break
        ;;
    esac
  done

  NEXT_INDEX="$i"
}

normalize_git_command() {
  local start="$1"
  local total="${#WORDS[@]}"
  local i=$((start + 1))
  local word
  local out="git"

  while (( i < total )); do
    word="${WORDS[$i]}"
    case "$word" in
      --)
        (( i++ ))
        break
        ;;
      -C|-C*)
        printf '%s' "git -C"
        return
        ;;
      --git-dir|--git-dir=*)
        printf '%s' "git --git-dir"
        return
        ;;
      --work-tree|--work-tree=*)
        printf '%s' "git --work-tree"
        return
        ;;
      -c|-C|--git-dir|--work-tree|--namespace|--exec-path|--super-prefix|--config-env)
        (( i += 2 ))
        ;;
      -c*|--git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--super-prefix=*|--config-env=*)
        (( i++ ))
        ;;
      --no-pager|--paginate|-p|--bare|--literal-pathspecs|--no-literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs|--no-optional-locks)
        (( i++ ))
        ;;
      -*)
        (( i++ ))
        ;;
      *)
        break
        ;;
    esac
  done

  if (( i < total )); then
    case "${WORDS[$i]}" in
      *'$('*|*'`'*|'$'*|'${'*)
        printf '%s' "__dynamic_command__ git"
        return
        ;;
    esac
  fi

  while (( i < total )); do
    out="$out ${WORDS[$i]}"
    (( i++ ))
  done

  printf '%s' "$out"
}

normalize_subcmd() {
  local cmd="$1"
  local line
  local total
  local i=0
  local cmd_word

  line=$(first_command_line "$cmd")
  line=$(printf '%s' "$line" | tr '\t' ' ')
  line=$(trim_space "$line")
  [ -z "$line" ] && return

  parse_words "$line"
  total="${#WORDS[@]}"

  while (( i < total )) && is_assignment_word "${WORDS[$i]}"; do
    (( i++ ))
  done

  while (( i < total )); do
    cmd_word=$(word_basename "${WORDS[$i]}")
    case "$cmd_word" in
      command)
        (( i++ ))
        while (( i < total )) && [[ "${WORDS[$i]}" == -* ]]; do
          (( i++ ))
        done
        while (( i < total )) && is_assignment_word "${WORDS[$i]}"; do
          (( i++ ))
        done
        ;;
      env)
        NORMALIZE_DYNAMIC=false
        skip_env_wrapper "$i"
        if $NORMALIZE_DYNAMIC; then
          printf '%s' "__dynamic_command__ env -S"
          return
        fi
        i="$NEXT_INDEX"
        while (( i < total )) && is_assignment_word "${WORDS[$i]}"; do
          (( i++ ))
        done
        ;;
      *)
        break
        ;;
    esac
  done

  (( i >= total )) && return

  cmd_word=$(word_basename "${WORDS[$i]}")
  case "$cmd_word" in
    *'$('*|*'`'*|'$'*|'${'*)
      printf '%s' "__dynamic_command__ $(join_words_from "$i")"
      return
      ;;
    git)
      normalize_git_command "$i"
      ;;
    *)
      join_words_from "$i"
      ;;
  esac
}

# --- クォート考慮のコマンド分割 ---
# 結果はグローバル配列 SPLIT_RESULTS に格納（改行を含むサブコマンドに対応）
# RAW_SEGMENTS: パイプ/チェーン分割直後のセグメント（ヒアドク統合前）

SPLIT_RESULTS=()
RAW_SEGMENTS=()

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
      local prev=""
      if (( i > 0 )); then
        prev="${cmd:$((i-1)):1}"
      fi

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

      # |& 検出
      if [ "$char" = "|" ] && [ "$next" = "&" ]; then
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

      # & 検出（2>&1、&>file、<&0などのリダイレクトは除外）
      if [ "$char" = "&" ] && [ "$prev" != ">" ] && [ "$prev" != "<" ] && [ "$next" != ">" ]; then
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

  # パイプ/チェーン分割直後の生セグメントを保存（ヒアドクによる統合前）
  RAW_SEGMENTS=("${results[@]}")

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

normalize_raw_subcmd() {
  local line

  line=$(first_command_line "$1")
  line=$(printf '%s' "$line" | tr '\t' ' ' | sed 's/  */ /g')
  trim_space "$line"
}

pattern_matches() {
  local subcmd="$1"
  local pattern="$2"
  local last_word

  [ -z "$subcmd" ] && return 1
  [ -z "$pattern" ] && return 1

  case "$pattern" in
    *'*'*|*'?'*|*'['*)
      [[ "$subcmd" == $pattern ]]
      ;;
    *)
      if [[ "$subcmd" == "$pattern" || "$subcmd" == "$pattern "* ]]; then
        return 0
      fi

      last_word="${pattern##* }"
      if [[ "$last_word" == -* ]]; then
        [[ "$subcmd" == "$pattern"* ]]
      else
        return 1
      fi
      ;;
  esac
}

match_pattern_list() {
  local subcmd="$1"
  local patterns="$2"
  local kind="$3"
  local source="$4"
  local pattern

  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if pattern_matches "$subcmd" "$pattern"; then
      printf '%s' "${kind}:${source}:${pattern}"
      return 0
    fi
  done <<< "$patterns"

  return 1
}

check_against_patterns() {
  local raw
  local normalized
  local result

  raw=$(normalize_raw_subcmd "$1")
  normalized=$(normalize_subcmd "$1")

  result=$(match_pattern_list "$raw" "$deny_patterns" "deny" "direct")
  [ $? -eq 0 ] && { printf '%s' "$result"; return 0; }

  result=$(match_pattern_list "$normalized" "$deny_patterns" "deny" "normalized")
  [ $? -eq 0 ] && { printf '%s' "$result"; return 0; }

  result=$(match_pattern_list "$raw" "$ask_patterns" "ask" "direct")
  [ $? -eq 0 ] && { printf '%s' "$result"; return 0; }

  result=$(match_pattern_list "$normalized" "$ask_patterns" "ask" "normalized")
  [ $? -eq 0 ] && { printf '%s' "$result"; return 0; }

  if [[ "$normalized" == __dynamic_command__* ]]; then
    printf '%s' "dynamic:normalized:dynamic"
    return 0
  fi

  return 1
}

deny_for_match() {
  local result="$1"
  local context="$2"
  local force_ask_block="$3"
  local kind="${result%%:*}"
  local rest="${result#*:}"
  local source="${rest%%:*}"
  local pattern="${rest#*:}"

  case "$kind" in
    deny)
      deny "${context}に禁止コマンド「${pattern}」が検出されました。"
      ;;
    ask)
      if [ "$force_ask_block" = "true" ] || [ "$source" != "direct" ]; then
        deny "${context}に確認が必要なコマンド「${pattern}」が検出されました。コマンドは権限確認を迂回しない形で個別に実行してください。"
      fi
      ;;
    dynamic)
      deny "${context}に動的に決まるコマンド名が含まれています。権限確認を迂回できるため、実行するコマンド名を明示してください。"
      ;;
  esac
}

# クォート外にファイルへのリダイレクト（> / <）が含まれるか判定する。
# クォート内の '>' はただの文字列なのでリダイレクトとは見なさない。
# >&2 や 2>&1 のようなfd複製はファイル書き込みではないため対象外とする。
has_file_redirect() {
  local s="$1"
  local len=${#s}
  local i=0
  local ch
  local in_single=false
  local in_double=false
  local escaped=false

  while (( i < len )); do
    ch="${s:$i:1}"

    if $escaped; then
      escaped=false
      (( i++ ))
      continue
    fi

    if [ "$ch" = "\\" ] && ! $in_single; then
      escaped=true
      (( i++ ))
      continue
    fi

    if [ "$ch" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      (( i++ ))
      continue
    fi

    if [ "$ch" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      (( i++ ))
      continue
    fi

    if ! $in_single && ! $in_double && { [ "$ch" = ">" ] || [ "$ch" = "<" ]; }; then
      # 直後が & ならfd複製（>&2 / 2>&1 / <&0）なのでスキップ
      if [ "${s:$((i+1)):1}" = "&" ]; then
        (( i += 2 ))
        continue
      fi
      return 0
    fi

    (( i++ ))
  done

  return 1
}

enforce_segment() {
  local subcmd="$1"
  local context="$2"
  local force_ask_block="$3"
  local result
  local normalized

  # echoはaskパターンに載せず確認なしで通す方針のため、Write権限を迂回した
  # ファイル書き込みになるリダイレクト付きechoだけを、settingsのパターンに関係なくここで拒否する
  normalized=$(normalize_subcmd "$subcmd")
  case "$normalized" in
    echo|echo\ *|echo\>*|echo\<*)
      if has_file_redirect "$subcmd"; then
        deny "${context}にファイルへのリダイレクトを伴うechoが検出されました。ファイルの書き込みにはWrite/Editツールを使用してください。"
      fi
      ;;
  esac

  result=$(check_against_patterns "$subcmd")
  if [ $? -eq 0 ]; then
    deny_for_match "$result" "$context" "$force_ask_block"
  fi
}

# --- サブシェル/グループ化チェック ---
# (cmd) や { cmd; } の外側を剥がし、内容を再分割してチェック
# 既知の制限: ネストされた((...))は外側1段のみ検出

check_grouping() {
  local subcmd="$1"
  local trimmed
  trimmed=$(printf '%s' "$subcmd" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

  local inner=""
  if [[ "$trimmed" == '('*')' ]]; then
    inner="${trimmed:1:${#trimmed}-2}"
  elif [[ "$trimmed" == '{'*'}' ]]; then
    inner="${trimmed:1:${#trimmed}-2}"
    inner=$(printf '%s' "$inner" | sed 's/[[:space:]]*;[[:space:]]*$//')
  fi

  [ -z "$inner" ] && return

  local saved_results=("${SPLIT_RESULTS[@]}")
  local saved_raw=("${RAW_SEGMENTS[@]}")
  split_command "$inner"

  for raw_seg in "${RAW_SEGMENTS[@]}"; do
    enforce_segment "$raw_seg" "サブシェル/グループ内" "true"
  done

  for inner_cmd in "${SPLIT_RESULTS[@]}"; do
    enforce_segment "$inner_cmd" "サブシェル/グループ内" "true"
  done

  SPLIT_RESULTS=("${saved_results[@]}")
  RAW_SEGMENTS=("${saved_raw[@]}")
}

# --- メイン処理: コマンド分割と照合 ---

# 全体が () や {} で囲まれている場合、split前にチェック
# { cmd; } は ; で先に分割されるため、splitより前に処理する必要がある
check_grouping "$command"

split_command "$command"

has_chain=false
if (( ${#RAW_SEGMENTS[@]} > 1 || ${#SPLIT_RESULTS[@]} > 1 )); then
  has_chain=true
fi

# 分割後の各パーツについてもサブシェルチェック（パイプ先の(cmd)等）
for subcmd in "${SPLIT_RESULTS[@]}"; do
  check_grouping "$subcmd"
done

# ヒアドキュメント境界を越えたコマンドをRAW_SEGMENTSで検出
# split_commandのヒアドク解析でSPLIT_RESULTSが統合されても、分割直後のセグメントで検出できる
for raw_seg in "${RAW_SEGMENTS[@]}"; do
  enforce_segment "$raw_seg" "コマンド列" "$has_chain"
done

for subcmd in "${SPLIT_RESULTS[@]}"; do
  enforce_segment "$subcmd" "コマンド列" "$has_chain"
done

# --- 埋め込みコマンドチェック（$()・バッククォート・プロセス置換） ---

MATCH_END=-1

find_matching_paren() {
  local cmd="$1"
  local open_idx="$2"
  local len=${#cmd}
  local i=$((open_idx + 1))
  local depth=1
  local char
  local in_single=false
  local in_double=false
  local escaped=false

  MATCH_END=-1

  while (( i < len )); do
    char="${cmd:$i:1}"

    if $escaped; then
      escaped=false
      (( i++ ))
      continue
    fi

    if [ "$char" = "\\" ] && ! $in_single; then
      escaped=true
      (( i++ ))
      continue
    fi

    if [ "$char" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      (( i++ ))
      continue
    fi

    if [ "$char" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      (( i++ ))
      continue
    fi

    if ! $in_single; then
      if [ "$char" = "(" ]; then
        (( depth++ ))
      elif [ "$char" = ")" ]; then
        (( depth-- ))
        if (( depth == 0 )); then
          MATCH_END="$i"
          return
        fi
      fi
    fi

    (( i++ ))
  done
}

check_embedded_command() {
  local embedded="$1"
  local saved_results=("${SPLIT_RESULTS[@]}")
  local saved_raw=("${RAW_SEGMENTS[@]}")
  local raw_seg
  local embedded_cmd

  split_command "$embedded"

  for raw_seg in "${RAW_SEGMENTS[@]}"; do
    enforce_segment "$raw_seg" "埋め込みコマンド内" "true"
  done

  for embedded_cmd in "${SPLIT_RESULTS[@]}"; do
    check_grouping "$embedded_cmd"
    enforce_segment "$embedded_cmd" "埋め込みコマンド内" "true"
  done

  check_embedded "$embedded"

  SPLIT_RESULTS=("${saved_results[@]}")
  RAW_SEGMENTS=("${saved_raw[@]}")
}

check_embedded() {
  local cmd="$1"
  local len=${#cmd}
  local i=0
  local char
  local next
  local inner
  local in_single=false
  local in_double=false
  local escaped=false
  local backtick_start

  while (( i < len )); do
    char="${cmd:$i:1}"
    next="${cmd:$((i+1)):1}"

    if $escaped; then
      escaped=false
      (( i++ ))
      continue
    fi

    if [ "$char" = "\\" ] && ! $in_single; then
      escaped=true
      (( i++ ))
      continue
    fi

    if [ "$char" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      (( i++ ))
      continue
    fi

    if [ "$char" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      (( i++ ))
      continue
    fi

    if ! $in_single && [ "$char" = "$" ] && [ "$next" = "(" ]; then
      find_matching_paren "$cmd" "$((i + 1))"
      if (( MATCH_END > i )); then
        inner="${cmd:$((i + 2)):$((MATCH_END - i - 2))}"
        check_embedded_command "$inner"
        i=$((MATCH_END + 1))
        continue
      fi
    fi

    if ! $in_single && { [ "$char" = "<" ] || [ "$char" = ">" ]; } && [ "$next" = "(" ]; then
      find_matching_paren "$cmd" "$((i + 1))"
      if (( MATCH_END > i )); then
        inner="${cmd:$((i + 2)):$((MATCH_END - i - 2))}"
        check_embedded_command "$inner"
        i=$((MATCH_END + 1))
        continue
      fi
    fi

    if ! $in_single && [ "$char" = '`' ]; then
      backtick_start="$i"
      (( i++ ))
      while (( i < len )); do
        char="${cmd:$i:1}"
        if [ "$char" = "\\" ]; then
          (( i += 2 ))
          continue
        fi
        if [ "$char" = '`' ]; then
          inner="${cmd:$((backtick_start + 1)):$((i - backtick_start - 1))}"
          check_embedded_command "$inner"
          (( i++ ))
          continue 2
        fi
        (( i++ ))
      done
      continue
    fi

    (( i++ ))
  done
}

check_embedded "$command"

exit 0
