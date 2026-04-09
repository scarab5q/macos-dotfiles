return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "recent_files", cwd = true, limit = 8, padding = 1, title = "Recent Files" },
          { section = "startup" },
        },
      },
    },
  },
}
