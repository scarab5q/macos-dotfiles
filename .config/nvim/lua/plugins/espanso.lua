return {
  "Danielhp95/espanso-nvim",
  ft = "yaml",
  cond = function()
    local path = vim.api.nvim_buf_get_name(0)
    return path:find("espanso") ~= nil
  end,
  opts = {},
}
