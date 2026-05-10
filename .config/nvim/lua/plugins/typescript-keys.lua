-- Extra TS code-action keymaps that LazyVim's typescript extra doesn't ship by default.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.vtsls = opts.servers.vtsls or {}
      local keys = opts.servers.vtsls.keys or {}
      vim.list_extend(keys, {
        { "<leader>co", LazyVim.lsp.action["source.organizeImports"], desc = "Organize Imports" },
        { "<leader>cu", LazyVim.lsp.action["source.removeUnused.ts"], desc = "Remove Unused Imports" },
      })
      opts.servers.vtsls.keys = keys
    end,
  },
}
