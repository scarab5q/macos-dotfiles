-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Delete any existing ; and : mappings first to ensure our swap takes precedence
pcall(vim.keymap.del, "n", ";")
pcall(vim.keymap.del, "n", ",")

map("n", ";", ":", { desc = "Command mode" })
map("n", ":", ";", { desc = "Repeat f/t" })
map("n", "U", "<c-r>")
map("n", "Q", "@q")

-- Find files in dotfiles (bare git repo at ~/.cfg)
map("n", "<leader>Cf", function()
  Snacks.picker.files({
    cmd = "git",
    args = {
      "--git-dir=" .. os.getenv("HOME") .. "/.cfg",
      "--work-tree=" .. os.getenv("HOME"),
      "ls-files",
    },
    cwd = os.getenv("HOME"),
    title = "Dotfiles",
  })
end, { desc = "Find dotfiles" })
