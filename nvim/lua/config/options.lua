local o = vim.opt
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = 'yes'
o.termguicolors = true
o.background = 'dark'
o.scrolloff = 8
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.mouse = 'a'
o.undofile = true
local undo = vim.fn.stdpath('state') .. '/undo'
vim.fn.mkdir(undo, 'p')
o.undodir = undo .. '//'
o.updatetime = 250
o.timeoutlen = 400
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.autoread = true
o.confirm = true
o.completeopt = 'menu,menuone,noselect'
-- Derive folds from syntax while keeping files fully expanded on entry.
function _G.NeoFoldExpr()
  if vim.bo.buftype ~= '' or vim.b.neo_bigfile then return '0' end
  return vim.treesitter.foldexpr()
end
o.foldmethod = 'expr'
o.foldexpr = 'v:lua.NeoFoldExpr()'
o.foldlevel = 99
o.foldlevelstart = 99
o.foldcolumn = '1'
-- Preserve terminal input: do not change stty, tmux prefix, or terminal mappings.
if vim.env.SSH_CONNECTION and vim.fn.has('nvim-0.10') == 1 then
  vim.g.clipboard = 'osc52'
end
o.clipboard = 'unnamedplus'

local path = vim.fn.stdpath('config') .. '/local.lua'
local settings = {}
if vim.fn.filereadable(path) == 1 then
  local ok, value = pcall(dofile, path)
  if ok and type(value) == 'table' then
    settings = value
  else
    vim.schedule(function() vim.notify('Invalid local.lua: ' .. tostring(value), vim.log.levels.ERROR) end)
  end
end
vim.g.neo_settings = settings
-- These remote language hosts are unused; native LSP/ACP are separate processes.
for _, provider in ipairs({ 'node', 'perl', 'python3', 'ruby' }) do
  vim.g['loaded_' .. provider .. '_provider'] = 0
end
