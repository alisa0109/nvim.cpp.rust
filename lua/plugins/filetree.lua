-- File explorer (TS §10): create/rename/delete/copy/move files, open a
-- terminal in a directory, show git status inline.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    -- NOTE: <leader>e is reserved for the diagnostic float (TS §28), so the
    -- explorer toggle lives under the Find group instead.
    keys = {
      { "<leader>fe", "<cmd>Neotree toggle reveal<cr>", desc = "Toggle file explorer" },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      default_component_configs = {
        git_status = {
          symbols = {
            added = "✚",
            modified = "",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          },
        },
      },
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = {
        mappings = {
          ["t"] = "open_tabnew",
          ["o"] = "open",
        },
      },
    },
  },
}
