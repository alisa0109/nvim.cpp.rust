local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- nvim-treesitter's "main" branch only manages parser installation; since the
-- old configs.setup({ highlight = ..., indent = ... }) module no longer
-- exists, highlighting/indent/folding are started manually per-buffer here.
-- Folding itself (foldexpr) is wired globally in config/options.lua.
local ts_group = augroup("ide_treesitter_start", { clear = true })
local ts_filetypes = {
  "c",
  "cpp",
  "rust",
  "lua",
  "bash",
  "sh",
  "json",
  "jsonc",
  "yaml",
  "toml",
  "markdown",
  "markdown_inline",
  "vim",
  "vimdoc",
  "query",
}
autocmd("FileType", {
  group = ts_group,
  pattern = ts_filetypes,
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
  desc = "Start native treesitter highlighting/indent for this buffer",
})

-- Quality-of-life: close throwaway windows with a single "q"
local qf_group = augroup("ide_quit_with_q", { clear = true })
autocmd("FileType", {
  group = qf_group,
  pattern = { "qf", "help", "lspinfo", "checkhealth", "man" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
  desc = "Close helper windows with q",
})

-- Restore last cursor position when reopening a file
autocmd("BufReadPost", {
  group = augroup("ide_restore_cursor", { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
