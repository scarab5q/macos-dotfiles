return {
  {
    "tpope/vim-abolish",
    event = "VeryLazy",
    config = function()
      local function split_words(s)
        s = s:gsub("(%l)(%u)", "%1 %2")
        s = s:gsub("(%u)(%u%l)", "%1 %2")
        s = s:gsub("[_%-%.]", " ")
        local words = {}
        for w in s:gmatch("%S+") do
          table.insert(words, w:lower())
        end
        return words
      end

      local function title(w)
        return w:sub(1, 1):upper() .. w:sub(2)
      end

      local transforms = {
        s = function(s) return table.concat(split_words(s), "_") end,
        ["-"] = function(s) return table.concat(split_words(s), "-") end,
        ["."] = function(s) return table.concat(split_words(s), ".") end,
        [" "] = function(s) return table.concat(split_words(s), " ") end,
        u = function(s) return table.concat(split_words(s), "_"):upper() end,
        U = function(s) return table.concat(split_words(s), "_"):upper() end,
        c = function(s)
          local ws = split_words(s)
          if #ws == 0 then return s end
          local out = ws[1]
          for i = 2, #ws do out = out .. title(ws[i]) end
          return out
        end,
        m = function(s)
          local out = ""
          for _, w in ipairs(split_words(s)) do out = out .. title(w) end
          return out
        end,
        t = function(s)
          local ws = split_words(s)
          for i, w in ipairs(ws) do ws[i] = title(w) end
          return table.concat(ws, " ")
        end,
      }

      local function apply(fn)
        return function()
          local save, save_type = vim.fn.getreg("z"), vim.fn.getregtype("z")
          vim.cmd('noautocmd normal! gv"zy')
          vim.fn.setreg("z", fn(vim.fn.getreg("z")))
          vim.cmd('noautocmd normal! gv"zp')
          vim.fn.setreg("z", save, save_type)
        end
      end

      for key, fn in pairs(transforms) do
        vim.keymap.set("x", "cr" .. key, apply(fn), { desc = "Coerce selection (" .. key .. ")" })
      end

      vim.keymap.set("x", "<leader>S", [[:S/\%V]], { desc = "Subvert within selection" })
    end,
  },
}
