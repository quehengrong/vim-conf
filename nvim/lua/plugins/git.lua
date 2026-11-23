return {
  { 'lewis6991/gitsigns.nvim', event = { 'BufReadPost', 'BufNewFile' }, opts = {
    max_file_length = 20000,
    on_attach = function(buf)
      if vim.b[buf].neo_bigfile then return false end
      local gs = require('gitsigns')
      local function map(lhs, rhs, desc, mode) vim.keymap.set(mode or 'n', lhs, rhs, { buffer = buf, desc = desc }) end
      map(']c', function() if vim.wo.diff then vim.cmd.normal({ args = { ']c' }, bang = true }) else gs.nav_hunk('next') end end, 'Next change')
      map('[c', function() if vim.wo.diff then vim.cmd.normal({ args = { '[c' }, bang = true }) else gs.nav_hunk('prev') end end, 'Previous change')
      map('<leader>gp', gs.preview_hunk, 'Preview hunk')
      map('<leader>gs', gs.stage_hunk, 'Stage/unstage hunk')
      map('<leader>gs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage selected lines', 'x')
      map('<leader>gR', function()
        if vim.fn.confirm('Discard the working-tree hunk under cursor?', '&Cancel\n&Discard', 1) == 2 then gs.reset_hunk() end
      end, 'Discard hunk (confirm)')
      map('<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
    end,
  } },
  { 'sindrets/diffview.nvim', cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' }, opts = {
    enhanced_diff_hl = true,
    view = { default = { layout = 'diff2_horizontal' } },
    default_args = { DiffviewOpen = { '--untracked-files=all' } },
  }, keys = {
    { '<leader>gd', function() require('config.git').diff() end, desc = 'Workspace diff' },
    { '<leader>gD', function() require('config.git').diff({ '--cached' }) end, desc = 'Staged diff' },
    { '<leader>ad', function() require('config.git').diff() end, desc = 'Workspace diff (all changes)' },
    { '<leader>gh', function() require('config.git').history() end, desc = 'File history' },
    { '<leader>gq', '<Cmd>DiffviewClose<CR>', desc = 'Close diff view' },
  } },
  { 'isakbm/gitgraph.nvim', dependencies = { 'sindrets/diffview.nvim' }, opts = {
    symbols = { merge_commit = 'M', commit = '*' },
    format = { timestamp = '%Y-%m-%d', fields = { 'hash', 'timestamp', 'author', 'branch_name', 'tag' } },
    hooks = {
      on_select_commit = function(commit) require('config.git').commit(commit.hash) end,
      on_select_range_commit = function(from, to) require('config.git').diff({ from.hash .. '..' .. to.hash }) end,
    },
  }, cmd = { 'NeoNativeGraph' }, config = function(_, opts)
    require('gitgraph').setup(opts)
    vim.api.nvim_create_user_command('NeoNativeGraph', function() require('config.git').native_graph(300) end, { desc = 'Native graph (synchronous; slow on large repositories)' })
  end, keys = {
    { '<leader>gl', function() require('config.git').graph(300) end, desc = 'Commit graph (300)' },
    { '<leader>gL', function() require('config.git').graph(1500) end, desc = 'Commit graph (1500)' },
  } },
}
