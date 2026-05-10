-- Monorepo: show the path-from-root in lualine, so it's obvious whether
-- a file lives in apps/arq, apps/backend, etc. (Root detection itself is
-- pinned to .git in lua/config/options.lua via vim.g.root_spec.)

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      for _, section in ipairs({ "lualine_b", "lualine_c" }) do
        for _, comp in ipairs(opts.sections[section] or {}) do
          if comp[1] == "filename" then
            comp.path = 1 -- relative path from cwd/root
            comp.shorting_target = 60
          end
        end
      end
    end,
  },
}
