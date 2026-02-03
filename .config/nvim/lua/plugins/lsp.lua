-- LSP共通設定
-- Mason経由でLSPサーバーをインストールし、共通キーマップを設定
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local lspconfig = require("lspconfig")

    -- Mason: LSPサーバーのパッケージマネージャー
    require("mason").setup()
    require("mason-lspconfig").setup({
      -- 使用するLSPサーバーを自動インストール
      ensure_installed = {
        "gopls",     -- Go
        "ruby_lsp",  -- Ruby
        "lua_ls",    -- Lua（Neovim設定編集用）
      },
      -- LSPサーバーごとの設定
      handlers = {
        -- デフォルトハンドラー（設定なしのLSPサーバー用）
        function(server_name)
          lspconfig[server_name].setup({})
        end,

        -- Go (gopls)
        ["gopls"] = function()
          lspconfig.gopls.setup({
            settings = {
              gopls = {
                analyses = { unusedparams = true },
                staticcheck = true,
                gofumpt = true, -- より厳格なフォーマット
              },
            },
          })
        end,

        -- Ruby (ruby_lsp)
        ["ruby_lsp"] = function()
          lspconfig.ruby_lsp.setup({
            init_options = {
              formatter = "auto",
            },
          })
        end,

        -- Lua (lua_ls)
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" }, -- Neovim組み込みのvimグローバルを認識
                },
              },
            },
          })
        end,
      },
    })

    -- LSPがバッファにアタッチしたときの共通設定
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
      callback = function(args)
        local opts = { buffer = args.buf }

        -- ナビゲーション
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)

        -- ドキュメント
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

        -- リファクタリング
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        -- 診断
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
      end,
    })

    -- 診断表示の設定
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- 診断アイコンのカスタマイズ
    local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
  end,
}
