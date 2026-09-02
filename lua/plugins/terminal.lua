-- Integrated terminal (TS §21): Ctrl+/ toggle, persistent process across
-- toggles, horizontal/vertical splits. Respects $SHELL (bash/zsh/fish all
-- work unmodified — toggleterm just execs the user's shell).
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    -- NOTE: <leader>t is reserved for the Test group (TS §24), so extra
    -- terminal-direction shortcuts intentionally live outside that prefix;
    -- use :ToggleTerm direction=vertical|horizontal|float directly if needed.
    keys = {
      { "<C-_>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
      { "<C-/>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    },
    opts = {
      shell = vim.o.shell, -- inherits $SHELL; never overrides bash/zsh/fish
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      open_mapping = false, -- mapped explicitly above so both <C-/> and <C-_> work
      direction = "float",
      float_opts = { border = "rounded" },
      persist_size = true,
      close_on_exit = false,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*toggleterm#*",
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("t", lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map("<esc>", [[<C-\><C-n>]], "Exit terminal mode")
          map("<C-h>", [[<Cmd>wincmd h<CR>]], "Go to left window")
          map("<C-j>", [[<Cmd>wincmd j<CR>]], "Go to lower window")
          map("<C-k>", [[<Cmd>wincmd k<CR>]], "Go to upper window")
          map("<C-l>", [[<Cmd>wincmd l<CR>]], "Go to right window")
        end,
      })
    end,
  },
}
