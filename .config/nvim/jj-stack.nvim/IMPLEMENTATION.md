# jj-stack.nvim — implementation notes

A Neovim sidebar plugin for Jujutsu. Fills the gap left by `jj.nvim` +
`diffview.nvim`: a **persistent, always-visible** two-pane sidebar showing
(top) the commit stack around `@`, (bottom) the files in the selected commit.
Auto-refreshes on every jj op.

See the full plan at
`~/.claude/plans/i-want-to-create-snappy-beacon.md` for context, keybinds,
architecture, and verification steps.

---

## Target sidebar layout

```
┌─────────────────────────────┐
│ STACK (jj log @-::@+)       │
│ ○  xyzw  fix shift poll...  │
│ @  abcd  wip payout refac   │  ← selected
│ ○  efgh  add retry logic    │
│ ○  ijkl  dev@origin         │
├─────────────────────────────┤
│ FILES IN abcd (4)           │
│  M  apps/backend/src/...    │
│  M  apps/backend/test/...   │
│  A  apps/backend/scripts/.. │
│  D  packages/arq-db/...     │
└─────────────────────────────┘
```

---

## Initial UI scaffold — build in this order

The first two steps are about an hour and give you a stable empty shell you
can iterate on. Everything after is "fetch → format → `set_lines` →
highlight."

### 1. Plugin scaffold

```
~/.config/nvim/jj-stack.nvim/
├── lua/jj-stack/
│   ├── init.lua        -- setup(), toggle(), open(), close()
│   └── sidebar.lua     -- window/buffer creation
└── lua/plugins/jj-stack.lua   -- lazy spec (points at local dir)
```

Mirror `claude-yank.nvim`'s lazy-spec pattern:

```lua
-- ~/.config/nvim/lua/plugins/jj-stack.lua
return {
  dir = vim.fn.stdpath('config') .. '/jj-stack.nvim',
  name = 'jj-stack',
  config = function() require('jj-stack').setup() end,
  keys = {
    { '<leader>js', function() require('jj-stack').toggle() end, desc = 'Toggle jj stack' },
  },
}
```

### 2. Create the buffer (scratch, not file-backed)

```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].buftype = 'nofile'
vim.bo[buf].bufhidden = 'hide'
vim.bo[buf].swapfile = false
vim.bo[buf].filetype = 'jjstack'    -- custom, gives us a handle for hl/ftplugin
vim.bo[buf].modifiable = false      -- flip true only when rewriting
```

### 3. Open a docked side window

`topleft vsplit` guarantees it lives at the absolute left edge regardless of
current layout.

```lua
vim.cmd('topleft vsplit')
vim.cmd('vertical resize 40')
local win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(win, buf)

-- window-local options that make it *feel* like a sidebar
for opt, val in pairs({
  winfixwidth = true,  number = false,      relativenumber = false,
  signcolumn  = 'no',  foldcolumn = '0',    cursorline    = true,
  wrap        = false, list       = false,
}) do vim.wo[win][opt] = val end
```

### 4. Split it horizontally for the two panes

With the sidebar window focused, `split` then `resize 15`. Create a second
scratch buffer for the bottom pane.

```lua
-- inside the sidebar window:
vim.cmd('split')
vim.cmd('resize 15')  -- top pane ~15 rows, rest for files
-- then create + attach a second scratch buffer the same way as step 2
```

### 5. Store handles + implement `close()`

```lua
M.state = { stack_buf, stack_win, files_buf, files_win }

function M.close()
  for _, w in ipairs({ M.state.stack_win, M.state.files_win }) do
    if w and vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end
  end
  for _, b in ipairs({ M.state.stack_buf, M.state.files_buf }) do
    if b and vim.api.nvim_buf_is_valid(b) then vim.api.nvim_buf_delete(b, { force = true }) end
  end
  M.state = nil
end

function M.toggle()
  if M.state and vim.api.nvim_win_is_valid(M.state.stack_win) then M.close()
  else M.open() end
end
```

### 6. Render placeholder content (milestone!)

Before wiring any jj logic:

```lua
vim.bo[buf].modifiable = true
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'STACK', '', '  (empty)' })
vim.bo[buf].modifiable = false
```

**This is the milestone to hit first** — toggleable two-pane sidebar with
fake content. Once the chrome toggles cleanly and doesn't break other
splits, everything else is mechanical.

### 7. Highlights

Define groups in `hl.lua` linked to existing LazyVim groups. Apply via
extmarks (they survive line rewrites better than `nvim_buf_add_highlight`).

```lua
vim.api.nvim_set_hl(0, 'JjStackCurrent',    { link = 'Special' })
vim.api.nvim_set_hl(0, 'JjStackImmutable',  { link = 'Comment' })
vim.api.nvim_set_hl(0, 'JjStackAdded',      { link = 'DiffAdd' })
vim.api.nvim_set_hl(0, 'JjStackModified',   { link = 'DiffChange' })
vim.api.nvim_set_hl(0, 'JjStackDeleted',    { link = 'DiffDelete' })

-- apply:
local ns = vim.api.nvim_create_namespace('jjstack')
vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
  end_col = col_end, hl_group = 'JjStackCurrent',
})
```

### 8. Buffer-local keybinds

Scope to the buffer so they only fire inside the sidebar:

```lua
vim.keymap.set('n', 'q', M.close,     { buffer = buf, nowait = true })
vim.keymap.set('n', 'd', open_diff,   { buffer = buf, nowait = true })
vim.keymap.set('n', '<CR>', open_file,{ buffer = buf, nowait = true })
-- etc.
```

---

## Build milestones (what to aim for)

1. **Empty toggleable chrome** — opens, closes, doesn't mess up other splits
2. **Static fake data rendered** — highlights + layout look right
3. **Real `jj log` / `jj diff --summary` output** — reflects `@`
4. **Autocmd + `vim.uv.fs_event_start` watcher on `.jj/repo/op_heads/heads/`**
   — edits in a terminal pane update the sidebar live
5. **Functional keybinds** — `<CR>`, `d`, `D`, `e` — you actually want to use it

---

## Commands to remember

| Need | Command |
|------|---------|
| Stack list | `jj log -r '@-::@+' --template '<custom>' --no-graph --no-pager` |
| Files in commit | `jj diff --summary -r <commit> --no-pager` |
| File content at commit | `jj file show -r <commit> <path>` |
| Whole-commit diff | Delegate: `require('diffview').open({ '<commit>^!' })` |

All invocations via `vim.system()` async, debounced ~100ms.

---

## Reference plugins to crib from

- `~/.config/nvim/claude-yank.nvim/lua/claude-yank/init.lua` — local plugin
  layout, lazy keybinds, minimal public API surface
- `jjtrack.nvim` (GitHub) — `op_heads` fs_event pattern
- `jj.nvim` (GitHub, NicolasGB) — `jj log --template` syntax and rendering
- `diffview.nvim` — Lua API for the diff handoff
