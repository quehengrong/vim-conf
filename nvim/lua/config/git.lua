local M = {}
local function repo()
  local diffview = package.loaded['diffview.lib']
  local view = diffview and diffview.get_current_view()
  local root = vim.b.neo_git_root or (view and view.adapter and view.adapter.ctx.toplevel) or require('config.root').git()
  if not root then vim.notify('Not inside a Git worktree', vim.log.levels.WARN) end
  return root
end
local function unsaved()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].buftype == '' then
      vim.notify('Diff reads disk/index. Unsaved buffer: ' .. vim.api.nvim_buf_get_name(buf), vim.log.levels.WARN)
    end
  end
end
function M.diff(args)
  local root = repo()
  if not root then return end
  unsaved()
  require('diffview').open(vim.list_extend({ '-C' .. root }, args or {}))
end
function M.history()
  local root = repo()
  if not root then return end
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then return vim.notify('Open a file first') end
  require('diffview').file_history(nil, { '-C' .. root, '--', vim.fn.fnamemodify(name, ':p') })
end
function M.parents(hash, root)
  local r = vim.system({ 'git', '-C', root, 'rev-list', '--parents', '-n', '1', hash }, { text = true }):wait()
  if r.code ~= 0 then return nil end
  local words = vim.split(vim.trim(r.stdout), '%s+')
  table.remove(words, 1)
  return words
end
function M.commit(hash)
  local root = repo()
  if not root then return end
  local parents = M.parents(hash, root)
  if not parents then return vim.notify('Cannot resolve commit', vim.log.levels.ERROR) end
  if #parents == 0 then
    local empty = vim.system({ 'git', '-C', root, 'hash-object', '-t', 'tree', '--stdin' }, { stdin = '', text = true }):wait()
    return M.diff({ vim.trim(empty.stdout) .. '..' .. hash })
  end
  local function compare(parent)
    if parent then vim.notify('Compare ' .. hash:sub(1, 10) .. ' against parent ' .. parent:sub(1, 10)); M.diff({ parent .. '..' .. hash }) end
  end
  if #parents == 1 then compare(parents[1]) else vim.ui.select(parents, { prompt = 'Merge parent to compare (first is default)' }, compare) end
end
function M.graph(count)
  local root = repo()
  if not root then return end
  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.b.neo_git_root = root
  vim.api.nvim_buf_set_name(buf, 'neo-git-graph://' .. buf)
  vim.cmd.tcd(vim.fn.fnameescape(root))
  local all, job, preview_job, generation = true, nil, nil, 0
  local function text(lines)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end
  local function draw()
    generation = generation + 1
    local current = generation
    if job then job:kill(15) end
    if preview_job then preview_job:kill(15) end
    vim.b[buf].neo_graph_ready = false
    vim.b[buf].neo_graph_preview = false
    text({ 'Git graph: ' .. root, 'Enter: diff | r: refresh | a: all refs/HEAD | q: close', 'Loading commits asynchronously…' })
    local args = { 'git', '-C', root, '--no-pager', 'log', '--graph', '--format=%h %d %s', '--decorate=short', '-n', tostring(count or 300), all and '--all' or 'HEAD' }
    if all then
      local preview_args = vim.deepcopy(args)
      preview_args[#preview_args] = 'HEAD'
      preview_job = vim.system(preview_args, { text = true }, function(result)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) or current ~= generation or vim.b[buf].neo_graph_ready or result.code ~= 0 then return end
          local lines = { 'Git graph: HEAD preview (loading all refs): ' .. root,
            'Enter: diff | r: refresh | a: all refs/HEAD | q: close' }
          vim.list_extend(lines, vim.split(result.stdout, '\n', { trimempty = true }))
          text(lines)
          vim.b[buf].neo_graph_preview = true
        end)
      end)
    end
    job = vim.system(args, { text = true }, function(result)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) or current ~= generation then return end
        local lines = { 'Git graph (' .. (all and 'all refs' or 'HEAD') .. '): ' .. root,
          'Enter: diff | r: refresh | a: all refs/HEAD | q: close' }
        vim.list_extend(lines, vim.split(result.code == 0 and result.stdout or result.stderr, '\n', { trimempty = true }))
        if #lines == 2 then lines[#lines + 1] = 'No commits' end
        text(lines)
        vim.b[buf].neo_graph_ready = true
      end)
    end)
  end
  local function hash_on_line(line)
    for token in line:gmatch('%S+') do
      if #token >= 7 and token:match('^%x+$') then return token end
    end
  end
  vim.keymap.set('n', '<CR>', function()
    for token in vim.api.nvim_get_current_line():gmatch('%S+') do
      if #token >= 7 and token:match('^%x+$') then M.commit(token); return end
    end
    vim.notify('Select a commit row')
  end, { buffer = buf, desc = 'Inspect commit diff' })
  vim.keymap.set('x', '<CR>', function()
    local first, last = vim.fn.line('v'), vim.fn.line('.')
    if first > last then first, last = last, first end
    local hashes = {}
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, first - 1, last, false)) do
      local hash = hash_on_line(line)
      if hash then hashes[#hashes + 1] = hash end
    end
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
    if #hashes >= 2 then
      M.diff({ hashes[#hashes] .. '..' .. hashes[1] })
    else vim.notify('Select at least two commit rows') end
  end, { buffer = buf, desc = 'Compare selected endpoint commits' })
  vim.keymap.set('n', 'r', draw, { buffer = buf, desc = 'Refresh graph' })
  vim.keymap.set('n', 'a', function() all = not all; draw() end, { buffer = buf, desc = 'Toggle all refs/HEAD' })
  vim.keymap.set('n', 'q', '<Cmd>tabclose<CR>', { buffer = buf, desc = 'Close graph' })
  vim.api.nvim_create_autocmd('BufWipeout', { buffer = buf, once = true, callback = function()
    if job then job:kill(15) end
    if preview_job then preview_job:kill(15) end
  end })
  draw()
end
function M.native_graph(count)
  local root = repo()
  if not root then return end
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(root))
  require('gitgraph').draw({}, { all = true, max_count = count or 300 })
end
return M
