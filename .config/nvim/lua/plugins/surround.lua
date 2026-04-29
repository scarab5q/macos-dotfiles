return {

  -- Disable LazyVim's built-in mini.surround to avoid conflicts
  {
    "nvim-mini/mini.surround",
    enabled = false,
  },

  -- Install nvim-surround with vim-surround keybindings (defaults match what we want)
  {
    "kylechui/nvim-surround",
    version = "*",
    lazy = false,
    opts = {},
  },
}
