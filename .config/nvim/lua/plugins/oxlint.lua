--- Find a binary in the nearest node_modules/.bin, falling back to global PATH.
local function node_bin(name)
  return function()
    local root = vim.fs.root(0, "node_modules")
    if root then
      local local_bin = root .. "/node_modules/.bin/" .. name
      if vim.uv.fs_stat(local_bin) then
        return local_bin
      end
    end
    return name
  end
end

return {
  -- Disable eslint-lsp (was from the removed LazyVim eslint extra)
  { "neovim/nvim-lspconfig", opts = { servers = { eslint = false } } },

  -- Format with oxfmt for JS/TS files
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        json = { "oxfmt" },
      },
      formatters = {
        oxfmt = {
          command = node_bin("oxfmt"),
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
        },
      },
    },
  },

  -- Lint with oxlint for JS/TS files
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")

      -- Register custom oxlint linter
      lint.linters.oxlint = {
        cmd = node_bin("oxlint"),
        args = { "--format", "unix" },
        stdin = false,
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.parser").from_pattern(
          "^([^:]+):(%d+):(%d+): (.+) %[(%a+)%/?",
          { "file", "lnum", "col", "message", "severity" },
          {
            severity = {
              error = vim.diagnostic.severity.ERROR,
              warning = vim.diagnostic.severity.WARN,
            },
          }
        ),
      }

      for ft, linters in pairs(opts.linters_by_ft) do
        lint.linters_by_ft[ft] = linters
      end
    end,
  },
}
