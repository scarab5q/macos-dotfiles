return {
  "Hashino/doing.nvim",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>oda", function() require("doing").add() end, desc = "[D]oing: [A]dd" },
    { "<leader>odn", function() require("doing").done() end, desc = "[D]oing: Do[n]e" },
    { "<leader>ode", function() require("doing").edit() end, desc = "[D]oing: [E]dit" },
  },
}
