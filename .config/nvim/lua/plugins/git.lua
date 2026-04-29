return {
  {
    "NicolasGB/jj.nvim",
    cmd = "J",
    keys = {
      { "<leader>jj", "<CMD>J log<CR>", desc = "jj log" },
      { "<leader>js", "<CMD>J status<CR>", desc = "jj status" },
      { "<leader>jd", "<CMD>J describe<CR>", desc = "jj describe" },
      { "<leader>jb", "<CMD>J bookmark list<CR>", desc = "jj bookmarks" },
    },
    opts = {
      diff = {
        module = "diffview",
      },
      terminal = {
        window = { type = "hsplit" },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    opts = {
      -- or "fzf-lua" or "snacks" or "default"
      picker = "telescope",
      -- bare Octo command opens picker of commands
      enable_builtin = true,
    },
    keys = {
      {
        "<leader>oi",
        "<CMD>Octo issue list<CR>",
        desc = "List GitHub Issues",
      },
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List GitHub PullRequests",
      },
      {
        "<leader>od",
        "<CMD>Octo discussion list<CR>",
        desc = "List GitHub Discussions",
      },
      {
        "<leader>on",
        "<CMD>Octo notification list<CR>",
        desc = "List GitHub Notifications",
      },
      {
        "<leader>os",
        function()
          require("octo.utils").create_base_search_command({ include_current_repo = true })
        end,
        desc = "Search GitHub",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- OR "ibhagwan/fzf-lua",
      -- OR "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "rafikdraoui/jj-diffconflicts",
    cmd = { "JJDiffConflicts" },
  },
  {
    "Spiegie/jj-conflict-highlight.nvim",
    version = "*",
    event = "BufReadPost",
    opts = {},
    keys = {
      {
        "]c",
        function()
          -- jj conflict markers: <<<<<<<, |||||||, %%%%%%%, +++++++, =======, >>>>>>>
          vim.fn.search([[^\(<<<<<<<\|>>>>>>>\|=======\|>>>>>>>\||||||||\|%%%%%%%\|+++++++\)]], "W")
        end,
        desc = "Next conflict marker",
      },
      {
        "[c",
        function()
          vim.fn.search([[^\(<<<<<<<\|>>>>>>>\|=======\|>>>>>>>\||||||||\|%%%%%%%\|+++++++\)]], "bW")
        end,
        desc = "Prev conflict marker",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<CMD>DiffviewOpen<CR>", desc = "Diffview Open" },
      { "<leader>gf", "<CMD>DiffviewFileHistory %<CR>", desc = "File History" },
      { "<leader>gF", "<CMD>DiffviewFileHistory<CR>", desc = "Branch History" },
    },
    opts = {},
  },
}
