return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- ファイルアイコン
  },
  config = function()
    require("nvim-tree").setup({
      -- ディレクトリを開いた時の自動起動を無効化（セッション復元と競合するため）
      hijack_directories = {
        enable = false,
      },
      view = {
        width = 30,
        side = "left",
      },
      filters = {
        dotfiles = false, -- 隠しファイルも表示
      },
      git = {
        enable = true,
        ignore = false,
      },
      renderer = {
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
        },
      },
    })

    -- キーマップ
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    vim.keymap.set("n", "<leader>o", ":NvimTreeFocus<CR>", { silent = true })
  end,
}
