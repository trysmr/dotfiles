return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      offsets = {
        { filetype = "neo-tree", text = "Explorer", highlight = "Directory" },
      },
      show_close_icon = false,
      separator_style = "thin",
    },
  },
  keys = {
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    {
      "<leader>bd",
      function()
        local buf = vim.api.nvim_get_current_buf()
        vim.cmd("BufferLineCyclePrev")
        -- 同じバッファに戻った場合（最後の1つ）は新規バッファを作る
        if vim.api.nvim_get_current_buf() == buf then
          vim.cmd("enew")
        end
        vim.cmd("bdelete " .. buf)
      end,
      desc = "Close buffer"
    },
  },
}
