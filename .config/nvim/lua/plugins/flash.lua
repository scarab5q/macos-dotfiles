return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        -- Disable flash in normal search
        search = { enabled = false },
        -- Disable s/S char mode (frees s for leap/surround)
        char = { enabled = false },
      },
    },
    -- Only keep remote flash (r) and treesitter search (R) in operator-pending
    -- stylua: ignore
    keys = {
      { "s", false },
      { "S", false },
      { "<c-space>", false },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
}
