local M = {}
function M.format()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/formatting' })
  if #clients == 0 then return vim.notify('No formatter attached; use :NeoHealth', vim.log.levels.WARN) end
  vim.lsp.buf.format({ async = false, timeout_ms = 3000, id = clients[1].id })
end
return M
