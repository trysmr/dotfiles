return {
  "folke/tokyonight.nvim",
  lazy = false,    -- メインテーマは即時読み込み
  priority = 1000, -- 最優先で読み込み
  config = function()
    require("tokyonight").setup({
      style = "night", -- night, storm, day, moon から選択
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
