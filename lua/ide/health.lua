-- :IDEHealth (TS §33, §38): a fast, focused executable check, separate from
-- the much broader :checkhealth. Reports which external tools this config
-- depends on are actually on PATH.
local tools = {
  { bin = "git", desc = "version control" },
  { bin = "rg", desc = "ripgrep — Telescope live_grep" },
  { bin = "fd", desc = "fast find — file pickers" },
  { bin = "clangd", desc = "C/C++ language server" },
  { bin = "clang-format", desc = "C/C++ formatter" },
  { bin = "clang-tidy", desc = "C/C++ static analysis" },
  { bin = "rustc", desc = "Rust compiler" },
  { bin = "cargo", desc = "Rust build tool" },
  { bin = "rust-analyzer", desc = "Rust language server" },
  { bin = "rustfmt", desc = "Rust formatter" },
  { bin = "cargo-clippy", desc = "Rust linter" },
  { bin = "cmake", desc = "CMake build system" },
  { bin = "ninja", desc = "Ninja build backend" },
  { bin = "gdb", desc = "debugger (fallback DAP adapter)" },
  { bin = "lldb", desc = "debugger (used by codelldb)" },
}

local function check()
  vim.health.start("nvim-ide: external tools")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim " .. tostring(vim.version()))
  else
    vim.health.error("Neovim >= 0.12.0 is required")
  end

  for _, tool in ipairs(tools) do
    if vim.fn.executable(tool.bin) == 1 then
      vim.health.ok(string.format("%s found (%s)", tool.bin, tool.desc))
    else
      vim.health.warn(string.format("%s NOT found — %s", tool.bin, tool.desc), {
        "See README.md → Troubleshooting for the openSUSE/Debian package name.",
      })
    end
  end
end

vim.api.nvim_create_user_command("IDEHealth", function()
  vim.cmd("checkhealth ide")
end, { desc = "Check external tool availability for this config" })

return { check = check }
