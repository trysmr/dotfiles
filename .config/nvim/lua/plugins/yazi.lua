-- yazi.nvim - Neovim内からyaziを起動するプラグイン
-- nvim-treeと共存し、用途で使い分け：
--   nvim-tree: 軽量なファイル選択
--   yazi: プレビュー付きの本格的なファイル操作

return {
  "mikavilpas/yazi.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>y", "<cmd>Yazi<cr>", desc = "Yazi" },
  },
  opts = {
    -- nvim-treeと共存するため、ディレクトリを開いてもyaziは起動しない
    open_for_directories = false,

    -- フローティングウィンドウの設定
    floating_window_scaling_factor = 0.9,

    -- yaziが選択したファイルを開く方法
    yazi_floating_window_border = "rounded",

    -- yaziプロセス終了後の挙動
    hooks = {
      -- yaziでファイルを選択した後のコールバック
      yazi_opened = function(preselected_path, yazi_buffer_id, config)
        -- yaziが開かれた時の処理（必要に応じてカスタマイズ）
      end,
      yazi_closed_successfully = function(chosen_file, config, state)
        -- yaziが正常に閉じられた時の処理（必要に応じてカスタマイズ）
      end,
    },
  },
}
