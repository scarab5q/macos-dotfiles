return {
  {
    url = "https://codeberg.org/andyg/leap.nvim.git",
    lazy = false,
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap)")
    end,
  },

  -- which-key overrides
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "gs", desc = "Leap bidirectional", mode = { "n", "x", "o" } },
        { "<leader>fe", group = "config" },
      },
    },
  },
}
