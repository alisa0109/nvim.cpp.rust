-- Core editor options. Plugin-specific options live next to their plugin spec.
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3 -- one global statusline (lualine)
opt.showmode = false -- mode is shown in lualine
opt.pumheight = 12
opt.cmdheight = 1
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.wrap = false
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
opt.winborder = "rounded"

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

-- Files / undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.fileencoding = "utf-8"
opt.updatetime = 250
opt.timeoutlen = 300

-- Completion (consumed by blink.cmp)
opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- Folding via native treesitter (see config/autocmds.lua)
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Clipboard: share with system clipboard
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- Diagnostics presentation (native vim.diagnostic, see plugins/lsp.lua for the
-- rest of the config that needs LSP client info)
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})
