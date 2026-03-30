local map = vim.keymap.set

-- 挿入モードでmacOS風カーソル移動
map("i", "<C-f>", "<Right>", { desc = "Move right" })
map("i", "<C-b>", "<Left>", { desc = "Move left" })
map("i", "<C-n>", "<Down>", { desc = "Move down" })
map("i", "<C-p>", "<Up>", { desc = "Move up" })
map("i", "<C-a>", "<Home>", { desc = "Move to beginning" })
map("i", "<C-e>", "<End>", { desc = "Move to end" })
map("i", "<C-k>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  if col <= #line then
    vim.fn.setline(".", line:sub(1, col - 1))
  end
end, { desc = "Kill to end of line" })
map("i", "<C-d>", "<Delete>", { desc = "Delete forward" })
map("i", "<C-h>", "<BS>", { desc = "Delete backward" })

-- 検索 (telescope)
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ hidden = true })
end, { desc = "Find files" })
map("n", "<C-p>", function()
  require("telescope.builtin").find_files({ hidden = true })
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })
map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, { desc = "Buffers" })
map("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end, { desc = "Help tags" })
map("n", "<leader>fr", function()
  require("telescope.builtin").oldfiles()
end, { desc = "Recent files" })
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })

-- コード (conform)
map("n", "<leader>cf", function()
  require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
end, { desc = "Format buffer" })

-- 診断
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- バッファ
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })

-- which-key ヘルプ
map("n", "<leader>?", function()
  require("which-key").show({ keys = "<leader>", loop = true })
end, { desc = "Leader keymaps" })
