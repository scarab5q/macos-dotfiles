return {

  -- Disable LazyVim's built-in mini.surround to avoid conflicts
  { "echasnovski/mini.surround", enabled = false },

  -- Install nvim-surround with vim-surround keybindings
  {
    "kylechui/nvim-surround",
    version = "*",
    lazy = false, -- Load immediately, don't lazy load
    config = function()
      require("nvim-surround").setup({
        keymaps = {
          insert = "<C-g>s",
          insert_line = "<C-g>S",
          normal = "ys",
          normal_cur = "yss",
          normal_line = "yS",
          normal_cur_line = "ySS",
          visual = "S",
          visual_line = "gS",
          delete = "ds",
          change = "cs",
          change_line = "cS",
        },
      })
    end,
  },
}
