local M = {}

local function options(cwd)
  return { cwd = cwd, win = { position = 'right', relative = 'editor', width = 0.4 } }
end

local function available(tool)
  if vim.fn.executable(tool) == 1 then return true end
  vim.notify(tool .. ' is missing; use :NeoHealth', vim.log.levels.WARN)
end

function M.toggle(tool)
  if not available(tool) then return end
  local terminal = vim.b.snacks_terminal
  local cwd = terminal and terminal.cwd or require('config.root').get()
  return Snacks.terminal({ tool }, options(cwd))
end

-- Read the actual buffer selection without yanking or touching the clipboard.
function M.selection()
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    vim.notify('Select some text first', vim.log.levels.WARN)
    return
  end
  if vim.bo.buftype ~= '' then
    vim.notify('Select text in a file buffer', vim.log.levels.WARN)
    return
  end
  local first, last = vim.fn.getpos('v'), vim.fn.getpos('.')
  local lines = vim.fn.getregion(first, last, { type = mode, exclusive = vim.o.selection == 'exclusive' })
  local content = table.concat(lines, '\n')
  if content == '' then return end
  local cwd = require('config.root').get()
  local name = vim.api.nvim_buf_get_name(0)
  local label = name ~= '' and (vim.fs.relpath(cwd, name) or name) or '[unnamed buffer]'
  local start_line, end_line = math.min(first[2], last[2]), math.max(first[2], last[2])
  local longest = 2
  for ticks in content:gmatch('`+') do longest = math.max(longest, #ticks) end
  local fence = string.rep('`', longest + 1)
  local header = ('Selected code: %s:%d-%d%s'):format(label, start_line, end_line,
    vim.bo.modified and ' (unsaved buffer snapshot)' or '')
  return {
    cwd = cwd,
    text = '\n\n' .. header .. '\n' .. fence .. vim.bo.filetype .. '\n' .. content .. '\n' .. fence .. '\n\n',
  }
end

function M.send_selection(tool)
  tool = tool or 'codex'
  if not available(tool) then return end
  local selection = M.selection()
  if not selection then return end
  vim.cmd.normal({ args = { '\27' }, bang = true })
  local terminal, created = Snacks.terminal.get({ tool }, options(selection.cwd))
  if not terminal then return end
  terminal:show():focus()
  vim.cmd.startinsert()
  local function paste()
    if not terminal:buf_valid() or not terminal:win_valid() then return end
    local job = vim.b[terminal.buf].terminal_job_id
    if not job or vim.fn.jobwait({ job }, 0)[1] ~= -1 then
      vim.notify(tool .. ' exited before the selection could be pasted', vim.log.levels.WARN)
      return
    end
    -- Bracketed paste keeps embedded newlines inside the CLI draft. Do not send
    -- Enter after the closing marker. Escape literal ESC bytes in source text
    -- so selected control sequences cannot terminate the paste framing.
    local text = selection.text:gsub('\27', '\\x1b'):gsub('%z', '\\0')
    vim.api.nvim_chan_send(job, '\27[200~' .. text .. '\27[201~')
  end
  -- Give a newly started TUI time to initialize; existing drafts paste at once.
  -- First-use login/trust screens must be completed before using this action.
  if created then vim.defer_fn(paste, 600) else vim.schedule(paste) end
end

return M
