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

-- Copy file path to clipboard
map("n", "<leader>fy", function() vim.fn.setreg("+", vim.fn.expand("%:.")) end, { desc = "Yank file path" })

-- Yank "<path>:<start>-<end>" relative to git root, for sharing with Claude
local function yank_path_range(s, e)
  if s > e then s, e = e, s end
  local abs = vim.fn.expand("%:p")
  local root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " rev-parse --show-toplevel")[1]
  local rel = (vim.v.shell_error == 0 and root and abs:sub(1, #root + 1) == root .. "/")
    and abs:sub(#root + 2)
    or vim.fn.expand("%:.")
  local range = s == e and tostring(s) or (s .. "-" .. e)
  local result = rel .. ":" .. range
  vim.fn.setreg("+", result)
  vim.notify("Yanked: " .. result)
end

_G.YankPathRangeOp = function() yank_path_range(vim.fn.line("'["), vim.fn.line("']")) end

map("n", "<leader>yr", function()
  vim.o.operatorfunc = "v:lua.YankPathRangeOp"
  return "g@"
end, { expr = true, desc = "Yank path:range (text object)" })

map("n", "<leader>yrr", function()
  local l = vim.fn.line(".")
  yank_path_range(l, l)
end, { desc = "Yank path:range (current line)" })

map("x", "<leader>yr", function()
  yank_path_range(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end, { desc = "Yank path:range (visual)" })

-- Save current file
map("n", "<leader>fs", "<cmd>write<cr>", { desc = "Save file" })

-- Config actions (<leader>fe)
map("n", "<leader>fed", "<cmd>tabnew | tcd ~/.config/nvim<cr>", { desc = "Edit nvim config" })
map("n", "<leader>fer", "<cmd>restart<cr>", { desc = "Restart neovim" })

-- Undotree (built-in, 0.12)
vim.cmd("packadd nvim.undotree")
map("n", "<leader>uu", "<cmd>Undotree<cr>", { desc = "Undo tree" })

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
