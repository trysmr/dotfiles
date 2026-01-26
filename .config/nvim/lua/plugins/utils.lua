return {
  -- 括弧の自動補完
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true, -- Treesitter連携
      })
      -- nvim-cmpと連携
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- コメントトグル
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment line" },
      { "gc", mode = { "n", "v" }, desc = "Comment" },
    },
    config = function()
      require("Comment").setup()
    end,
  },

  -- キーバインドヘルプ
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        delay = 500, -- 500ms後に表示
      })
      -- キーグループの説明を登録
      wk.add({
        { "<leader>a", group = "AI (Claude)" },
        { "<leader>e", desc = "Explorer toggle" },
        { "<leader>f", group = "Find (Telescope)" },
        { "<leader>g", group = "Git" },
        { "<leader>o", desc = "Explorer focus" },
        { "<leader>q", group = "Quit" },
        { "<leader>r", group = "Refactor" },
        { "<leader>s", group = "Session" },
        { "<leader>t", group = "Terminal" },
        { "<leader>d", desc = "Diagnostic float" },
        { "<leader>y", desc = "Yazi" },
      })
    end,
  },

  -- インデントガイド
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = true },
      })
    end,
  },
}
