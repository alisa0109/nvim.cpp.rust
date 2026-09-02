-- Colorscheme, statusline (TS §22), which-key (TS §24). Kept deliberately
-- lean: function over decoration (TS §23).
return {
  {
    -- ellisonleao/gruvbox.nvim is the maintained Neovim-native port of
    -- morhetz/gruvbox — same palette/feel, but with proper treesitter/LSP
    -- semantic-highlight groups that the original vimscript plugin doesn't
    -- define (needed for consistent colors across blink.cmp, dap-ui, etc.).
    "ellisonleao/gruvbox.nvim",
    name = "gruvbox",
    priority = 1000,
    lazy = false, -- must load at startup; having `keys` below would
    -- otherwise make lazy.nvim treat this as lazy-loaded and the
    -- colorscheme would only apply after the first <leader>u* keypress
    opts = {
      terminal_colors = true,
      contrast = "hard", -- darkest variant — good contrast for night work
      dim_inactive = true,
      italic = { strings = false, comments = true, folds = true },
    },
    -- Day/night switching: gruvbox is one colorscheme with light/dark
    -- controlled by vim.o.background, unlike Catppuccin's per-flavour names.
    keys = {
      { "<leader>ud", function() vim.o.background = "dark"; vim.cmd.colorscheme("gruvbox") end, desc = "Night theme (dark)" },
      { "<leader>ul", function() vim.o.background = "light"; vim.cmd.colorscheme("gruvbox") end, desc = "Day theme (light)" },
      {
        "<leader>ut",
        function()
          vim.o.background = (vim.o.background == "dark") and "light" or "dark"
          vim.cmd.colorscheme("gruvbox")
        end,
        desc = "Toggle day/night theme",
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.o.background = "dark"
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "gruvbox",
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
        { "<leader>u", group = "UI / Theme" },
      },
    },
  },
}
