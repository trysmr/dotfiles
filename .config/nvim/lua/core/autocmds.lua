local api = vim.api

api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("UserYankHighlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("GoIndentSettings", { clear = true }),
  pattern = { "go", "gomod", "gowork" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false
  end,
})

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("RubyIndentSettings", { clear = true }),
  pattern = { "ruby", "eruby" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("PythonIndentSettings", { clear = true }),
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("RustIndentSettings", { clear = true }),
  pattern = { "rust" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
