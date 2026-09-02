-- Build system integration (TS §15-§18, §26): CMake, Make, Ninja, Meson for
-- C/C++ via cmake-tools.nvim (+ overseer.nvim fallback for plain
-- Make/Ninja/Meson projects with no CMakeLists.txt), and Cargo for Rust.
-- Everything here runs strictly on an explicit keymap/command — nothing
-- executes automatically on file open (TS §43).

--- Walk up from cwd looking for the first directory containing any of
--- markers, in priority order (TS §26: .git, CMakeLists.txt,
--- compile_commands.json, Cargo.toml, Makefile, meson.build).
local function project_root()
  local markers = { "CMakeLists.txt", "Cargo.toml", "compile_commands.json", "Makefile", "meson.build", ".git" }
  local found = vim.fs.root(0, markers)
  return found or vim.uv.cwd()
end

local function detect_build_system(root)
  if vim.uv.fs_stat(root .. "/CMakeLists.txt") then
    return "cmake"
  elseif vim.uv.fs_stat(root .. "/meson.build") then
    return "meson"
  elseif vim.uv.fs_stat(root .. "/build.ninja") then
    return "ninja"
  elseif vim.uv.fs_stat(root .. "/Makefile") or vim.uv.fs_stat(root .. "/makefile") then
    return "make"
  end
  return nil
end

--- Run a shell command as an overseer task (quickfix-backed) for the plain
--- Make/Ninja/Meson case, i.e. no CMakeLists.txt driving things.
local function run_task(name, cmd, root)
  local overseer = require("overseer")
  overseer.new_task({
    name = name,
    cmd = cmd,
    cwd = root,
    components = { "default" },
  }):start()
  vim.cmd("OverseerOpen!")
end

local function cmake_or_fallback(cmake_fn, fallback_cmd, label)
  return function()
    local root = project_root()
    local system = detect_build_system(root)
    if system == "cmake" then
      cmake_fn()
    elseif fallback_cmd then
      run_task(label, fallback_cmd(system, root), root)
    else
      vim.notify("No CMakeLists.txt/Makefile/meson.build/build.ninja found under " .. root, vim.log.levels.WARN)
    end
  end
end

local function cargo(subcmd)
  return function()
    local cmd = { "cargo" }
    vim.list_extend(cmd, vim.split(subcmd, " "))
    run_task("cargo " .. subcmd, cmd, project_root())
  end
end

return {
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen" },
    keys = {
      { "<leader>bo", "<cmd>OverseerToggle<cr>", desc = "Toggle task panel" },
      { "<leader>br", "<cmd>OverseerRun<cr>", desc = "Run task" },
      -- Rust / Cargo shortcuts (TS §18)
      { "<leader>rb", cargo("build"), desc = "cargo build" },
      { "<leader>rr", cargo("run"), desc = "cargo run" },
      { "<leader>rt", cargo("test"), desc = "cargo test" },
      { "<leader>rc", cargo("check"), desc = "cargo check" },
      { "<leader>rcl", cargo("clippy"), desc = "cargo clippy" },
      { "<leader>rf", cargo("fmt"), desc = "cargo fmt" },
    },
    opts = {
      task_list = { direction = "bottom" },
    },
  },

  {
    "Civitasv/cmake-tools.nvim",
    dependencies = { "stevearc/overseer.nvim" },
    cmd = {
      "CMakeGenerate",
      "CMakeBuild",
      "CMakeRun",
      "CMakeDebug",
      "CMakeClean",
      "CMakeSelectBuildType",
      "CMakeSelectBuildTarget",
      "CMakeSelectLaunchTarget",
      "CMakeRunTest",
    },
    opts = {
      cmake_command = "cmake",
      cmake_build_directory = "build/${variant:buildType}",
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
      cmake_soft_link_compile_commands = true,
      cmake_dap_configuration = { name = "cpp", type = "codelldb", request = "launch" },
    },
    keys = {
      { "<leader>cg", "<cmd>CMakeGenerate<cr>", desc = "CMake configure" },
      {
        "<leader>cb",
        cmake_or_fallback(function()
          vim.cmd("CMakeBuild")
        end, function(system, root)
          if system == "ninja" then
            return { "ninja", "-C", "build" }
          elseif system == "meson" then
            return { "meson", "compile", "-C", "build" }
          end
          return { "make", "-C", root }
        end, "build"),
        desc = "Build",
      },
      {
        "<leader>cr",
        cmake_or_fallback(function()
          vim.cmd("CMakeRun")
        end),
        desc = "Run",
      },
      {
        "<leader>ct",
        cmake_or_fallback(function()
          vim.cmd("CMakeRunTest")
        end, function(_, root)
          return { "ctest", "--test-dir", root .. "/build", "--output-on-failure" }
        end, "test"),
        desc = "Test",
      },
      {
        "<leader>cc",
        cmake_or_fallback(function()
          vim.cmd("CMakeClean")
        end, function(system, root)
          if system == "ninja" then
            return { "ninja", "-C", "build", "clean" }
          elseif system == "meson" then
            return { "meson", "compile", "-C", "build", "--clean" }
          end
          return { "make", "-C", root, "clean" }
        end, "clean"),
        desc = "Clean",
      },
      { "<leader>cs", "<cmd>CMakeSelectBuildType<cr>", desc = "Select build type (Debug/Release/RelWithDebInfo)" },
      { "<leader>cT", "<cmd>CMakeSelectBuildTarget<cr>", desc = "Select build target" },
      { "<leader>cL", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "Select launch target" },
      { "<leader>cd", "<cmd>CMakeDebug<cr>", desc = "Debug (via CMake)" },
    },
  },
}
