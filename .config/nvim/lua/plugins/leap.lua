return {
  {
    url = "https://codeberg.org/andyg/leap.nvim.git",
    lazy = false,
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      -- `S` is intentionally normal+op-pending only; visual-mode `S` belongs to
      -- nvim-surround (surround the visual selection).
      vim.keymap.set({ "n", "o" }, "S", "<Plug>(leap-backward)")
      vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)")
    end,
  },

  -- which-key overrides
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "s", desc = "Leap forward", mode = { "n", "x", "o" } },
        { "S", desc = "Leap backward", mode = { "n", "o" } },
        { "gs", desc = "Leap from window", mode = { "n", "x", "o" } },
        { "<leader>fe", group = "config" },
      },
    },
  },
}
