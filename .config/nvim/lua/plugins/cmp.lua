return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter", -- 挿入モードに入ったら読み込み
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- LSPからの補完
    "hrsh7th/cmp-buffer",   -- バッファ内の単語
    "hrsh7th/cmp-path",     -- ファイルパス
    "L3MON4D3/LuaSnip",     -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item(),     -- 次の候補
        ["<C-p>"] = cmp.mapping.select_prev_item(),     -- 前の候補
        ["<C-Space>"] = cmp.mapping.complete(),         -- 補完を開始
        ["<C-e>"] = cmp.mapping.abort(),                -- 補完を閉じる
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- 決定
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      -- 優先度グループ: 第1グループがなければ第2グループを使用
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- LSP補完（最優先）
        { name = "luasnip" },  -- スニペット
      }, {
        { name = "buffer" },   -- バッファ内単語（フォールバック）
        { name = "path" },     -- ファイルパス
      }),
    })
  end,
}
