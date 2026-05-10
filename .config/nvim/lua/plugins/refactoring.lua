-- refactoring.nvim's recent rewrite (commit 6d75b14, "follow latests async.nvim
-- changes") moved its async helpers out into lewis6991/async.nvim. The
-- LazyVim extra hasn't been updated to declare that dep yet, so loading the
-- plugin fails with: module 'async' not found.
return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "lewis6991/async.nvim" },
  },
}
