-- Ruby言語固有の設定
-- LSP共通設定はlsp.luaで行う

-- Rubyファイルのインデント設定（起動時に即座に登録）
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

return {
  -- ruby_lsp設定
  {
    "neovim/nvim-lspconfig",
    ft = { "ruby", "eruby" },
    config = function()
      vim.lsp.config.ruby_lsp = {
        cmd = { "ruby-lsp" },
        filetypes = { "ruby", "eruby" },
        root_markers = { "Gemfile", ".git" },
        init_options = {
          formatter = "auto",
        },
      }
      vim.lsp.enable("ruby_lsp")
    end,
  },
}
