-- Neovim >= 0.12 is required: this config relies on the native vim.lsp.config()/
-- vim.lsp.enable() API and built-in treesitter highlighting introduced in 0.11/0.12.
if vim.fn.has("nvim-0.12") ~= 1 then
  vim.schedule(function()
    vim.notify(
      "This config requires Neovim >= 0.12.0 (found "
        .. tostring(vim.version())
        .. "). See README.md for upgrade instructions on openSUSE/Debian.",
      vim.log.levels.ERROR,
      { title = "nvim-ide" }
    )
  end)
  return
end

-- leader must be set before lazy.nvim / which-key load any keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
require("ide.health") -- defines :IDEHealth (also reachable as :checkhealth ide)
