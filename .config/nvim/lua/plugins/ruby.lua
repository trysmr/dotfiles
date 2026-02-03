-- Ruby言語固有の設定
-- LSP設定はlsp.luaで一元管理

-- Rubyファイルのインデント設定
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("RubyIndent", { clear = true }),
  pattern = { "ruby", "eruby" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- 保存時に自動フォーマット
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("RubyFormat", { clear = true }),
  pattern = { "*.rb", "*.erb" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- プラグインなし（autocmdのみ）
return {}
