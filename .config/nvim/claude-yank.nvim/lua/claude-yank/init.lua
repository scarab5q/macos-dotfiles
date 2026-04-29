-- claude-yank.nvim — Neovim ↔ Claude Code channel integration
-- Yank code with file context to a Claude session, pick sessions,
-- and auto-connect neovim so Claude gets nvim_* MCP tools.
--
-- Communication uses Unix domain sockets with per-instance bearer tokens.
-- No TCP ports exposed, no shared token files.

local M = {}

M.config = {
  channel_dir = vim.fn.expand("~/.claude/channels/neovim-yank"),
}

-- ── State ──────────────────────────────────────────────────────────

--- @class ClaudeSession
--- @field socketPath string  Unix domain socket path
--- @field secret string      Per-instance bearer token
--- @field nvimId string

--- @type ClaudeSession?
M._session = nil
M._connected = false

function M.is_connected() return M._connected end
function M.session() return M._session end

-- ── Internal ───────────────────────────────────────────────────────

local function sessions_dir() return M.config.channel_dir .. "/sessions" end

--- Return list of { label, data } for live Claude sessions.
local function read_sessions()
  local out = {}
  for _, path in ipairs(vim.fn.glob(sessions_dir() .. "/*.json", false, true)) do
    local ok, raw = pcall(vim.fn.readfile, path)
    if ok and raw and #raw > 0 then
      local parsed = vim.fn.json_decode(table.concat(raw, "\n"))
      if parsed and parsed.pid and parsed.socketPath and parsed.secret then
        vim.fn.system("kill -0 " .. tostring(parsed.pid) .. " 2>/dev/null")
        if vim.v.shell_error == 0 then
          table.insert(out, {
            label = string.format("[%s] %s", parsed.nvimId or "?", vim.fn.fnamemodify(parsed.cwd or "", ":~")),
            data = parsed,
          })
        else
          vim.fn.delete(path)
        end
      end
    end
  end
  return out
end

--- POST to the yank server via Unix domain socket using curl --unix-socket.
local function post(socket_path, url_path, headers, body, cb)
  local args = {
    "curl", "-s", "-X", "POST",
    "--unix-socket", socket_path,
    "http://localhost" .. (url_path or "/"),
    "--max-time", "3",
  }
  for _, h in ipairs(headers) do
    table.insert(args, "-H")
    table.insert(args, h)
  end
  if type(body) == "string" then
    table.insert(args, "-H")
    table.insert(args, "Content-Type: text/plain")
    table.insert(args, "--data-binary")
    table.insert(args, body)
  else
    table.insert(args, "-H")
    table.insert(args, "Content-Type: application/json")
    table.insert(args, "--data-raw")
    table.insert(args, vim.fn.json_encode(body))
  end
  vim.fn.jobstart(args, {
    on_exit = function(_, code)
      if cb then vim.schedule(function() cb(code) end) end
    end,
  })
end

local function auth_header()
  return "Authorization: Bearer " .. (M._session and M._session.secret or "")
end

-- ── Public API ─────────────────────────────────────────────────────

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Connect this neovim instance to the active Claude session's yank server.
function M.connect()
  if not M._session then
    vim.notify("No Claude session selected", vim.log.levels.WARN)
    return
  end
  local sock = vim.v.servername
  if not sock or sock == "" then
    vim.notify("No Neovim server socket", vim.log.levels.ERROR)
    return
  end
  post(
    M._session.socketPath, "/connect",
    { auth_header() },
    { nvim_socket = sock },
    function(code)
      if code == 0 then
        M._connected = true
        vim.notify("Neovim connected to Claude", vim.log.levels.INFO)
      else
        vim.notify("Failed to connect to Claude session", vim.log.levels.WARN)
      end
    end
  )
end

--- Pick a Claude session and connect this neovim to it.
function M.pick_session()
  local sessions = read_sessions()
  if #sessions == 0 then
    vim.notify("No active Claude sessions found", vim.log.levels.WARN)
    return
  end

  local labels = vim.tbl_map(function(s) return s.label end, sessions)

  vim.ui.select(labels, { prompt = "Select Claude session:" }, function(_, idx)
    if not idx then return end
    local session = sessions[idx].data

    M._session = {
      socketPath = session.socketPath,
      secret = session.secret,
      nvimId = session.nvimId or "?",
    }
    M._connected = false
    vim.notify(string.format("Claude session: %s", M._session.nvimId), vim.log.levels.INFO)
    M.connect()
  end)
end

--- Yank selection or text-object with file context and push to the active Claude session.
--- @param type "visual"|string  "visual" for visual mode, otherwise operatorfunc motion type
function M.yank(type)
  local start_line = type == "visual" and vim.fn.getpos("'<")[2] or vim.fn.getpos("'[")[2]
  local end_line = type == "visual" and vim.fn.getpos("'>")[2] or vim.fn.getpos("']")[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
  local lang = vim.bo.filetype
  local sock = vim.v.servername or ""
  local formatted = string.format(
    "nvim-socket: %s\n%s:%d-%d\n```%s\n%s\n```",
    sock, rel, start_line, end_line, lang, table.concat(lines, "\n")
  )

  vim.fn.setreg("+", formatted)

  -- Determine target: explicit session, or auto-pick first available
  local socket_path, secret
  if M._session then
    socket_path, secret = M._session.socketPath, M._session.secret
  else
    local sessions = read_sessions()
    if #sessions > 0 then
      socket_path = sessions[1].data.socketPath
      secret = sessions[1].data.secret
    end
  end

  if socket_path and secret then
    post(
      socket_path, "/",
      { "Authorization: Bearer " .. secret },
      formatted,
      function(code)
        local tag = M._session and ("[" .. M._session.nvimId .. "] ") or ""
        if code == 0 then
          vim.notify(string.format("→ Claude %s %s:%d-%d", tag, rel, start_line, end_line), vim.log.levels.INFO)
        else
          vim.notify(string.format("Copied %s:%d-%d (channel unreachable)", rel, start_line, end_line), vim.log.levels.WARN)
        end
      end
    )
  else
    vim.notify(string.format("Copied %s:%d-%d", rel, start_line, end_line), vim.log.levels.INFO)
  end
end

return M
