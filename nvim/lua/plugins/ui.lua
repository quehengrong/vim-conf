return {
  { 'catppuccin/nvim', name = 'catppuccin', lazy = false, priority = 1200,
    dependencies = { 'Mofiqul/dracula.nvim' }, opts = {
    flavour = 'mocha',
    integrations = { aerial = true, gitsigns = true, treesitter_context = true, which_key = true, snacks = true },
  }, config = function(_, opts)
    require('catppuccin').setup(opts)
    require('config.theme').setup()
  end },
  { 'Mofiqul/dracula.nvim', lazy = false, priority = 1100, config = function()
    require('dracula').setup({ transparent_bg = false })
  end },
  { 'nvim-lualine/lualine.nvim', event = 'VeryLazy', opts = {
    options = { theme = 'auto', icons_enabled = false },
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
