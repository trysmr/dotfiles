return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>ee", "<cmd>Neotree toggle<cr>", desc = "Toggle explorer" },
    { "<leader>ef", "<cmd>Neotree reveal<cr>", desc = "Reveal in explorer" },
  },
  opts = {
    filesystem = {
      filtered_items = { visible = true },
      follow_current_file = { enabled = true },
    },
    window = { width = 30 },
  },
}
