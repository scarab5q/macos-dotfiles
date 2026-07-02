return {
  -- Nushell built-in language server (`nu --lsp`)
  { "neovim/nvim-lspconfig", opts = { servers = { nushell = {} } } },

  -- Format with nufmt (reads stdin, writes stdout)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { nu = { "nufmt" } },
      formatters = {
        nufmt = {
          command = "nufmt",
          args = { "--stdin" },
          stdin = true,
        },
      },
    },
  },
}
