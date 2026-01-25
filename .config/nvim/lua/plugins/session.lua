return {
  "folke/persistence.nvim",
  lazy = false, -- 起動時に即座にロード
  config = function()
    require("persistence").setup({
      dir = vim.fn.stdpath("state") .. "/sessions/",
      need = 1,
      -- NvimTreeなど特殊なバッファを除外
      options = { "buffers", "curdir", "tabpages", "winsize" },
    })

    -- NvimTreeを閉じるヘルパー関数
    local function close_nvim_tree()
      local nvim_tree_ok, nvim_tree_api = pcall(require, "nvim-tree.api")
      if nvim_tree_ok then
        nvim_tree_api.tree.close()
      end
    end

    -- セッション保存前にNvimTreeを閉じる
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("PersistenceNvimTree", { clear = true }),
      callback = function()
        close_nvim_tree()
      end,
    })

    -- キーマップ（起動直後から使える）
    vim.keymap.set("n", "<leader>ss", function()
      require("persistence").load()
    end, { desc = "Restore session (current dir)" })

    vim.keymap.set("n", "<leader>sl", function()
      require("persistence").load({ last = true })
    end, { desc = "Restore last session" })

    vim.keymap.set("n", "<leader>sd", function()
      require("persistence").stop()
    end, { desc = "Don't save session" })

    vim.keymap.set("n", "<leader>sS", function()
      close_nvim_tree()
      require("persistence").save()
    end, { desc = "Save session now" })

    -- 引数なし、またはディレクトリのみでnvimを起動した場合、自動でセッション復元
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("PersistenceAutoLoad", { clear = true }),
      nested = true,
      callback = function()
        -- 標準入力からの起動は除外
        if vim.g.started_with_stdin then
          return
        end

        -- 引数なし、または引数がカレントディレクトリ（.）のみの場合
        local should_restore = false
        if vim.fn.argc() == 0 then
          should_restore = true
        elseif vim.fn.argc() == 1 then
          local arg = vim.fn.argv(0)
          -- 引数がディレクトリの場合は復元
          if vim.fn.isdirectory(arg) == 1 then
            should_restore = true
          end
        end

        if should_restore then
          -- 少し遅延させて確実に読み込む
          vim.defer_fn(function()
            require("persistence").load()
          end, 50)
        end
      end,
    })

    -- 標準入力からの起動を検出
    vim.api.nvim_create_autocmd("StdinReadPre", {
      callback = function()
        vim.g.started_with_stdin = true
      end,
    })
  end,
}
