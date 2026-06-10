-- folke/sidekick.nvim — AI CLI sidebar.
-- Configured for `pi` (https://github.com/badlogic/pi-mono). Claude has its own
-- bindings under <leader>a* and yanky owns <leader>p, so this plugin lives
-- under <leader>i (mnemonic: "pi" / AI).
return {
  "folke/sidekick.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- No Copilot LSP configured in this nvim, so disable Next Edit Suggestions
    -- entirely — sidekick is purely the pi CLI terminal here.
    nes = { enabled = false },
    copilot = { status = { enabled = false } },
    cli = {
      watch = true,
      win = {
        layout = "right",
        split = { width = 90 },
      },
      -- Jack uses cmux (not zellij/tmux), so leave mux disabled and run pi
      -- inside a regular Neovim terminal buffer.
      mux = { enabled = false },
      tools = {
        pi = {
          -- Resolve pi explicitly: nvim launched outside a shell (e.g. from
          -- cmux) may not inherit nvm's PATH, so `executable("pi")` fails.
          -- Fall back to the latest nvm-installed pi shim.
          cmd = (function()
            local exe = vim.fn.exepath("pi")
            if exe ~= "" then return { exe } end
            -- Don't use vim.fn.expand on a glob pattern — it expands the glob
            -- itself and returns newline-joined matches. Resolve $HOME first.
            local home = os.getenv("HOME") or ""
            local matches = vim.fn.glob(home .. "/.nvm/versions/node/*/bin/pi", false, true)
            table.sort(matches) -- newest node version last
            return { matches[#matches] or "pi" }
          end)(),
        },
      },
    },
  },
  keys = {
    {
      "<leader>ip",
      function() require("sidekick.cli").toggle({ name = "pi", focus = true }) end,
      desc = "Pi: Toggle",
    },
    {
      "<leader>if",
      function() require("sidekick.cli").focus({ name = "pi" }) end,
      desc = "Pi: Focus",
    },
    {
      "<leader>ir",
      function() require("sidekick.cli").toggle({ name = "pi", focus = true, args = { "--resume" } }) end,
      desc = "Pi: Resume session",
    },
    {
      "<leader>iC",
      function() require("sidekick.cli").toggle({ name = "pi", focus = true, args = { "--continue" } }) end,
      desc = "Pi: Continue last session",
    },
    {
      "<leader>id",
      function() require("sidekick.cli").close({ name = "pi" }) end,
      desc = "Pi: Detach session",
    },
    -- Context sending
    {
      "<leader>it",
      function() require("sidekick.cli").send({ name = "pi", msg = "{this}" }) end,
      mode = { "n", "x" },
      desc = "Pi: Send {this}",
    },
    {
      "<leader>ib",
      function() require("sidekick.cli").send({ name = "pi", msg = "{file}" }) end,
      desc = "Pi: Send buffer",
    },
    {
      "<leader>iv",
      function() require("sidekick.cli").send({ name = "pi", msg = "{selection}" }) end,
      mode = "x",
      desc = "Pi: Send selection",
    },
    {
      "<leader>iP",
      function() require("sidekick.cli").prompt({ name = "pi" }) end,
      mode = { "n", "x" },
      desc = "Pi: Prompt picker",
    },
    -- Focus toggle (handy from terminal mode too)
    {
      "<c-.>",
      function() require("sidekick.cli").focus({ name = "pi" }) end,
      mode = { "n", "t", "i", "x" },
      desc = "Pi: Focus toggle",
    },
  },
}
