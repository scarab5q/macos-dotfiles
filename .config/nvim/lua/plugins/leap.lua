return {
  {
    "ggandor/leap.nvim",
    keys = {
      { "gs", mode = { "n", "x", "o" }, desc = "Leap bidirectional" },
    },
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap)")
    end,
  },
}
