return {
  {
    "jinzhongjia/zig-lamp",
    ft = "zig",
    build = ":ZigLampBuild async",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    init = function()
      vim.g.zig_lamp_zls_auto_install = 30000
      vim.g.zig_lamp_fall_back_sys_zls = 1
    end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "zig",
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
          end

          local ok, wk = pcall(require, "which-key")
          if ok then
            wk.add({ { "<leader>cz", group = "zls", buffer = ev.buf } })
          end

          map("<leader>cb", "<cmd>ZigLamp build<cr>", "Zig: Build")
          map("<leader>ct", "<cmd>ZigLamp test<cr>", "Zig: Test")
          map("<leader>cx", "<cmd>ZigLamp clean<cr>", "Zig: Clean")
          map("<leader>cp", "<cmd>ZigLamp pkg<cr>", "Zig: Package panel")
          map("<leader>ci", "<cmd>ZigLamp info<cr>", "Zig: Info")
          map("<leader>ch", "<cmd>ZigLamp health<cr>", "Zig: Health check")

          map("<leader>czi", "<cmd>ZigLamp zls install<cr>", "Zig: ZLS install")
          map("<leader>czs", "<cmd>ZigLamp zls status<cr>", "Zig: ZLS status")
          map("<leader>czu", function()
            vim.ui.input({ prompt = "ZLS version to uninstall: " }, function(v)
              if v and v ~= "" then vim.cmd("ZigLamp zls uninstall " .. v) end
            end)
          end, "Zig: ZLS uninstall")
        end,
      })
    end,
  },

}
