-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Monorepo: prefer .git as project root over LSP, so file pickers search the
-- entire repo instead of just apps/arq, apps/backend, etc.
vim.g.root_spec = { { ".git" }, "lsp", "cwd" }
