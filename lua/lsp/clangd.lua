-- clangd config table consumed by vim.lsp.config('clangd', ...) in
-- lua/plugins/lsp.lua (TS §5, §17, §30 — native 0.12 API only, no
-- lspconfig.clangd.setup{}). Never hardcodes -std=c++NN: compile flags must
-- come from the project's own compile_commands.json.
local build_dir_candidates = {
  "build",
  "build-debug",
  "build-release",
  "build-relwithdebinfo",
  "out/build",
  "cmake-build-debug",
  "cmake-build-release",
}

--- Look for compile_commands.json in the project root or one of the common
--- CMake build-directory names underneath it.
local function find_compile_commands(root)
  if vim.uv.fs_stat(root .. "/compile_commands.json") then
    return root
  end
  for _, dir in ipairs(build_dir_candidates) do
    local candidate = root .. "/" .. dir
    if vim.uv.fs_stat(candidate .. "/compile_commands.json") then
      return candidate
    end
  end
  return nil
end

local warned_dirs = {}

local function root_dir(bufnr, on_dir)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  -- Highest priority: a directory that already has (or is near) a
  -- compile_commands.json, since that's what actually drives clangd.
  local cc_root = vim.fs.root(bufname, "compile_commands.json")
    or vim.fs.root(bufname, function(name)
      return name == "CMakeLists.txt" or name == "Makefile" or name == "meson.build" or name == ".git"
    end)

  local project_root = cc_root or vim.fs.dirname(bufname)
  local compile_db_dir = find_compile_commands(project_root)

  if not compile_db_dir and not warned_dirs[project_root] then
    warned_dirs[project_root] = true
    vim.schedule(function()
      vim.notify(
        "clangd: no compile_commands.json found under "
          .. project_root
          .. " (checked project root and build*/ dirs).\n"
          .. "Generate one with: cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON\n"
          .. "clangd will still start with a best-effort fallback config.",
        vim.log.levels.WARN,
        { title = "clangd" }
      )
    end)
  end

  on_dir(project_root)
end

return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed",
    "--header-insertion=iwyu", "--function-arg-placeholders", "--fallback-style=llvm" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  root_dir = root_dir,
  capabilities = {
    textDocument = {
      completion = { editsNearCursor = true },
    },
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
}
