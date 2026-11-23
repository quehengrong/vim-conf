local M = {}
local function directory(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name == '' or vim.bo[buf or 0].buftype ~= '' then return vim.uv.cwd() end
  return vim.fs.dirname(vim.fs.normalize(name))
end
function M.git(buf)
  local result = vim.system({ 'git', '-C', directory(buf), 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code == 0 then return vim.trim(result.stdout) end
end
function M.get(buf)
  if vim.t.neo_root then return vim.t.neo_root end
  return M.git(buf) or vim.fs.root(directory(buf), { 'pyproject.toml', 'package.json', 'CMakeLists.txt', '.project' }) or vim.uv.cwd()
end
function M.show()
  local roots = { 'Search/Git workspace: ' .. M.get() }
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    roots[#roots + 1] = client.name .. ': ' .. tostring(client.config.root_dir)
  end
  vim.notify(table.concat(roots, '\n'))
end
return M
