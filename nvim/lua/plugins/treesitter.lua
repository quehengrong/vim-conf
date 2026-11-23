return {
  { 'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false,
    config = function()
      require('nvim-treesitter').setup({})
      vim.api.nvim_create_autocmd('FileType', { callback = function(ev)
        if vim.bo[ev.buf].buftype == '' and not vim.b[ev.buf].neo_bigfile then
          pcall(vim.treesitter.start, ev.buf)
        end
      end })
      vim.api.nvim_create_user_command('NeoParsersInstall', function()
        require('nvim-treesitter').install({ 'c', 'cpp', 'python', 'lua', 'json', 'javascript', 'typescript', 'tsx', 'vim', 'vimdoc', 'bash', 'markdown', 'markdown_inline' })
      end, { desc = 'Explicitly install the supported parsers' })
    end,
  },
  { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main', lazy = false,
    config = function()
      require('nvim-treesitter-textobjects').setup({ select = { lookahead = true }, move = { set_jumps = true } })
      local structure = require('config.structure')
      for key, object in pairs({ af = 'function.outer', ['if'] = 'function.inner', ac = 'class.outer', ic = 'class.inner', aa = 'parameter.outer', ia = 'parameter.inner' }) do
        vim.keymap.set({ 'x', 'o' }, key, function() structure.select(object) end, { desc = 'Select ' .. object })
      end
      for key, spec in pairs({
        [']m'] = { 'function', false, true }, ['[m'] = { 'function', false, false },
        [']M'] = { 'function', true, true }, ['[M'] = { 'function', true, false },
        [']]'] = { 'class', false, true }, ['[['] = { 'class', false, false },
        [']['] = { 'class', true, true }, ['[]'] = { 'class', true, false },
      }) do
        vim.keymap.set({ 'n', 'x', 'o' }, key, function() structure.move(unpack(spec)) end, { desc = 'Move to ' .. spec[1] })
      end
    end,
  },
}
