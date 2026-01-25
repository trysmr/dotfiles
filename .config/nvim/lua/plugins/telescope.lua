return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files)  -- ファイル検索
      vim.keymap.set("n", "<leader>fg", builtin.live_grep)   -- 文字列検索
      vim.keymap.set("n", "<leader>fb", builtin.buffers)     -- 開いてるファイル一覧
    end,
  },
}
