-- Native Neovim 0.12 LSP setup (TS §5, §6, §39). clangd is configured with
-- vim.lsp.config()/vim.lsp.enable() directly — never
-- require("lspconfig").clangd.setup{}. rust-analyzer is the one deliberate
-- exception: it's driven through rustaceanvim's own vim.g.rustaceanvim
-- table because rustaceanvim manages its client lifecycle itself (documented
-- in README's LSP section).
local function lsp_keymaps(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Navigation (TS §29) — bare g-prefixed, mirroring vim's own gd convention.
  -- <leader>g is reserved for Git (plugins/git.lua), which is why these are
  -- NOT under <leader>g even though TS §25's illustrative list shows "Space gd".
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
  map("n", "gr", function() require("telescope.builtin").lsp_references() end, "References")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  -- Signature help is shown automatically by blink.cmp while typing inside
  -- parens (plugins/completion.lua); <C-k> is reserved for window navigation.

  -- Actions (TS §25)
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")

  -- Symbols (TS §29)
  map("n", "<leader>fs", function() require("telescope.builtin").lsp_document_symbols() end, "Document symbols")
  map("n", "<leader>fS", function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end, "Workspace symbols")

  -- Call hierarchy (TS §29)
  map("n", "<leader>lci", vim.lsp.buf.incoming_calls, "Incoming calls")
  map("n", "<leader>lco", vim.lsp.buf.outgoing_calls, "Outgoing calls")

  -- LSP housekeeping / inlay hints (TS §30/§31: quick toggle)
  map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", "LSP health")
  map("n", "<leader>lr", "<cmd>LspRestart<cr>", "Restart LSP client")
  map("n", "<leader>lh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
  end, "Toggle inlay hints")
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ide_lsp_attach", { clear = true }),
  callback = function(args)
    lsp_keymaps(args.buf)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    ft = { "c", "cpp", "objc", "objcpp", "cuda" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local clangd_config = require("lsp.clangd")
      clangd_config.capabilities =
        vim.tbl_deep_extend("force", capabilities, clangd_config.capabilities or {})

      vim.lsp.config("clangd", clangd_config)
      vim.lsp.enable("clangd")
    end,
  },

  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false, -- rustaceanvim lazy-loads itself via a rust ftplugin
    init = function()
      vim.g.rustaceanvim = function()
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_blink, blink = pcall(require, "blink.cmp")
        if ok_blink then
          capabilities = blink.get_lsp_capabilities(capabilities)
        end

        local settings = require("lsp.rust_analyzer")
        settings.server.capabilities = capabilities
        return settings
      end
    end,
  },
}
