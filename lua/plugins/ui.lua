-- Colorscheme, statusline (TS §22), which-key (TS §24). Kept deliberately
-- lean: function over decoration (TS §23).
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      -- Darker/higher-contrast than stock Mocha for comfortable night work:
      -- push the background tiers toward near-black instead of Mocha's
      -- default dark-navy (#1e1e2e), while keeping foreground/accent colors
      -- untouched so syntax highlighting contrast stays the same.
      background = { light = "latte", dark = "mocha" },
      color_overrides = {
        mocha = {
          base = "#0a0a10",
          mantle = "#060609",
          crust = "#020203",
        },
      },
      dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
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
    -- Quick day/night theme switching: Catppuccin ships four flavours
    -- (latte = light, frappe/macchiato/mocha = dark) and registers each as
    -- its own colorscheme, so switching is instant — no reload needed.
    keys = {
      { "<leader>ud", function() vim.o.background = "dark"; vim.cmd.colorscheme("catppuccin-mocha") end, desc = "Night theme (dark)" },
      { "<leader>ul", function() vim.o.background = "light"; vim.cmd.colorscheme("catppuccin-latte") end, desc = "Day theme (light)" },
      {
        "<leader>ut",
        function()
          if (vim.g.colors_name or ""):find("latte") then
            vim.o.background = "dark"
            vim.cmd.colorscheme("catppuccin-mocha")
          else
            vim.o.background = "light"
            vim.cmd.colorscheme("catppuccin-latte")
          end
        end,
        desc = "Toggle day/night theme",
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
        { "<leader>u", group = "UI / Theme" },
      },
    },
  },
}
