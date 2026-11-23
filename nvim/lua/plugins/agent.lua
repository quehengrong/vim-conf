return {
  { 'carlos-algms/agentic.nvim', opts = function()
    local settings = vim.g.neo_settings or {}
    return { provider = settings.agent_provider or 'codex-acp',
      acp_configs = { session_cwd = function() return require('config.root').get() end },
      acp_providers = settings.acp_providers or {}, windows = { position = 'right', width = '40%' } }
  end, keys = {
    { '<leader>aa', function() require('config.agent').terminal('codex') end, desc = 'Toggle Codex CLI (right pane)' },
    { '<leader>aA', function() require('config.agent').call('toggle') end, desc = 'Toggle ACP agent pane' },
    { '<leader>as', function() require('config.agent').call('add_selection') end, mode = 'x', desc = 'Add selection to agent' },
    { '<leader>af', function() require('config.agent').call('add_file') end, desc = 'Add file to agent' },
    { '<leader>ap', function() require('config.agent').call('new_session_with_provider') end, desc = 'Choose agent (new session)' },
    { '<leader>an', function() require('config.agent').call('new_session') end, desc = 'New agent session' },
    { '<leader>ar', function() require('config.agent').call('restore_session') end, desc = 'Restore agent session' },
    { '<leader>al', function() require('config.agent').call('select_session') end, desc = 'Select project agent session' },
    { '<leader>ax', function() require('agentic').stop_generation() end, desc = 'Cancel agent generation' },
    { '<leader>ac', function() require('config.agent').terminal('claude') end, desc = 'Claude CLI fallback' },
    { '<leader>ao', function() require('config.agent').terminal('codex') end, desc = 'Codex CLI fallback' },
  } },
}
