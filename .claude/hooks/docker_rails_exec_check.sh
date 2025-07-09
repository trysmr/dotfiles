#!/bin/bash

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

# 対象：rails, bundle, rake など
if [[ "$command" =~ ^(rails|bundle|rake) ]]; then
  echo "Dockerコンテナ内で実行してください: docker compose exec app $command" >&2
  exit 2
fi

exit 0