-- Runs in a temporary project made by lsp.py; no business build or files touched.
local passed = 0
local function check(value, message) assert(value, message); passed = passed + 1 end
local function run()
  vim.cmd.edit(vim.fn.fnameescape(vim.env.NEO_TEST_LSP .. '/main.cpp'))
  check(vim.wait(10000, function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })
    return #clients == 1 and clients[1].initialized
  end, 30), 'Exactly one clangd initialized')
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })[1]
  local uri = vim.uri_from_bufnr(0)
  local function request(method, params)
    local response, err = client:request_sync(method, params, 10000, 0)
    check(response and not response.err, method .. ': ' .. vim.inspect(err or response))
    return response.result
  end
  local result = request('textDocument/definition', { textDocument = { uri = uri }, position = { line = 1, character = 21 } })
  check(result and #result > 0 and result[1].range.start.line == 0, 'Definition resolves to add')
  result = request('textDocument/references', { textDocument = { uri = uri }, position = { line = 0, character = 5 }, context = { includeDeclaration = true } })
  check(result and #result == 2, 'References include definition and call')
  result = request('textDocument/rename', { textDocument = { uri = uri }, position = { line = 0, character = 5 }, newName = 'sum' })
  local edits = result and result.changes and result.changes[uri]
  if not edits and result and result.documentChanges then edits = result.documentChanges[1].edits end
  check(edits and #edits == 2, 'Rename updates both locations')
  result = request('textDocument/documentSymbol', { textDocument = { uri = uri } })
  check(result and #result == 2, 'Document symbols available')
  result = request('textDocument/formatting', { textDocument = { uri = uri }, options = { tabSize = 2, insertSpaces = true } })
  check(type(result) == 'table', 'Formatting returns edits')
  print(('PASS LSP: %d assertions'):format(passed))
end
local ok, err = xpcall(run, debug.traceback)
if not ok then vim.api.nvim_err_writeln(err); vim.cmd.cquit(1) else vim.cmd.qa({ bang = true }) end
