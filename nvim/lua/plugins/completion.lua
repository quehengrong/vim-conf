return {
  { 'saghen/blink.cmp', version = '1.*', event = 'InsertEnter',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      fuzzy = { implementation = 'lua' }, -- No runtime downloads or Rust build required.
      keymap = {
        preset = 'none',
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', function()
          return vim.keycode('<C-d>')
        end },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Esc>'] = { 'hide', 'fallback' },
        ['<C-x><C-o>'] = { 'show' },
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      },
      completion = { list = { selection = { preselect = false, auto_insert = false } },
        documentation = { auto_show = true } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      enabled = function() return vim.bo.buftype == '' and not vim.b.neo_bigfile end,
    },
  },
}
