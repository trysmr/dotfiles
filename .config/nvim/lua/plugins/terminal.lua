return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<leader>tt", desc = "Toggle terminal" },
    { "<leader>tf", desc = "Float terminal" },
    { "<leader>th", desc = "Horizontal terminal" },
    { "<leader>tv", desc = "Vertical terminal" },
    { "<leader>tg", desc = "Lazygit" },
  },
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<leader>tt]],
      hide_numbers = true,
      shade_terminals = true,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    })

    -- ターミナルモードでEscでNormalモードに
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true })
    vim.keymap.set("t", "<C-w>h", [[<C-\><C-n><C-w>h]], { noremap = true })
    vim.keymap.set("t", "<C-w>j", [[<C-\><C-n><C-w>j]], { noremap = true })
    vim.keymap.set("t", "<C-w>k", [[<C-\><C-n><C-w>k]], { noremap = true })
    vim.keymap.set("t", "<C-w>l", [[<C-\><C-n><C-w>l]], { noremap = true })

    local Terminal = require("toggleterm.terminal").Terminal

    -- 各方向のターミナルインスタンスを事前作成（再利用される）
    local float_term = Terminal:new({
      direction = "float",
      hidden = true,
    })

    local horizontal_term = Terminal:new({
      direction = "horizontal",
      hidden = true,
    })

    local vertical_term = Terminal:new({
      direction = "vertical",
      hidden = true,
    })

    local lazygit = Terminal:new({
      cmd = "lazygit",
      direction = "float",
      hidden = true,
      float_opts = { border = "curved" },
      on_open = function(term)
        -- lazygitではEscをそのまま使う（Escでノーマルモードに戻らない）
        vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, noremap = true })
      end,
    })

    -- キーマップ（同じインスタンスを再利用）
    vim.keymap.set("n", "<leader>tf", function()
      float_term:toggle()
    end, { desc = "Float terminal" })

    vim.keymap.set("n", "<leader>th", function()
      horizontal_term:toggle()
    end, { desc = "Horizontal terminal" })

    vim.keymap.set("n", "<leader>tv", function()
      vertical_term:toggle()
    end, { desc = "Vertical terminal" })

    vim.keymap.set("n", "<leader>tg", function()
      lazygit:toggle()
    end, { desc = "Lazygit" })
  end,
}
