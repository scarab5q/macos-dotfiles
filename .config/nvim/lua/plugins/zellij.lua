return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      {
        "<c-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "navigate left",
      },
      {
        "<c-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "navigate down",
      },
      {
        "<c-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "navigate up",
      },
      {
        "<c-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "navigate right",
      },
    },
    opts = {
      at_edge = "stop",
    },
  },
}
