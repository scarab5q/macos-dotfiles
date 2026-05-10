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
