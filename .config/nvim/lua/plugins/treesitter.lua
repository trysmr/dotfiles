return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    local languages = {
      "bash",
      "css",
      "go", "gomod", "gosum",
      "html",
      "javascript", "json",
      "lua",
      "markdown", "markdown_inline",
      "python",
      "ruby",
      "rust",
      "toml",
      "tsx", "typescript",
      "vim", "vimdoc",
      "yaml",
    }

    require("nvim-treesitter").setup()
    require("nvim-treesitter").install(languages)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitterHighlight", { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitterIndent", { clear = true }),
      pattern = { "lua", "go", "ruby", "rust", "python", "typescript", "javascript", "markdown", "yaml", "json", "bash" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
