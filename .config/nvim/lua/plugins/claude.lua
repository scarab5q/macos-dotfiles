return {
  -- Auto-reload buffers when Claude (or anything) writes files externally
  { "manuuurino/autoread.nvim", event = "VeryLazy", config = true },

  -- Claude Code IDE integration (terminal commands only; nvim tools come from neovim-yank server)
  {
    "coder/claudecode.nvim",
    lazy = false,
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("claudecode").setup({
        auto_start = true, -- WS server for diff display; yank server handles connection/nvim tools
        terminal = {
          cwd_provider = function(ctx)
            local dir = ctx.file_dir or vim.fn.getcwd()
            local found = vim.fn.findfile("package.json", dir .. ";")
            return found ~= "" and vim.fn.fnamemodify(found, ":h") or dir
          end,
        },
      })

      -- Patch lockfile to use a descriptive ideName
      local lockfile = require("claudecode.lockfile")
      local _orig_create = lockfile.create
      lockfile.create = function(port, auth_token)
        local success, path, token = _orig_create(port, auth_token)
        if success then
          local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          local file = io.open(path, "r")
          if file then
            local content = file:read("*all")
            file:close()
            local ok, data = pcall(vim.json.decode, content)
            if ok and data then
              data.ideName = "Neovim · " .. project
              local wf = io.open(path, "w")
              if wf then
                wf:write(vim.json.encode(data))
                wf:close()
              end
            end
          end
        end
        return success, path, token
      end
    end,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },

  -- Yank code with context + session picker → neovim-yank channel server
  {
    dir = vim.fn.stdpath("config") .. "/claude-yank.nvim",
    name = "claude-yank",
    lazy = false,
    config = function()
      local cy = require("claude-yank")
      cy.setup()

      -- Lualine component
      local ok, lualine = pcall(require, "lualine")
      if ok then
        local cfg = lualine.get_config()
        if cfg and cfg.sections and cfg.sections.lualine_x then
          table.insert(cfg.sections.lualine_x, 1, {
            function()
              local s = cy.session()
              local dot = cy.is_connected() and "●" or "○"
              return "󱙺 " .. dot .. (s and (" " .. s.nvimId) or "")
            end,
            cond = function() return cy.session() ~= nil end,
            color = "lualine_a_normal",
            separator = { left = "", right = "" },
            padding = { left = 1, right = 1 },
          })
          lualine.setup(cfg)
        end
      end
    end,
    keys = {
      { "<leader>aS", function() require("claude-yank").pick_session() end, desc = "Select Claude session" },
      { "<leader>ay", function() require("claude-yank").yank("visual") end, mode = "v", desc = "Yank with file context" },
      {
        "<leader>ay",
        function()
          _G._claude_yank_op = function(type) require("claude-yank").yank(type) end
          vim.opt.operatorfunc = "v:lua._claude_yank_op"
          return "g@"
        end,
        expr = true,
        desc = "Yank text object with context",
      },
    },
  },
}
