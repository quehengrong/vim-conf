-- Loaded by ui.py inside a real PTY. Does not send a model prompt.
vim.defer_fn(function()
  local report = { theme = vim.g.colors_name == require('config.theme').selected(), checks = {} }
  local errors = {}
  local notify = vim.notify
  vim.notify = function(msg, level, opts)
    if level == vim.log.levels.ERROR then errors[#errors + 1] = tostring(msg) end
    notify(msg, level, opts)
  end
  local ok, err = xpcall(function()
    report.checks.input = vim.ui.input == Snacks.input.input
    report.checks.select = vim.ui.select == Snacks.picker.select
    local picker = Snacks.picker.files({ cwd = require('config.root').get() })
    assert(vim.wait(5000, function() return picker.list:count() > 0 end, 30), 'Picker files available')
    report.checks.picker = picker.list:count() > 0
    picker:close()
    vim.wait(100, function() return false end)
    require('lazy').load({ plugins = { 'agentic.nvim' } })
    require('config.agent').call('toggle')
    local registry = require('agentic.session_registry')
    assert(vim.wait(10000, function() return registry.visible_here() ~= nil end, 50), 'Agent sidebar visible')
    report.checks.agent_sidebar = registry.visible_here() ~= nil
    local first_session = registry.visible_here()
    require('agentic').close()
    vim.wait(100, function() return false end)
    report.checks.agent_close = registry.visible_here() == nil
    vim.api.nvim_win_set_cursor(0, { 4, 2 })
    vim.cmd.normal({ args = { 'vaf' } })
    require('config.agent').call('add_selection')
    report.checks.agent_selection = #registry.visible_here().code_selection:get_selections() == 1
    require('agentic').close()
    local other_root = vim.fn.tempname()
    vim.fn.mkdir(other_root, 'p')
    vim.fn.writefile({ 'project(probe)' }, other_root .. '/CMakeLists.txt')
    vim.fn.writefile({ 'int other() { return 0; }' }, other_root .. '/other.cpp')
    vim.cmd.tabnew(vim.fn.fnameescape(other_root .. '/other.cpp'))
    require('config.agent').call('toggle')
    local other_session = registry.visible_here()
    report.checks.agent_worktree_isolation = other_session.session_key ~= first_session.session_key
      and require('config.agent').session_roots[other_session.session_key] == other_root
    require('agentic').close()
    vim.cmd.tabclose()
    require('config.agent').call('toggle')
    report.checks.agent_session_resume = registry.visible_here().session_key == first_session.session_key
    require('agentic').close()
    vim.fn.delete(other_root, 'rf')
    report.checks.layout_restored = #vim.api.nvim_tabpage_list_wins(0) >= 1
  end, debug.traceback)
  report.ok, report.error, report.errors = ok, ok and nil or err, errors
  vim.fn.writefile({ vim.json.encode(report) }, vim.env.NEO_UI_REPORT)
  vim.cmd.qa({ bang = true })
end, 200)
