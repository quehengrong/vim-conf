return {
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      local local_config = vim.g.neo_settings or {}
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        clangd = { cmd = { local_config.clangd or 'clangd', '--background-index', '--background-index-priority=normal', '--malloc-trim', '--log=error', '-j=6' } },
        pyright = { settings = { python = { analysis = { diagnosticMode = 'openFilesOnly', autoSearchPaths = true } } } },
        ts_ls = {}, jsonls = {},
        lua_ls = { settings = { Lua = { diagnostics = { globals = { 'vim' } },
          workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } }, telemetry = { enable = false } } } },
      }
      if local_config.python then servers.pyright.settings.python.pythonPath = local_config.python end
      for name, config in pairs(servers) do
        config.capabilities = capabilities
        config = vim.tbl_deep_extend('force', config, (local_config.lsp or {})[name] or {})
        vim.lsp.config(name, config)
        local cmd = vim.lsp.config[name].cmd
        if type(cmd) == 'table' and vim.fn.executable(cmd[1]) == 1 then
          vim.lsp.enable(name)
        end
      end
      vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev)
        if vim.b[ev.buf].neo_bigfile then
          vim.schedule(function() vim.lsp.buf_detach_client(ev.buf, ev.data.client_id) end)
        end
      end })
      vim.diagnostic.config({ severity_sort = true, virtual_text = false, float = { border = 'rounded' } })
    end,
  },
}
