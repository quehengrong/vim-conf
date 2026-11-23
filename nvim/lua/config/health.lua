local M = {}
function M.check()
  vim.health.start('Neovim workspace')
  for _, exe in ipairs({ 'git', 'rg', 'fd', 'clangd', 'lazygit', 'tree-sitter', 'claude-agent-acp', 'codex-acp' }) do
    local path = vim.fn.exepath(exe)
    if path ~= '' then vim.health.ok(exe .. ': ' .. path)
    else vim.health.warn(exe .. ' missing; see docs/neovim/INSTALL.md') end
  end
  vim.health.info('Run :NeoHealth for paths and active language servers.')
end
function M.show()
  local lines = { 'Neovim ' .. tostring(vim.version()), 'Theme: ' .. tostring(vim.g.colors_name),
    'Config: ' .. vim.fn.stdpath('config'), 'Workspace: ' .. require('config.root').get() }
  for _, exe in ipairs({ 'git', 'rg', 'fd', 'node', 'clangd', 'pyright-langserver', 'typescript-language-server',
    'vscode-json-language-server', 'lua-language-server', 'lazygit', 'tree-sitter', 'claude', 'codex', 'claude-agent-acp', 'codex-acp' }) do
    local path = vim.fn.exepath(exe)
    lines[#lines + 1] = exe .. ': ' .. (path ~= '' and path or 'MISSING')
  end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    lines[#lines + 1] = 'LSP: ' .. client.name .. ' root=' .. tostring(client.config.root_dir)
  end
  vim.cmd.new()
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
end
return M
