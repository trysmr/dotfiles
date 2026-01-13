# fzf 基本設定・見た目カスタマイズ

# =============================================================================
# グローバルデフォルト設定
# =============================================================================

# TokyoNight カラースキーム + リッチな見た目
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --padding=1
  --margin=1
  --info=inline
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
  --color=border:#27a1b9,gutter:#1a1b26
  --preview-window=right:50%:wrap:border-left
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-d:preview-page-down'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-y:execute-silent(echo -n {+} | pbcopy)'
  --bind='alt-a:select-all'
  --bind='alt-d:deselect-all'
"

# =============================================================================
# Ctrl-T: ファイル検索
# =============================================================================

export FZF_CTRL_T_OPTS="
  --preview 'if [ -d {} ]; then ls -la {} 2>/dev/null; else cat -n {} 2>/dev/null || echo \"バイナリファイルまたは読み込み不可\"; fi'
  --preview-window 'right:50%:wrap:border-left'
  --header='📁 ファイル/ディレクトリを選択 | Ctrl-/: プレビュー切替 | Ctrl-Y: パスをコピー'
  --bind='enter:become(echo {+})'
"

# =============================================================================
# Alt-C: ディレクトリ移動
# =============================================================================

export FZF_ALT_C_OPTS="
  --preview 'ls -la {} 2>/dev/null'
  --preview-window 'right:50%:wrap:border-left'
  --header='📂 ディレクトリを選択して移動 | Ctrl-/: プレビュー切替'
"

# =============================================================================
# Ctrl-R: コマンド履歴検索
# =============================================================================

export FZF_CTRL_R_OPTS="
  --preview-window 'hidden'
  --header='⌨️  コマンド履歴を検索'
  --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)'
  --info=inline
"
