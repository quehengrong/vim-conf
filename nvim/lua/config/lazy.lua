local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(path) then
  vim.api.nvim_echo({ { 'Missing lazy.nvim. Run scripts/install-neovim.sh first.', 'ErrorMsg' } }, true, {})
  return
end
vim.opt.rtp:prepend(path)
require('lazy').setup({ { import = 'plugins' } }, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  checker = { enabled = false },
  rocks = { enabled = false },
  concurrency = 4,
  git = { timeout = 300 },
  change_detection = { notify = false },
  install = { missing = false, colorscheme = { 'catppuccin-mocha', 'dracula' } },
  performance = { rtp = { disabled_plugins = { 'netrwPlugin' } } },
})
