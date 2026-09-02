-- Parser installation only (nvim-treesitter "main" branch). Highlighting,
-- indent and folding are enabled per-buffer in config/autocmds.lua /
-- config/options.lua using Neovim 0.12's built-in vim.treesitter APIs.
local ensure_installed = {
  "c",
  "cpp",
  "rust",
  "lua",
  "bash",
  "json",
  "yaml",
  "toml",
  "markdown",
  "markdown_inline",
  "vimdoc",
  "query",
  "regex",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false, -- parsers must be available before FileType autocmds fire
    config = function()
      require("nvim-treesitter").install(ensure_installed)

      -- Incremental selection (init_selection/node_incremental/node_decremental/
      -- scope_incremental from the old nvim-treesitter.configs module), reimplemented
      -- directly on top of vim.treesitter since that module no longer exists.
      local incremental_stack = {}

      local function set_visual_selection(node, buf)
        local srow, scol, erow, ecol = node:range()
        vim.api.nvim_buf_set_mark(buf, "<", srow + 1, scol, {})
        vim.api.nvim_buf_set_mark(buf, ">", erow + 1, math.max(ecol - 1, 0), {})
        vim.cmd("normal! gv")
      end

      vim.keymap.set("n", "gnn", function()
        local buf = vim.api.nvim_get_current_buf()
        local node = vim.treesitter.get_node()
        if not node then
          return
        end
        incremental_stack = { node }
        set_visual_selection(node, buf)
      end, { desc = "Init treesitter incremental selection" })

      vim.keymap.set("x", "grn", function()
        local buf = vim.api.nvim_get_current_buf()
        local current = incremental_stack[#incremental_stack]
        local parent = current and current:parent()
        if parent then
          table.insert(incremental_stack, parent)
          set_visual_selection(parent, buf)
        end
      end, { desc = "Expand treesitter selection" })

      vim.keymap.set("x", "grm", function()
        local buf = vim.api.nvim_get_current_buf()
        if #incremental_stack > 1 then
          table.remove(incremental_stack)
          set_visual_selection(incremental_stack[#incremental_stack], buf)
        end
      end, { desc = "Shrink treesitter selection" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
          },
        },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local map = vim.keymap.set

      -- Text objects: af/if function, ac/ic class, aa/ia parameter
      for _, m in ipairs({ "x", "o" }) do
        map(m, "af", function() select.select_textobject("@function.outer", "textobjects") end, { desc = "Around function" })
        map(m, "if", function() select.select_textobject("@function.inner", "textobjects") end, { desc = "Inside function" })
        map(m, "ac", function() select.select_textobject("@class.outer", "textobjects") end, { desc = "Around class" })
        map(m, "ic", function() select.select_textobject("@class.inner", "textobjects") end, { desc = "Inside class" })
        map(m, "aa", function() select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
        map(m, "ia", function() select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Inside parameter" })
      end

      map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function start" })
      map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class start" })
      map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Previous function start" })
      map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Previous class start" })
    end,
  },
}
