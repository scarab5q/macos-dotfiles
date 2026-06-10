return {
  {
    "mfussenegger/nvim-dap",
    -- All node debug configs live in the repo's .vscode/launch.json (shared with VS Code).
    -- LazyVim's typescript + dap.core extras already register the js-debug adapter
    -- (node/pwa-node) and a comment-tolerant json_decode, so we only load the file.
    opts = function()
      local js = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      pcall(function()
        require("dap.ext.vscode").load_launchjs(nil, { node = js, ["pwa-node"] = js })
      end)
    end,
  },
}
