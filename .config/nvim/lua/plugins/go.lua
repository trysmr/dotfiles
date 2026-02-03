-- Go言語固有の設定
-- LSP設定はlsp.luaで一元管理

-- Goファイルのインデント設定
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("GoIndent", { clear = true }),
  pattern = { "go", "gomod", "gowork" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false -- Goはタブを使用
  end,
})

-- 保存時に自動フォーマット
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("GoFormat", { clear = true }),
  pattern = "*.go",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- プラグインなし（autocmdのみ）
return {}
