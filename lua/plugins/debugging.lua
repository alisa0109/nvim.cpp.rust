-- Debugger (TS §19): nvim-dap + nvim-dap-ui for C/C++/Rust. codelldb (mason-
-- installed) is the default adapter; native gdb (`gdb --interpreter=dap`,
-- requires gdb >= 14) is wired in as a documented, no-mason-required
-- fallback. F5/F9/F10/F11/F12 match VS Code/CLion muscle memory (TS §19).
return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-dap" },
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      ensure_installed = { "codelldb" },
      automatic_installation = true,
      handlers = {}, -- default handler wires dap.adapters.codelldb to the mason install
    },
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: start/continue" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
      {
        "<leader>db",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug console (REPL)" },
      { "<leader>dw", function() require("dapui").elements.watches.add(vim.fn.input("Watch expression: ")) end, desc = "Add watch" },
      { "<leader>dx", function() require("dap").terminate() end, desc = "Terminate debug session" },
    },
    config = function()
      local dap = require("dap")

      -- Native gdb DAP mode fallback (no mason/network required, gdb >= 14).
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }

      local function ask_executable()
        return vim.fn.input("Path to executable: ", vim.uv.cwd() .. "/build/", "file")
      end

      local cpp_configs = {
        {
          name = "Launch (codelldb)",
          type = "codelldb",
          request = "launch",
          program = ask_executable,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
        {
          name = "Launch (gdb fallback)",
          type = "gdb",
          request = "launch",
          program = ask_executable,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = false,
        },
      }
      dap.configurations.c = cpp_configs
      dap.configurations.cpp = cpp_configs
      dap.configurations.rust = cpp_configs -- rustaceanvim provides its own richer
      -- configs via `:RustLsp debuggables`; these are the plain nvim-dap fallback.

      require("nvim-dap-virtual-text").setup({})

      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual" })
    end,
  },
}
