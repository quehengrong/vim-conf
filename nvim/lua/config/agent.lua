local M = { session_roots = {}, last_session = {} }
-- Agentic's current() can fall back to the most recent session in another tab.
-- Use its pinned registry API explicitly to keep workspace contexts isolated.
function M.call(method)
  local root = require('config.root').get()
  if vim.bo.modified then
    vim.notify('Unsaved buffer: selection uses buffer content; agent file reads use disk.', vim.log.levels.WARN)
  end
  vim.cmd.tcd(vim.fn.fnameescape(root))
  local ok, err = pcall(function()
    local registry = require('agentic.session_registry')
    local function show(session)
      if not session then return end
      M.last_session[root] = session.session_key
      registry.show_session(session.session_key, { focus_prompt = true })
    end
    local function create(provider)
      local session = registry.create(provider, { kind = 'new', cwd = function() return root end })
      if session then
        M.session_roots[session.session_key] = root
        M.last_session[root] = session.session_key
      end
      return session
    end
    if method == 'new_session_with_provider' then
      return vim.ui.select({ 'claude-agent-acp', 'codex-acp' }, { prompt = 'New project agent session' }, function(provider)
        if provider then show(create(provider)) end
      end)
    end
    if method == 'new_session' then return show(create()) end
    if method == 'restore_session' then
      -- The provider owns historical sessions and their cwd. Restoration is an
      -- explicit user choice; unknown restored sessions are not reused by ensure.
      return require('agentic').restore_session()
    end
    if method == 'select_session' then
      local sessions = vim.tbl_filter(function(session) return M.session_roots[session.session_key] == root end, registry.list())
      return vim.ui.select(sessions, { prompt = 'Sessions for ' .. root,
        format_item = function(session) return session.provider_name .. ' #' .. session.session_key .. ' ' .. (session.chat_history.title or '') end,
      }, show)
    end
    local visible = registry.visible_here()
    if method == 'toggle' and visible and M.session_roots[visible.session_key] == root then
      require('agentic').close()
      return
    end
    local session = visible and M.session_roots[visible.session_key] == root and visible
      or (M.last_session[root] and registry.get(M.last_session[root])) or create()
    if not session then return end
    if method == 'add_selection' then session:add_selection_to_session()
    elseif method == 'add_file' then session:add_file_to_session() end
    show(session)
  end)
  if not ok then vim.notify('Agent unavailable: ' .. tostring(err) .. '\nUse :NeoHealth or the CLI fallback.', vim.log.levels.ERROR) end
end
function M.terminal(tool)
  if vim.fn.executable(tool) ~= 1 then return vim.notify(tool .. ' is missing; use :NeoHealth', vim.log.levels.WARN) end
  Snacks.terminal({ tool }, { cwd = require('config.root').get() })
end
return M
