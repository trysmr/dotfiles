return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  keys = {
    { "<leader>dw", "<cmd>Trouble diagnostics toggle<cr>",              desc = "Workspace diagnostics" },
    { "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
    { "<leader>dl", "<cmd>Trouble lsp toggle<cr>",                      desc = "LSP references/definitions" },
  },
  opts = {},
}
