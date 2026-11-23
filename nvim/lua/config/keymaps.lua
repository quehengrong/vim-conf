local map = vim.keymap.set
local root = function() return require('config.root').get() end
local function pick(name, opts)
  return function() Snacks.picker[name](vim.tbl_extend('force', { cwd = root() }, opts or {})) end
end
local function editing() return vim.bo.buftype == '' and vim.bo.filetype ~= 'agentic' end
local function buffer_maps(ev)
  if not editing() then return end
  local function bmap(mode, lhs, rhs, desc)
    map(mode, lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
  end
  bmap({ 'n', 'i' }, '<C-p>', pick('files'), 'Find files')
  bmap('n', '<C-f>', '/', 'Search buffer')
  bmap('n', '<C-b>', function() Snacks.explorer({ cwd = root() }) end, 'File explorer (tmux may intercept)')
  bmap({ 'n', 'i' }, '<C-s>', function() vim.cmd.update() end, 'Save file')
  bmap('n', '<F1>', pick('commands'), 'Command picker')
  bmap('n', '<F2>', vim.lsp.buf.rename, 'Rename symbol')
  bmap('n', '<F12>', vim.lsp.buf.definition, 'Definition')
  -- Shift/Ctrl aliases are opt-in after testing terminal and tmux transport.
  if (vim.g.neo_settings or {}).extended_keys then
    bmap({ 'n', 'i' }, '<C-S-p>', pick('commands'), 'Command picker')
    bmap({ 'n', 'i' }, '<C-S-f>', pick('grep'), 'Search project')
    bmap('n', '<C-Tab>', pick('buffers'), 'Buffers')
    bmap({ 'n', 'x' }, '<C-S-i>', function() require('config.actions').format() end, 'Format')
    map('n', '<C-/>', 'gcc', { buffer = ev.buf, remap = true, desc = 'Toggle comment' })
    map('x', '<C-/>', 'gc', { buffer = ev.buf, remap = true, desc = 'Toggle comment' })
  end
end
vim.api.nvim_create_autocmd('FileType', { callback = buffer_maps })
map('n', '<leader>ff', pick('files'), { desc = 'Find files' })
map('n', '<leader>fg', pick('grep'), { desc = 'Search project' })
map('n', 'g/', pick('grep'), { desc = 'Search project' })
map('n', '<leader>fH', pick('files', { hidden = true }), { desc = 'Find hidden files' })
map('n', '<leader>fI', pick('files', { hidden = true, ignored = true }), { desc = 'Find ignored files' })
map('n', '<leader>fG', pick('grep', { hidden = true, ignored = true }), { desc = 'Search ignored files' })
map('n', '<leader>fb', pick('buffers'), { desc = 'Buffers' })
map('n', '<leader>fr', pick('recent'), { desc = 'Recent files' })
map('n', '<leader>e', function() Snacks.explorer({ cwd = root() }) end, { desc = 'File explorer' })
map('n', '<leader>:', pick('commands'), { desc = 'Command picker' })
map('n', '<leader>?', pick('keymaps'), { desc = 'Find keymaps' })
map('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Close buffer, preserve windows' })
map('n', '<leader>tt', function() Snacks.terminal(nil, { cwd = root() }) end, { desc = 'Terminal' })
map('n', '<leader>gg', function() Snacks.lazygit({ cwd = root() }) end, { desc = 'Git panel (Lazygit)' })
map('n', '<leader>xx', pick('diagnostics'), { desc = 'Diagnostics' })
map('n', '<leader>wr', function() require('config.root').show() end, { desc = 'Show workspace and LSP roots' })
map('n', '<leader>wv', '<C-w>v', { desc = 'Split right' })
map('n', '<leader>ws', '<C-w>s', { desc = 'Split below' })
for key, dir in pairs({ h = 'Left', j = 'Down', k = 'Up', l = 'Right' }) do
  map('n', '<C-' .. key .. '>', '<Cmd>TmuxNavigate' .. dir .. '<CR>', { desc = 'Navigate ' .. dir })
  map('n', '<leader>w' .. key, '<C-w>' .. key, { desc = 'Window ' .. dir })
end
for lhs, fn in pairs({ gd = 'definition', gD = 'declaration', gy = 'type_definition', gI = 'implementation', gA = 'references', gr = 'references', K = 'hover', gh = 'hover', cd = 'rename' }) do
  map('n', lhs, vim.lsp.buf[fn], { desc = 'LSP ' .. fn })
end
map('n', 'gs', pick('lsp_symbols'), { desc = 'File symbols' })
map('n', 'gS', pick('lsp_workspace_symbols'), { desc = 'Workspace symbols' })
map('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename symbol' })
map({ 'n', 'x' }, 'g.', vim.lsp.buf.code_action, { desc = 'Code actions' })
map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
map({ 'n', 'x' }, '<leader>=', function() require('config.actions').format() end, { desc = 'Format file/selection' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'Previous diagnostic' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Next diagnostic' })
