vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 使わないプロバイダーを無効化
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.showmode = false -- lualineがモード表示するので不要
opt.wrap = false -- 折り返しなし。必要になったら:set wrap!
opt.fillchars = { eob = " " } -- バッファ末尾の~を非表示

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.scrolloff = 8
opt.sidescrolloff = 8
opt.undofile = true
opt.mouse = "a"
opt.splitbelow = true
opt.splitright = true

-- 既定は 2 スペースにし、言語ごとの差分は autocmd 側で上書きする。
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
