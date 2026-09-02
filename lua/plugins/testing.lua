-- Testing (TS §20): cargo test via neotest-rust, CTest/GoogleTest via
-- neotest-gtest. Run nearest test, run file, run whole suite, jump to
-- failed tests, inline + summary-panel results.
--
-- Caveat (documented in README): neotest-gtest discovers tests by parsing
-- GoogleTest TEST()/TEST_F() macros with treesitter. A CMake project that
-- uses plain CTest without GoogleTest won't show individual tests here —
-- use <leader>ct (plugins/build.lua, CMakeRunTest/ctest) for those instead.
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "rouge8/neotest-rust",
      "alfaix/neotest-gtest",
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run tests in file" },
      { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show test output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>tj", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Jump to next failed test" },
      { "<leader>tk", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Jump to previous failed test" },
      { "<leader>tx", function() require("neotest").run.stop() end, desc = "Stop running test" },
    },
    opts = function()
      return {
        adapters = {
          require("neotest-rust"),
          require("neotest-gtest").setup({}),
        },
        output = { open_on_run = false },
        summary = { open = "botright vsplit" },
        floating = { border = "rounded" },
      }
    end,
    config = function(_, opts)
      require("neotest").setup(opts)
    end,
  },
}
