local group = vim.api.nvim_create_augroup('NeoVimWorkspace', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufReadPost' }, {
  group = group,
  callback = function(ev)
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    vim.b[ev.buf].neo_bigfile = (stat and stat.size > 1024 * 1024) or vim.api.nvim_buf_line_count(ev.buf) > 20000
    if vim.b[ev.buf].neo_bigfile then
      pcall(vim.treesitter.stop, ev.buf)
      vim.b[ev.buf].gitsigns_disable = true
    end
  end,
})
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermLeave' }, {
  group = group,
  callback = function()
    if vim.fn.mode() == 'n' then vim.cmd.checktime() end
  end,
})
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group, callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
vim.api.nvim_create_user_command('NeoRoot', function(opts)
  if opts.args ~= '' then vim.t.neo_root = vim.fs.normalize(vim.fn.fnamemodify(opts.args, ':p')) end
  require('config.root').show()
end, { nargs = '?', complete = 'dir', desc = 'Show roots or override workspace root for this tab' })
vim.api.nvim_create_user_command('NeoRootReset', function() vim.t.neo_root = nil end, {})
vim.api.nvim_create_user_command('NeoLargeFileEnable', function()
  vim.b.neo_bigfile = false
  vim.b.gitsigns_disable = false
  pcall(vim.treesitter.start)
  vim.cmd('LspStart')
  require('gitsigns').attach()
end, {})
vim.api.nvim_create_user_command('NeoHealth', function() require('config.health').show() end, {})
