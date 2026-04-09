return {
  {
    "nvim-mini/mini.ai",
    opts = {
      mappings = {
        -- Remap next/last to free an/in for built-in treesitter node selection (0.12)
        around_next = "aN",
        inside_next = "iN",
        around_last = "aL",
        inside_last = "iL",
      },
    },
  },
}
