local M = {}
local types = { struct_specifier = true, class_specifier = true, union_specifier = true }
local function c_family() return vim.bo.filetype == 'c' or vim.bo.filetype == 'cpp' end
local function tree()
  if vim.b.neo_bigfile then vim.notify('Structure parsing disabled for large file'); return end
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then vim.notify('Parser missing; run :NeoParsersInstall or use gs', vim.log.levels.WARN); return end
  local parsed = parser:parse()
  return parsed[1] and parsed[1]:root()
end
local function is_kind(node, kind, lambda)
  if kind == 'class' then return types[node:type()] and #node:field('body') > 0 end
  return node:type() == 'function_definition' or (lambda and node:type() == 'lambda_expression')
end
local function outer(node, kind)
  local parent = node:parent()
  while parent and parent:type() == 'template_declaration' do node = parent; parent = node:parent() end
  local sr, sc, er, ec = node:range()
  if kind == 'class' then
    local next_node = node:next_sibling()
    if next_node and next_node:type() == ';' then _, _, er, ec = next_node:range() end
  end
  return { sr, sc, er, ec }
end
local function contains(r, row, col)
  return (row > r[1] or row == r[1] and col >= r[2]) and (row < r[3] or row == r[3] and col < r[4])
end
local function before(a, b) return a[1] < b[1] or a[1] == b[1] and a[2] < b[2] end
function M.ranges(kind, include_lambda)
  local root = tree()
  if not root then return {} end
  local ranges = {}
  local function walk(node)
    if is_kind(node, kind, include_lambda) then
      ranges[#ranges + 1] = { node = node, range = outer(node, kind) }
    end
    for child in node:iter_children() do walk(child) end
  end
  walk(root)
  table.sort(ranges, function(a, b) return before(a.range, b.range) end)
  return ranges
end
local function endpoint(r)
  local row, col = r[3], r[4]
  if col == 0 then
    row = row - 1
    col = #(vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or '')
  end
  return row, math.max(col - 1, 0)
end
function M.select(object)
  local kind, part = object:match('^(%w+)%.(%w+)$')
  if not c_family() or kind == 'parameter' then
    if not tree() then return end
    return require('nvim-treesitter-textobjects.select').select_textobject('@' .. object, 'textobjects')
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local all = M.ranges(kind, true)
  local selected
  for _, entry in ipairs(all) do
    if contains(entry.range, row, col) then selected = entry
    elseif not selected and before({ row, col }, entry.range) then selected = entry; break end
  end
  if not selected then vim.notify('No matching ' .. kind); return end
  local r = selected.range
  if part == 'inner' then
    local body = selected.node:field('body')[1]
    if not body then return end
    local sr, sc, er, ec = body:range()
    r = { sr, sc + 1, er, ec - 1 }
    if r[1] == r[3] and r[2] >= r[4] then vim.notify('Empty body'); return end
  end
  local er, ec = endpoint(r)
  -- Switch out of an existing visual selection before choosing an exact range.
  if vim.fn.mode():match('[vV\22]') then vim.cmd.normal({ args = { '\27' }, bang = true }) end
  vim.api.nvim_win_set_cursor(0, { r[1] + 1, r[2] })
  vim.cmd.normal({ args = { 'v' }, bang = true })
  vim.api.nvim_win_set_cursor(0, { er + 1, ec })
end
function M.move(kind, at_end, forward)
  if not c_family() then
    if not tree() then return end
    local method = 'goto_' .. (forward and 'next' or 'previous') .. '_' .. (at_end and 'end' or 'start')
    return require('nvim-treesitter-textobjects.move')[method]('@' .. kind .. '.outer', 'textobjects')
  end
  local points = {}
  for _, entry in ipairs(M.ranges(kind, false)) do
    local r = entry.range
    local er, ec = endpoint(r)
    points[#points + 1] = at_end and { er, ec } or { r[1], r[2] }
  end
  table.sort(points, before)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current = { cursor[1] - 1, cursor[2] }
  local eligible = {}
  for _, point in ipairs(points) do
    if (forward and before(current, point)) or (not forward and before(point, current)) then eligible[#eligible + 1] = point end
  end
  local count = vim.v.count1
  local target = forward and eligible[count] or eligible[#eligible - count + 1]
  if not target then vim.notify('No ' .. (forward and 'next ' or 'previous ') .. kind); return end
  vim.cmd.normal({ args = { "m'" }, bang = true })
  vim.api.nvim_win_set_cursor(0, { target[1] + 1, target[2] })
end
return M
