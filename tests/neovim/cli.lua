local passed = 0
local function check(value, message) assert(value, message); passed = passed + 1 end
local function escape() vim.cmd.normal({ args = { '\27' }, bang = true }) end
local function select(mode, first, last)
  escape()
  vim.api.nvim_win_set_cursor(0, first)
  vim.cmd.normal({ args = { mode }, bang = true })
  vim.api.nvim_win_set_cursor(0, last)
end
local function received(path)
  if vim.fn.filereadable(path) == 0 then return '' end
  return table.concat(vim.fn.readfile(path, 'b'), '\n')
end
local function run()
  local api, base = vim.api, vim.env.NEO_CLI_TEST_BASE
  -- The launcher intentionally prefers installed tools; override only this test.
  vim.env.PATH = base .. '/bin:' .. vim.env.PATH
  vim.o.clipboard = ''
  local cli = require('config.cli')
  local root = base .. '/project one'
  vim.cmd.edit(vim.fn.fnameescape(root .. '/sample with spaces.cpp'))
  local source, source_win = api.nvim_get_current_buf(), api.nvim_get_current_win()
  api.nvim_buf_set_lines(source, 0, -1, false, { 'alpha β 中文', 'abcdef', 'uvwxyz', '```nested```' })
  select('v', { 1, 6 }, { 1, 6 })
  local context = cli.selection()
  check(context.text:find('\nβ\n', 1, true) ~= nil, 'Character selection preserves UTF-8')
  check(context.text:find('(unsaved buffer snapshot)', 1, true) ~= nil, 'Unsaved snapshot labeled')
  check(context.text:find('sample with spaces.cpp:1-1', 1, true) ~= nil, 'Path and line range included')
  select('\22', { 2, 1 }, { 3, 3 })
  check(cli.selection().text:find('\nbcd\nvwx\n', 1, true) ~= nil, 'Block selection exact')
  vim.o.selection = 'exclusive'
  select('v', { 2, 1 }, { 2, 4 })
  check(cli.selection().text:find('\nbcd\n', 1, true) ~= nil, 'Exclusive selection exact')
  vim.o.selection = 'inclusive'
  select('V', { 3, 0 }, { 2, 0 })
  check(cli.selection().text:find('\nabcdef\nuvwxyz\n', 1, true) ~= nil, 'Reversed line selection ordered')
  select('V', { 4, 0 }, { 4, 0 })
  check(cli.selection().text:find('\n````cpp\n```nested```\n````', 1, true) ~= nil, 'Nested code fence preserved')

  local reg = vim.fn.getreg('0')
  select('V', { 1, 0 }, { 2, 0 })
  local expected = cli.selection().text
  vim.cmd.normal({ args = { ' as' } })
  vim.cmd.stopinsert()
  local output = root .. '/codex.paste'
  local framed = '\27[200~' .. expected .. '\27[201~'
  check(vim.wait(4000, function() return received(output) == framed end, 20), 'Codex receives one bracketed paste without Enter')
  local terminal = Snacks.terminal.get({ 'codex' }, { cwd = root, create = false })
  check(terminal and terminal:win_valid(), 'CLI stays visible after sending')
  local job = vim.b[terminal.buf].terminal_job_id
  check(vim.fn.getreg('0') == reg, 'Yank register unchanged')
  check(vim.bo[source].modified, 'Source buffer remains unsaved')
  check(vim.fn.readfile(root .. '/sample with spaces.cpp')[1] == 'original disk content', 'Disk file untouched')

  api.nvim_set_current_win(source_win)
  select('V', { 3, 0 }, { 3, 0 })
  local next_text = cli.selection().text
  cli.send_selection('codex')
  vim.cmd.stopinsert()
  framed = framed .. '\27[200~' .. next_text .. '\27[201~'
  check(vim.wait(2000, function() return received(output) == framed end, 20), 'Second selection appends to existing draft')
  check(terminal:win_valid() and vim.b[terminal.buf].terminal_job_id == job, 'Existing CLI reused without hiding')

  api.nvim_set_current_win(source_win)
  select('V', { 2, 0 }, { 2, 0 })
  expected = cli.selection().text
  vim.cmd.normal({ args = { ' aS' } })
  vim.cmd.stopinsert()
  check(vim.wait(4000, function() return received(root .. '/claude.paste') == '\27[200~' .. expected .. '\27[201~' end, 20), 'Claude mapping receives selection')

  api.nvim_set_current_win(source_win)
  vim.cmd.edit(vim.fn.fnameescape(base .. '/project two/sample with spaces.cpp'))
  select('V', { 1, 0 }, { 1, 0 })
  expected = cli.selection().text
  cli.send_selection('codex')
  vim.cmd.stopinsert()
  check(vim.wait(4000, function() return received(base .. '/project two/codex.paste') == '\27[200~' .. expected .. '\27[201~' end, 20), 'Other project gets a separate CLI context')
  vim.cmd.stopinsert()
  for _, terminal in ipairs(Snacks.terminal.list()) do
    pcall(vim.fn.jobstop, vim.b[terminal.buf].terminal_job_id)
    terminal:close()
  end
  vim.wait(100, function() return false end)
  print(('PASS CLI selection: %d assertions'):format(passed))
end
local ok, err = xpcall(run, debug.traceback)
if not ok then vim.api.nvim_err_writeln(err); vim.cmd.cquit(1) else vim.cmd.qa({ bang = true }) end
