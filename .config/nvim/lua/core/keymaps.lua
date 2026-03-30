local map = vim.keymap.set

-- 検索 (telescope)
map("n", "<leader>ff", function()
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
