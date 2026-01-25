return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false, -- 遅延読み込み非サポート
  build = ":TSUpdate",
  config = function()
    -- パーサーをインストール
    require("nvim-treesitter").install({
      "lua",
      "vim",
      "vimdoc",
      "bash",
      "json",
      "yaml",
      "markdown",
      "markdown_inline",
      "ruby",
      "go",
      "javascript",
      "typescript",
    })

    -- 全ファイルタイプでTreesitterハイライトを有効化
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Treesitterベースのインデント（実験的機能）
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "go", "ruby", "javascript", "typescript" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}

