return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = { "typescript", "javascript" }
      vscode.type_to_filetypes["pwa-node"] = { "typescript", "javascript" }

      -- Explicit attach configs that bypass resolveSourceMapLocations issues
      local root = vim.fn.getcwd()
      local attach_configs = {
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach arq (9233)",
          port = 9233,
          restart = true,
          continueOnAttach = true,
          timeout = 30000,
          sourceMaps = true,
          outFiles = { root .. "/apps/arq/dist/**/*.js" },
          resolveSourceMapLocations = { root .. "/**", "!**/node_modules/**" },
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          cwd = root .. "/apps/arq",
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach backend (9234)",
          port = 9234,
          restart = true,
          continueOnAttach = true,
          timeout = 30000,
          sourceMaps = true,
          outFiles = { root .. "/apps/backend/dist/**/*.js" },
          resolveSourceMapLocations = { root .. "/**", "!**/node_modules/**" },
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          cwd = root .. "/apps/backend",
        },
      }

      for _, lang in ipairs({ "typescript", "javascript" }) do
        dap.configurations[lang] = dap.configurations[lang] or {}
        for _, config in ipairs(attach_configs) do
          table.insert(dap.configurations[lang], 1, config)
        end
      end
    end,
  },
}
