return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        move = {
          -- Disable the ; and , repeat keymaps
          goto_next_start = {},
          goto_next_end = {},
          goto_previous_start = {},
          goto_previous_end = {},
        },
      },
    },
    keys = function()
      -- Return empty to prevent LazyVim from setting up ; and , keymaps
      return {}
    end,
  },
}
