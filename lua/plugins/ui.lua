-- Colorscheme, statusline (TS §22), which-key (TS §24). Kept deliberately
-- lean: function over decoration (TS §23).
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        neotree = true,
        telescope = true,
        which_key = true,
        native_lsp = { enabled = true },
        dap = true,
        dap_ui = true,
        treesitter = true,
        mason = true,
        cmp = false,
        indent_blankline = { enabled = false },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          { "filename", path = 1 },
        },
        lualine_x = {
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then
                return ""
              end
              local names = {}
              for _, c in ipairs(clients) do
                table.insert(names, c.name)
              end
              return " " .. table.concat(names, ", ")
            end,
          },
          "diagnostics",
        },
        lualine_y = { "filetype", "encoding" },
        lualine_z = { "location", "progress" },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      win = { border = "rounded" },
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>c", group = "CMake / C++" },
        { "<leader>r", group = "Rust / Cargo" },
        { "<leader>d", group = "Diagnostics / Debug" },
        { "<leader>t", group = "Test" },
      },
    },
  },
}
