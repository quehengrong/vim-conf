return {
  { 'Mofiqul/dracula.nvim', lazy = false, priority = 1100, config = function()
    require('dracula').setup({ transparent_bg = false })
    vim.cmd.colorscheme('dracula')
  end },
  { 'nvim-lualine/lualine.nvim', event = 'VeryLazy', opts = {
    options = { theme = 'dracula', icons_enabled = false },
    sections = { lualine_c = { { 'filename', path = 1 } }, lualine_x = { 'diagnostics', 'filetype' } },
  } },
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = { delay = 400, spec = {
    { '<leader>f', group = 'Find' }, { '<leader>g', group = 'Git' },
    { '<leader>a', group = 'Agent' }, { '<leader>c', group = 'Code' },
    { '<leader>w', group = 'Windows' }, { '<leader>b', group = 'Buffers' },
    { '<leader>t', group = 'Terminal' }, { '<leader>x', group = 'Diagnostics' },
    { '<leader>u', group = 'UI' },
  } } },
}
