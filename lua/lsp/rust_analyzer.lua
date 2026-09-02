-- rust-analyzer settings consumed by rustaceanvim (lua/plugins/lsp.lua sets
-- vim.g.rustaceanvim to a function returning this table). rustaceanvim owns
-- its own client lifecycle instead of going through vim.lsp.config(), which
-- is the one deliberate exception to TS §39 (documented in README).
return {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = { enable = true },
        },
        checkOnSave = true,
        check = {
          command = "clippy",
        },
        procMacro = {
          enable = true,
        },
        inlayHints = {
          bindingModeHints = { enable = false },
          closureReturnTypeHints = { enable = "with_block" },
          lifetimeElisionHints = { enable = "skip_trivial" },
        },
        files = {
          excludeDirs = { "target", ".git" },
        },
      },
    },
  },
}
