#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
event=$(printf '%s' "$input" | hook_event_name)
command=$(printf '%s' "$input" | extract_field "command")

[ -z "$command" ] && exit 0

deny() {
  deny_current_event "$1" "$event"
}

normalized=$(printf '%s' "$command" | tr '\n' ' ' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//')

for token in $normalized; do
  token=${token#\'}
  token=${token%\'}
  token=${token#\"}
  token=${token%\"}

  # rg/find等の除外glob（例: --glob '!**/.git/**'）は直接参照ではないため除外する。
  if [[ "$token" == "!"* || "$token" == *"*"* || "$token" == *"?"* || "$token" == *"["* ]]; then
    continue
  fi

  case "$token" in
    .git|.git/*|*/.git|*/.git/*)
      deny ".gitディレクトリを直接参照するコマンドは禁止されています。gitコマンド経由で確認してください。"
      ;;
  esac
done

if [[ "$normalized" =~ (^|[[:space:];|&])sudo($|[[:space:]]) ]]; then
  deny "sudoの実行は禁止されています。必要な場合は目的と影響範囲をユーザーに確認してください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])(bash|sh|zsh)[[:space:]]+-c($|[[:space:]]) ]]; then
  deny "shell -c は権限ルールを迂回しやすいため禁止されています。直接コマンドを実行してください。"
fi

if [[ "$normalized" =~ (^|[;|&][[:space:]]*)(eval|exec)($|[[:space:]]) ]]; then
  deny "eval/execは禁止されています。展開後の具体的なコマンドを使ってください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])git[[:space:]]+(-C|--git-dir|--work-tree) ]]; then
  deny "gitの作業ディレクトリ差し替えは禁止されています。現在のワークツリーで実行してください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])git[[:space:]]+(reset|rebase|clean|filter-branch|update-ref)($|[[:space:]]) ]]; then
  deny "破壊的なgit操作は禁止されています。必要な場合はユーザーの明示許可を得てください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])git[[:space:]]+push[[:space:]].*(-f|--force|--force-with-lease|--delete) ]]; then
  deny "force pushまたはリモート削除は禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])rm[[:space:]].*(-r|-R|--recursive) ]]; then
  deny "再帰的なrmは禁止されています。削除対象と理由をユーザーに確認してください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])(truncate|dd|shred|mkfs)($|[[:space:]]) ]]; then
  deny "データ破壊につながるコマンドは禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&(])(terraform[[:space:]]+(destroy|state[[:space:]]+rm))($|[[:space:];|&)]) ]]; then
  deny "Terraformリソースの削除またはstateからの除外は禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&(])docker[[:space:]]+(system|image|container|volume|network|builder)[[:space:]]+prune($|[[:space:];|&)]) ]]; then
  deny "Dockerリソースの一括削除は禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&(])gh[[:space:]]+(repo|release)[[:space:]]+delete($|[[:space:];|&)]) ]]; then
  deny "GitHub上のリソース削除は禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&(])gem[[:space:]]+(push|yank)($|[[:space:];|&)]) ]] || \
   [[ "$normalized" =~ (^|[[:space:];|&(])(npm|yarn|pnpm)[[:space:]]+(publish|unpublish)($|[[:space:];|&)]) ]]; then
  deny "パッケージの公開または取り下げは禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&(])((bundle[[:space:]]+exec[[:space:]]+)?(bin/rails|rails|bin/rake|rake))[[:space:]]+(db:reset|db:drop|db:schema:load|db:setup|credentials:diff|credentials:edit|credentials:show)($|[[:space:];|&)]) ]]; then
  deny "データまたは認証情報へ危険な変更やアクセスを行うRailsコマンドは禁止されています。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])(cat|sed|awk|less|more|head|tail|rg|grep)[[:space:]].*\.env($|[[:space:]./_-]) ]]; then
  deny ".env系ファイルの読み取りは禁止されています。"
fi

# 承認対象をチェーンやパイプへ埋め込むと、個別の承認画面を迂回する可能性がある。
approval_pattern='(curl|wget|rm|kill|killall|chmod|pkill|chown)([[:space:]]|$)|git[[:space:]]+(commit|stash|cherry-pick|merge|push)([[:space:]]|$)|gh[[:space:]]+pr[[:space:]]+(create|merge|close|comment|edit|review|reopen)([[:space:]]|$)|(bin/rails|rails|bin/rake|rake)[[:space:]]+(db:migrate|db:rollback|db:up|db:down|db:fixtures:load|runner|console)([[:space:]]|$)|bundle[[:space:]]+exec[[:space:]]+(bin/rails|rails|bin/rake|rake)[[:space:]]+(db:migrate|db:rollback|db:up|db:down|db:fixtures:load|runner|console)([[:space:]]|$)|(psql|mysql|sqlite3|launchctl|osascript)([[:space:]]|$)|docker[[:space:]]+compose[[:space:]]+down([[:space:]]|$)|docker[[:space:]]+volume[[:space:]]+rm([[:space:]]|$)|terraform[[:space:]]+(apply|taint)([[:space:]]|$)|defaults[[:space:]]+delete([[:space:]]|$)'

has_unquoted_chain() {
  local value="$1"
  local length=${#value}
  local index=0
  local char
  local next
  local in_single=false
  local in_double=false
  local escaped=false

  while (( index < length )); do
    char="${value:$index:1}"
    next="${value:$((index + 1)):1}"

    if $escaped; then
      escaped=false
      (( index++ ))
      continue
    fi

    if [ "$char" = "\\" ] && ! $in_single; then
      escaped=true
      (( index++ ))
      continue
    fi

    if [ "$char" = "'" ] && ! $in_double; then
      if $in_single; then in_single=false; else in_single=true; fi
      (( index++ ))
      continue
    fi

    if [ "$char" = '"' ] && ! $in_single; then
      if $in_double; then in_double=false; else in_double=true; fi
      (( index++ ))
      continue
    fi

    if ! $in_single && ! $in_double; then
      if [ "$char" = ";" ] || [ "$char" = "|" ] || { [ "$char" = "&" ] && [ "$next" = "&" ]; }; then
        return 0
      fi
    fi

    (( index++ ))
  done

  return 1
}

if has_unquoted_chain "$command" && [[ "$normalized" =~ $approval_pattern ]]; then
  deny "コマンド列に確認が必要な操作が含まれています。承認対象のコマンドを個別に実行してください。"
fi

while IFS= read -r line; do
  [ -z "$line" ] && continue
  if [[ "$line" =~ ^[[:space:]]*$approval_pattern ]]; then
    first_line=$(printf '%s' "$command" | sed -n '1p')
    if [ "$line" != "$first_line" ]; then
      deny "改行後に確認が必要な操作が含まれています。承認対象のコマンドを個別に実行してください。"
    fi
  fi
done <<< "$command"

if [[ "$normalized" =~ \$\([[:space:]]*($approval_pattern) ]]; then
  deny "埋め込みコマンドに確認が必要な操作が含まれています。承認対象のコマンドを個別に実行してください。"
fi

exit 0
