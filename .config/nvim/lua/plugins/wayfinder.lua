return {
  {
    "error311/wayfinder.nvim",
    cmd = {
      "Wayfinder",
      "WayfinderTrailNext",
      "WayfinderTrailPrev",
      "WayfinderTrailOpen",
      "WayfinderTrailShow",
      "WayfinderTrailResume",
    },
    keys = {
      { "gwf", "<Plug>(WayfinderOpen)", desc = "Wayfinder: open" },
      { "gwn", "<Plug>(WayfinderTrailNext)", desc = "Wayfinder: Trail next" },
      { "gwp", "<Plug>(WayfinderTrailPrev)", desc = "Wayfinder: Trail prev" },
      { "gwo", "<Plug>(WayfinderTrailOpen)", desc = "Wayfinder: Trail open" },
      { "gws", "<Plug>(WayfinderTrailShow)", desc = "Wayfinder: Trail show" },
    },
    opts = {},
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "gw", group = "wayfinder" },
      },
    },
  },
}
