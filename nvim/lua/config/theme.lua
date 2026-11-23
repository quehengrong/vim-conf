local M = { default = 'catppuccin-mocha' }
local path = vim.fn.stdpath('state') .. '/theme.json'

function M.selected()
  if vim.fn.filereadable(path) == 1 then
    local ok, saved = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), '\n')) end)
    if ok and type(saved) == 'table' and type(saved.colorscheme) == 'string' then return saved.colorscheme end
  end
  return M.default
end

function M.apply(name, remember)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify('Cannot load theme ' .. name .. ': ' .. tostring(err), vim.log.levels.WARN)
    return false
  end
  if remember then
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile({ vim.json.encode({ colorscheme = name }) }, path)
  end
  return true
end

function M.pick()
  return Snacks.picker.colorschemes({
    confirm = function(picker, item)
      -- Preserve Snacks' cancel/preview behavior; only confirm persists a theme.
      picker:close()
      if item then
        picker.preview.state.colorscheme = nil
        vim.schedule(function() M.apply(item.text, true) end)
      end
    end,
  })
end

function M.setup()
  if not M.apply(M.selected(), false) then M.apply(M.default, false) end
  vim.api.nvim_create_user_command('NeoTheme', function(opts)
    if opts.args == '' then M.pick() else M.apply(opts.args, true) end
  end, { nargs = '?', complete = 'color', desc = 'Pick a theme or apply and remember one' })
  vim.keymap.set('n', '<leader>ut', M.pick, { desc = 'Choose theme (preview and remember)' })
end

return M
