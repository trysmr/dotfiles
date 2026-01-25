-- Go言語固有の設定
-- LSP共通設定はlsp.luaで行う

-- Goファイルのインデント設定（起動時に即座に登録）
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

return {
  -- gopls設定
  {
    "neovim/nvim-lspconfig",
    ft = { "go", "gomod", "gowork", "gotmpl" },
    config = function()
      vim.lsp.config.gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.mod", "go.work", ".git" },
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
            gofumpt = true, -- より厳格なフォーマット
          },
        },
      }
      vim.lsp.enable("gopls")
    end,
  },
}
