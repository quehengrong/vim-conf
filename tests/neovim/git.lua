local root = vim.env.NEO_TEST_REPO
local passed = 0
local function check(value, message) assert(value, message); passed = passed + 1 end
local function edit(path) vim.cmd.edit(vim.fn.fnameescape(path)) end
local function view()
  return require('diffview.lib').get_current_view()
end
local function wait_files(predicate)
  local ready = vim.wait(10000, function()
    local v = view()
    return v and predicate(v.files) and v.cur_entry and v.cur_entry.opened
  end, 30)
  if not ready then print('Diffview state:', vim.inspect(view() and view().files)) end
  check(ready, 'Diffview populated files')
  return view().files
end
local function has(files, path)
  for _, file in ipairs(files) do if file.path == path then return true end end
  return false
end
local function close() vim.cmd.DiffviewClose() end
local function run()
  require('lazy').load({ plugins = { 'gitsigns.nvim', 'diffview.nvim', 'gitgraph.nvim' } })
  edit(root .. '/main.txt')
  check(require('config.root').get() == root, 'Root resolves from file outside initial cwd')
  local git = require('config.git')
  local gs = require('gitsigns')
  check(vim.wait(5000, function() return #(gs.get_hunks() or {}) == 2 end, 30), 'Gitsigns finds two unstaged hunks')
  local staged = false
  gs.stage_hunk({ 35, 35 }, nil, function(err) assert(not err, err); staged = true end)
  check(vim.wait(5000, function() return staged end, 30), 'Stage one hunk completed')
  local index = vim.system({ 'git', '-C', root, 'show', ':main.txt' }, { text = true }):wait().stdout
  check(index:find('unstaged change', 1, true) and not index:find('other unstaged change', 1, true), 'Staging only selected hunk preserves other unstaged hunk')
  -- Read the updated index before toggling the staged hunk back out.
  check(vim.wait(5000, function() return #(gs.get_hunks() or {}) == 1 end, 30), 'Stage signs refreshed')
  local unstaged = false
  gs.stage_hunk({ 35, 35 }, nil, function(err) assert(not err, err); unstaged = true end)
  check(vim.wait(5000, function() return unstaged end, 30), 'Unstage selected hunk completed')
  check(vim.wait(5000, function() return #(gs.get_hunks() or {}) == 2 end, 30), 'Unstaged hunks restored')
  local reset = false
  gs.reset_hunk({ 10, 10 }, nil, function(err) assert(not err, err); reset = true end)
  check(vim.wait(5000, function() return reset end, 30), 'Reset selected hunk completed')
  check(vim.api.nvim_buf_get_lines(0, 9, 10, false)[1] == 'line 10', 'Reset targets only chosen hunk')
  check(vim.api.nvim_buf_get_lines(0, 34, 35, false)[1] == 'unstaged change', 'Reset preserves other hunk')
  vim.cmd.write()
  git.diff()
  local files = wait_files(function(f) return #f.working >= 3 and #f.staged >= 2 end)
  check(has(files.working, 'untracked.txt'), 'Untracked file shown')
  check(has(files.working, 'other.txt'), 'Deleted file shown')
  check(has(files.staged, 'renamed.txt'), 'Rename shown')
  check(has(files.working, 'main.txt') and has(files.staged, 'main.txt'), 'Staged and unstaged versions separated')
  close()
  git.diff({ '--cached' })
  files = wait_files(function(f) return #f.working >= 2 end)
  check(not has(files.working, 'untracked.txt'), 'Cached diff excludes untracked')
  close()
  git.commit(vim.env.NEO_TEST_ROOT_COMMIT)
  files = wait_files(function(f) return #f.working == 2 end)
  check(has(files.working, 'main.txt'), 'Root commit compares against empty tree')
  close()
  local head = vim.trim(vim.system({ 'git', '-C', root, 'rev-parse', 'HEAD' }, { text = true }):wait().stdout)
  check(#git.parents(head, root) == 2, 'Merge parents resolved')
  local original_select = vim.ui.select
  vim.ui.select = function(items, _, callback) callback(items[2]) end
  git.commit(head)
  wait_files(function(f) return #f.working > 0 end)
  close()
  vim.ui.select = original_select
  edit(vim.env.NEO_TEST_WORKTREE .. '/main.txt')
  check(require('config.root').get() == vim.env.NEO_TEST_WORKTREE, 'Linked worktree has its own root')
  edit(root .. '/main.txt')
  local start = vim.uv.hrtime()
  git.graph(300)
  check(vim.uv.hrtime() - start < 2e9, 'Small graph draws within 2 seconds')
  check(vim.wait(2000, function() return vim.b.neo_graph_ready end), 'Graph has content')
  print(('PASS Git: %d assertions'):format(passed))
end
local ok, err = xpcall(run, debug.traceback)
if not ok then vim.api.nvim_err_writeln(err); vim.cmd.cquit(1) else vim.cmd.qa({ bang = true }) end
