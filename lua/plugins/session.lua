-- Session persistence (TS §27): restores open buffers, tabs, splits and cwd
-- on reopening a project. Deliberately does NOT restore terminal buffers/jobs.
return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      options = { "buffers", "curdir", "tabpages", "winsize", "folds" },
    },
    keys = {
      {
        "<leader>ps",
        function() require("persistence").load() end,
        desc = "Restore session for cwd",
      },
      {
        "<leader>pl",
        function() require("persistence").load({ last = true }) end,
        desc = "Restore last session",
      },
      {
        "<leader>pd",
        function() require("persistence").stop() end,
        desc = "Don't save this session on exit",
      },
    },
  },
}
