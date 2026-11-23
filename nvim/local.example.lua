-- Copy to local.lua (ignored by Git). Only override values needed on this host.
return {
  -- clangd = '/absolute/path/to/clangd',
  -- python = '/path/to/project/.venv/bin/python',
  -- extended_keys = true, -- Enable only after checking the actual terminal/tmux.
  agent_provider = 'claude-agent-acp',
  -- acp_providers = {
  --   ['codex-acp'] = { env = { HTTPS_PROXY = 'http://127.0.0.1:PORT' } },
  -- },
  -- lsp = { clangd = { cmd = { 'clangd', '--compile-commands-dir=/path/to/build' } } },
}
