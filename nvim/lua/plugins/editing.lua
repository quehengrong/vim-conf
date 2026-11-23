return {
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },
  { 'tpope/vim-surround', event = 'VeryLazy' },
  { 'tpope/vim-repeat', event = 'VeryLazy' },
  { 'junegunn/vim-easy-align', keys = {
    { '<leader>ce', '<Plug>(EasyAlign)', mode = { 'n', 'x' }, desc = 'Align text' },
  } },
  { 'christoomey/vim-tmux-navigator', lazy = false, init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end },
}
