return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      max_lines = 3,
      multiline_threshold = 2,
      min_window_height = 15,
      on_attach = function(buf)
        return vim.bo[buf].buftype == '' and not vim.b[buf].neo_bigfile
      end,
    },
    keys = {
      { '<leader>uc', function() require('treesitter-context').toggle() end, desc = 'Toggle sticky code context' },
    },
  },
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialClose', 'AerialNavToggle' },
    keys = {
      { '<leader>co', '<Cmd>AerialToggle!<CR>', desc = 'Toggle code outline' },
      { '<leader>cO', '<Cmd>AerialOpen<CR>', desc = 'Focus code outline' },
    },
    opts = {
      backends = { 'lsp', 'treesitter' },
      layout = { default_direction = 'right', min_width = 24, max_width = { 40, 0.25 } },
      show_guides = true,
      disable_max_lines = 20000,
      disable_max_size = 1024 * 1024,
      filter_kind = { 'Class', 'Constructor', 'Enum', 'Function', 'Interface', 'Method', 'Namespace', 'Struct' },
      -- Match the existing terminal-friendly UI without requiring a Nerd Font.
      icons = { Class = 'C', Constructor = 'c', Enum = 'E', Function = 'f',
        Interface = 'I', Method = 'm', Namespace = 'N', Struct = 'S' },
      keymaps = { ['<C-j>'] = false, ['<C-k>'] = false }, -- Preserve tmux navigation.
    },
  },
}
