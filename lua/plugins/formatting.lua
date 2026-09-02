-- Formatting (TS §13): clang-format for C/C++, rustfmt for Rust. Format on
-- save is skipped whenever the buffer has an active LSP error diagnostic, so
-- we never "fix" formatting over code the compiler/clangd considers broken.
local function has_errors(bufnr)
  return #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR }) > 0
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format file/selection",
      },
    },
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        rust = { "rustfmt" },
      },
      formatters = {
        clang_format = {
          -- Respects a project .clang-format if present; falls back to LLVM style.
          prepend_args = function()
            local has_style = vim.uv.fs_stat((vim.uv.cwd() or "") .. "/.clang-format")
            return has_style and {} or { "--style=llvm" }
          end,
        },
      },
      format_on_save = function(bufnr)
        if has_errors(bufnr) then
          return nil
        end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
  },
}
