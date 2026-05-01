#!/bin/bash

# Stop hook: Claudeの応答からMermaidダイアグラムを検出し、自動レンダリングして表示
# 依存: mmdc (npm install -g @mermaid-js/mermaid-cli), jq

# mmdc未インストールならスキップ
command -v mmdc &>/dev/null || exit 0

# stdin からhook入力を読み取り
input=$(cat)
last_text=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty')

if [[ -z "$last_text" ]]; then
  exit 0
fi

# Mermaidブロックの抽出（```mermaid ... ``` の中身）
# 複数ブロックに対応
mermaid_blocks=()
in_block=false
current_block=""

while IFS= read -r line; do
  if [[ "$in_block" == false && "$line" =~ ^\`\`\`mermaid ]]; then
    in_block=true
    current_block=""
    continue
  fi
  if [[ "$in_block" == true ]]; then
    if [[ "$line" =~ ^\`\`\` ]]; then
      in_block=false
      mermaid_blocks+=("$current_block")
    else
      current_block+="$line"$'\n'
    fi
  fi
done <<< "$last_text"

if [[ ${#mermaid_blocks[@]} -eq 0 ]]; then
  exit 0
fi

# 出力ディレクトリ
output_dir="${TMPDIR:-/tmp}/claude-mermaid"
mkdir -p "$output_dir"

# 各ブロックをレンダリングして表示
timestamp=$(date +%Y%m%d_%H%M%S)
for i in "${!mermaid_blocks[@]}"; do
  input_file="${output_dir}/diagram_${timestamp}_${i}.mmd"
  output_file="${output_dir}/diagram_${timestamp}_${i}.png"

  printf '%s' "${mermaid_blocks[$i]}" > "$input_file"

  if mmdc -i "$input_file" -o "$output_file" -b transparent -t neutral --quiet 2>/dev/null; then
    # macOSのプレビューで表示
    open "$output_file" 2>/dev/null
  fi
done

exit 0
