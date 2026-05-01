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

case "$normalized" in
  *".git/"*|*"/.git/"*)
    deny ".gitディレクトリを直接参照するコマンドは禁止されています。gitコマンド経由で確認してください。"
    ;;
esac

if [[ "$normalized" =~ (^|[[:space:];|&])sudo($|[[:space:]]) ]]; then
  deny "sudoの実行は禁止されています。必要な場合は目的と影響範囲をユーザーに確認してください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])(bash|sh|zsh)[[:space:]]+-c($|[[:space:]]) ]]; then
  deny "shell -c は権限ルールを迂回しやすいため禁止されています。直接コマンドを実行してください。"
fi

if [[ "$normalized" =~ (^|[[:space:];|&])(eval|exec)($|[[:space:]]) ]]; then
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

if [[ "$normalized" =~ (^|[[:space:];|&])(cat|sed|awk|less|more|head|tail|rg|grep)[[:space:]].*\.env($|[[:space:]./_-]) ]]; then
  deny ".env系ファイルの読み取りは禁止されています。"
fi

exit 0
