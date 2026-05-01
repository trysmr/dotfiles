#!/bin/bash

set -u

command -v mmdc >/dev/null 2>&1 || exit 0

input=$(cat)
last_text=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty')
[ -n "$last_text" ] || exit 0

mermaid_blocks=()
in_block=false
current_block=""

while IFS= read -r line; do
  if [ "$in_block" = false ] && [[ "$line" =~ ^\`\`\`mermaid ]]; then
    in_block=true
    current_block=""
    continue
  fi

  if [ "$in_block" = true ]; then
    if [[ "$line" =~ ^\`\`\` ]]; then
      in_block=false
      mermaid_blocks+=("$current_block")
    else
      current_block+="$line"$'\n'
    fi
  fi
done <<< "$last_text"

[ "${#mermaid_blocks[@]}" -gt 0 ] || exit 0

output_dir="${TMPDIR:-/tmp}/codex-mermaid"
mkdir -p "$output_dir"
timestamp=$(date +%Y%m%d_%H%M%S)

for i in "${!mermaid_blocks[@]}"; do
  input_file="${output_dir}/diagram_${timestamp}_${i}.mmd"
  output_file="${output_dir}/diagram_${timestamp}_${i}.png"

  printf '%s' "${mermaid_blocks[$i]}" > "$input_file"

  if mmdc -i "$input_file" -o "$output_file" -b transparent -t neutral --quiet 2>/dev/null; then
    if command -v open >/dev/null 2>&1 && [ -z "${SSH_CONNECTION:-}" ]; then
      open "$output_file" 2>/dev/null || true
    fi
  fi
done

exit 0
