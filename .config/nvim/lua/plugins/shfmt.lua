return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "shfmt" } },
  },
}
