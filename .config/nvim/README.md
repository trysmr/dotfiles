# Neovim 設定ガイド

## 方針

- 6言語（Go, Ruby, TypeScript/JS, Rust, Python, Lua）対応の IDE 風環境
- カスタムキーは `<leader>`（Space）プレフィックスで統一し、which-key で発見可能にする
- LSP / formatter / linter の責務を明確に分離する
- 起動時は空バッファか指定ファイルだけを開く（dashboard 等は使わない）
- プラグインは各ファイルが自己完結する lazy.nvim spec 形式で管理する

## 読む順番

1. `init.lua` — エントリポイント（4行の require）
2. `lua/core/options.lua` — Vim オプション
3. `lua/core/keymaps.lua` — leader キーマップ
4. `lua/core/autocmds.lua` — 自動コマンド
5. `lua/core/lazy.lua` — lazy.nvim ブートストラップ
6. `lua/plugins/*.lua` — プラグインごとの設定

## キーマップ

`<leader>?` で which-key ヘルプを表示できる。

### leader グループ

| プレフィックス | グループ | 用途 |
|-------------|---------|------|
| `<leader>f` | find | 検索（telescope） |
| `<leader>g` | git | Git 操作 |
| `<leader>c` | code | フォーマット、コードアクション、リネーム |
| `<leader>d` | diagnostics | 診断・エラー表示 |
| `<leader>b` | buffers | バッファ操作 |
| `<leader>e` | explorer | ファイルツリー |
| `<leader>t` | terminal | ターミナル |
| `<leader>o` | outline | コードアウトライン |

### よく使うキー

```
検索:       <leader>ff=ファイル  fg=grep  fb=バッファ  fh=ヘルプ  fr=最近  ft=TODO
Git:        <leader>gs=ステージ  gr=リセット  gp=プレビュー  gb=blame  gg=lazygit
コード:     <leader>cf=フォーマット  ca=アクション  cr=リネーム
診断:       <leader>dd=行診断  dw=ワークスペース  db=バッファ
バッファ:    <leader>bd=閉じる  bo=他を閉じる  S-h/S-l=前後移動
エクスプ:    <leader>ee=トグル  ef=現ファイル表示
ターミナル:  <leader>tt=水平  tf=フロート  C-\=トグル
アウトライン: <leader>oo=トグル
LSP:        gd=定義  gD=宣言  gi=実装  gr=参照  K=ホバー  [d/]d=診断移動
```

## 構成

- `lua/core/options.lua`: 基本設定
- `lua/core/keymaps.lua`: leader 系キーマップ
- `lua/core/autocmds.lua`: yank ハイライトと言語別インデント
- `lua/core/lazy.lua`: lazy.nvim の bootstrap
- `lua/plugins/*.lua`: プラグインごとの責務（1プラグイン = 1ファイル）

## 言語ツーリング

| 言語 | LSP | formatter | external linter |
|------|-----|-----------|-----------------|
| Go | gopls | goimports + gofumpt | なし（gopls 内蔵） |
| Ruby | ruby_lsp | rubocop | rubocop |
| TypeScript/JS | ts_ls | prettierd | eslint_d |
| Rust | rust_analyzer | rustfmt | なし（clippy 内蔵） |
| Python | basedpyright | ruff_format | ruff |
| Lua | lua_ls | stylua | なし（lua_ls 内蔵） |

## キーマップの定義場所

キーマップはプラグインの spec ファイル内の `keys` で定義するのが基本。
`core/keymaps.lua` にはプラグイン横断的なものだけを置く。

| キー | 定義ファイル |
|------|------------|
| `<leader>f*` (検索) | `core/keymaps.lua` |
| `<leader>cf` (フォーマット) | `core/keymaps.lua` |
| `<leader>dd` (行診断) | `core/keymaps.lua` |
| `S-h/S-l`, `<leader>bo` (バッファ) | `core/keymaps.lua` |
| `<leader>bd/bp` (バッファ) | `plugins/bufferline.lua` |
| `gd/gr/K` 等, `<leader>cr/ca` (LSP) | `plugins/lsp.lua` |
| `<leader>g*` (Git) | `plugins/git.lua` |
| `<leader>ee/ef` (エクスプローラ) | `plugins/neo-tree.lua` |
| `<leader>tt/tf`, `C-\` (ターミナル) | `plugins/toggleterm.lua` |
| `<leader>oo` (アウトライン) | `plugins/outline.lua` |
| `<leader>dw/db/dl` (診断パネル) | `plugins/trouble.lua` |

## プラグインを足す時の手順

1. `lua/plugins/` に新しいファイルを作る（lazy.nvim が自動で読み込む）
2. lazy-load イベントを適切に設定する（起動速度を維持）
3. キーマップは which-key グループに沿って `<leader>` プレフィックスで追加する
