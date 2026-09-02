# Neovim C++ / Rust IDE

A modular Neovim configuration that turns Neovim 0.12+ into a full IDE for **C**, **C++**, and **Rust** — native LSP (`vim.lsp.config()`/`vim.lsp.enable()`, no `lspconfig.*.setup{}`), fast completion, treesitter, a file explorer, fuzzy finding, git, formatting, linting, CMake/Cargo build integration, a full debugger, testing, an integrated terminal, sessions, and health checks. Built and verified on **openSUSE Tumbleweed**; the same config works unmodified on Debian/Ubuntu once the equivalent packages are installed.

Design principle: **function over decoration**. No dashboard, no unnecessary background jobs, no plugin installed "just in case."

---

## Table of contents

1. [Requirements](#1-requirements)
2. [Installation](#2-installation)
3. [openSUSE Tumbleweed / Slowroll dependencies](#3-opensuse-tumbleweed--slowroll-dependencies)
4. [Debian / Ubuntu dependencies](#4-debian--ubuntu-dependencies)
5. [Rust setup](#5-rust-setup)
6. [C / C++ setup](#6-c--c-setup)
7. [Neovim installation](#7-neovim-installation)
8. [First startup](#8-first-startup)
9. [compile_commands.json workflow](#9-compile_commandsjson-workflow)
10. [Keybindings](#10-keybindings)
11. [Plugin list](#11-plugin-list)
12. [CMake workflow](#12-cmake-workflow)
13. [Cargo workflow](#13-cargo-workflow)
14. [Debugging](#14-debugging)
15. [Testing](#15-testing)
16. [Git](#16-git)
17. [Troubleshooting](#17-troubleshooting)
18. [Updating the configuration](#18-updating-the-configuration)
19. [Removing the configuration](#19-removing-the-configuration)
20. [Architecture notes](#20-architecture-notes)

---

## 1. Requirements

- **Neovim >= 0.12.0** — this config uses `vim.lsp.config()`, `vim.lsp.enable()`, `vim.treesitter.foldexpr()`, and other 0.12-era APIs. It will refuse to load (with a clear error, see `init.lua`) on older versions.
- `git`, a C/C++ toolchain (`gcc`/`clang`), `clangd`, `cmake`, `ninja`, a Rust toolchain with `rust-analyzer`, `ripgrep`, `fd`.
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for icons (neo-tree, lualine, which-key, diagnostics signs).

Check your version first:

```sh
nvim --version
```

If it's below 0.12.0, see [§7](#7-neovim-installation) before doing anything else.

---

## 2. Installation

**Back up any existing config** (don't skip this — even an "empty" LazyVim starter is worth keeping):

```sh
mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d-%H%M%S)
# also move state/data dirs if you want a truly clean slate:
mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%Y%m%d-%H%M%S)
mv ~/.local/state/nvim ~/.local/state/nvim.backup.$(date +%Y%m%d-%H%M%S)
```

Clone this config:

```sh
git clone <REPOSITORY> ~/.config/nvim
```

Start Neovim:

```sh
nvim
```

`lazy.nvim` bootstraps itself on first launch and installs every plugin automatically. Wait for it to finish (progress shows in a floating window), then restart Neovim once.

---

## 3. openSUSE Tumbleweed / Slowroll dependencies

Verified against a live Tumbleweed snapshot (2026-09) with `zypper`. Because Tumbleweed is rolling, package names occasionally differ from generic tutorials found online — the list below is what actually resolves today.

```sh
sudo zypper install \
  git curl wget \
  gcc gcc-c++ \
  clang clang-tools \
  cmake ninja make \
  gdb lldb \
  ripgrep fd fzf \
  unzip tar gzip \
  python3 \
  nodejs-default npm-default
```

Notes:
- `clangd`, `clang-format`, and `clang-tidy` are **not** separate zypper packages on Tumbleweed — they all ship inside `clang` + `clang-tools`. Installing those two gives you all three binaries.
- `nodejs-default`/`npm-default` are optional — nothing in this config's default plugin set requires Node, but Mason's LSP registry has npm-based servers if you ever add one (`zypper se nodejs` shows the currently versioned packages, e.g. `nodejs24`, if you'd rather pin a version).
- Slowroll tracks the same repos at a slower cadence; the same package names apply, just check `zypper se -i cmake` etc. if something doesn't match — Slowroll can lag Tumbleweed by a few weeks.

Rust is deliberately handled separately — see [§5](#5-rust-setup).

---

## 4. Debian / Ubuntu dependencies

Best-effort — package availability/versions vary a lot more than on Tumbleweed, especially `clangd`'s version on older Ubuntu LTS releases.

```sh
sudo apt update
sudo apt install \
  git curl wget build-essential \
  clang clangd clang-format clang-tidy \
  cmake ninja-build \
  gdb lldb \
  ripgrep fd-find fzf \
  unzip tar gzip \
  python3 \
  nodejs npm
```

Notes:
- On Debian/Ubuntu, `fd-find` installs the binary as `fdfind`, not `fd`. Either `ln -s $(which fdfind) ~/.local/bin/fd` or add `alias fd=fdfind` — Telescope/neo-tree call the plain `fd` name.
- If `apt`'s `clangd` is old (Ubuntu 22.04 ships clangd 14), prefer the upstream LLVM apt repo (`apt.llvm.org`) for a current clangd — better C++20/23 support and fewer false diagnostics.
- Rust: same guidance as Tumbleweed — see [§5](#5-rust-setup), `rustup` is the path of least resistance on any distro.

---

## 5. Rust setup

### Option A — zypper (compiler + cargo only)

```sh
sudo zypper install rust rust-src cargo
```

`rustfmt`, `cargo-fmt`, `cargo-clippy` and `clippy-driver` are already bundled inside the `rust`/`cargo` packages on Tumbleweed — nothing extra to install for those. **There is no `rust-analyzer` zypper package** on Tumbleweed at the time of writing, so you still need Option B (or a standalone binary) for the language server itself.

### Option B — rustup (recommended, gives you rust-analyzer)

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

rustup component add rust-src
rustup component add rust-analyzer
rustup component add rustfmt
rustup component add clippy
```

rust-analyzer needs the Rust standard library source to give completions/go-to-definition into `std`; the official docs recommend installing the `rust-src` component for this — that's why it's listed first above.

Either way, confirm everything is on `PATH`:

```sh
which rustc cargo rustfmt rust-analyzer cargo-clippy
```

If you mix zypper's rust with rustup, make sure only one `cargo`/`rustc` is first on `PATH` — `rustup`'s shims in `~/.cargo/bin` should generally take priority (put `~/.cargo/bin` before `/usr/bin` in `PATH`).

---

## 6. C / C++ setup

Already covered by [§3](#3-opensuse-tumbleweed--slowroll-dependencies)/[§4](#4-debian--ubuntu-dependencies): `clang clang-tools cmake ninja gdb lldb`. Confirm:

```sh
which clangd clang-format clang-tidy cmake ninja gdb lldb
clangd --version   # check it's a reasonably current LLVM (16+) for good C++20/23 support
```

---

## 7. Neovim installation

Tumbleweed's rolling repo tracks upstream Neovim releases closely — a plain `sudo zypper install neovim` is normally enough to get >= 0.12. If `nvim --version` still reports something older (e.g. you're on Leap or a pinned snapshot), install the current release directly instead of waiting on packaging:

```sh
# Option 1: official prebuilt tarball (no root needed, put it on PATH)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar xzf nvim-linux-x86_64.tar.gz
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

# Option 2: official AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim
```

Never pipe an installer script straight into `sh` from this README or any other source without reading it first (see [§20](#20-architecture-notes) on security posture) — the commands above only fetch a signed release tarball/AppImage, not a script.

This config intentionally does **not** silently downgrade its own feature set on old Neovim — it refuses to load and tells you why (see the top of `init.lua`).

---

## 8. First startup

1. `nvim` — `lazy.nvim` bootstraps and installs plugins automatically.
2. `:Lazy sync` — re-run any time you want to double check everything installed/updated cleanly.
3. `:checkhealth` and `:IDEHealth` — the latter is this config's own fast check for `clangd`, `rust-analyzer`, `cmake`, `gdb`, etc. actually being on `PATH` (see `lua/ide/health.lua`).
4. `:Mason` — only used here to install `codelldb`, the default debug adapter (`lua/plugins/debugging.lua` triggers this automatically the first time you use `<F5>`/`<leader>db`, but you can run it manually too). Everything else (`clangd`, `rust-analyzer`, formatters) is expected to already be a system package — this config never duplicates what your package manager already gives you.

---

## 9. compile_commands.json workflow

clangd needs a compilation database to know your real include paths, defines, and language standard — without one it falls back to guessing and diagnostics get noisy/wrong. This config **never hardcodes `-std=c++17` or similar** (`lua/lsp/clangd.lua`) — flags always come from your project.

Generate it with CMake:

```sh
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

`lua/lsp/clangd.lua`'s root-detection looks for `compile_commands.json` in, in order: the project root itself, then `build/`, `build-debug/`, `build-release/`, `build-relwithdebinfo/`, `out/build/`, `cmake-build-debug/`, `cmake-build-release/`. If it can't find one anywhere, clangd still starts (falls back to a best-effort config from `CMakeLists.txt`/`.git`) and you get a one-time `vim.notify` warning telling you exactly what to run — it never just silently breaks.

For Meson: `meson setup build` already emits `build/compile_commands.json` — no extra flag needed.

For plain Makefiles: generate one with [`bear`](https://github.com/rizsotto/Bear) (`bear -- make`) or [`compiledb`](https://github.com/nickdiego/compiledb).

---

## 10. Keybindings

Leader is **Space**. `<C-h/j/k/l>` always means "move to the window in that direction" — it works identically in normal-mode buffers and inside the integrated terminal.

Two deliberate resolutions of ambiguity in the original spec, so there's no reference to hunt for elsewhere:
- **LSP navigation is bare `g*`, not `<leader>g*`** — `<leader>g` is reserved entirely for Git. `gd`/`gD`/`gi`/`gy`/`gr`/`K` follow the same convention as Vim's own `gd`.
- **`<leader>d` is the Diagnostics *and* Debug group** — diagnostic nav (`dn`/`dp`) lives there because the spec puts it there explicitly; the primary debug flow uses F-keys (industry-standard muscle memory: F5/F9/F10/F11/F12), with a few DAP-UI extras (`db`/`du`/`dr`/`dw`/`dx`) filling the rest of that same prefix.

### General

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Move to window left/down/up/right |
| `<C-Up/Down/Left/Right>` | Resize current window |
| `<esc>` | Clear search highlight |
| `<C-d>` / `<C-u>` | Half-page down/up, centered |
| `<leader>e` | Diagnostic float (current line) |
| `<leader>q` | Send diagnostics to quickfix |
| `<leader>dn` / `<leader>dp` | Next / previous diagnostic |
| `<C-/>` / `<C-_>` | Toggle terminal |

### LSP (bare `g`, buffer-local once a server attaches)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `gr` | Find references (Telescope) |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action (normal + visual) |
| `<leader>fs` / `<leader>fS` | Document / workspace symbols |
| `<leader>lci` / `<leader>lco` | Incoming / outgoing calls |
| `<leader>li` | Open `:checkhealth vim.lsp` |
| `<leader>lr` | Restart LSP client |
| `<leader>lh` | Toggle inlay hints |
| signature help | shown automatically while typing inside `(...)` |

### Find (Telescope)

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `<leader>fr` | Recent files |
| `<leader>fd` | Diagnostics |
| `<leader>fw` | Grep word under cursor |
| `<leader>fe` | Toggle file explorer (neo-tree) |
| `<leader>fc` / `<leader>fB` | Git commits / branches |

### Git (gitsigns)

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk |
| `<leader>gs` | Stage hunk (normal + visual) |
| `<leader>gr` | Reset hunk |
| `<leader>gR` | Reset entire buffer |
| `<leader>gu` | Undo stage hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gtb` | Toggle inline blame |
| `<leader>gd` | Diff against index |
| `<leader>gc` / `<leader>gC` | Commits (repo / current buffer) |
| `<leader>gB` | Branches |

### CMake / C++ (`lua/plugins/build.lua`)

Auto-detects CMake vs. plain Make/Ninja/Meson per project (`§9`/root detection); CMake gets the richer workflow.

| Key | Action |
|---|---|
| `<leader>cg` | CMake configure/generate |
| `<leader>cb` | Build |
| `<leader>cr` | Run |
| `<leader>ct` | Test (CTest) |
| `<leader>cc` | Clean |
| `<leader>cs` | Select build type (Debug/Release/RelWithDebInfo) |
| `<leader>cT` | Select build target |
| `<leader>cL` | Select launch target |
| `<leader>cd` | Debug via CMake (launches DAP) |
| `<leader>cf` | Format file/selection (clang-format, works for any filetype conform.nvim knows) |

### Rust / Cargo (`lua/plugins/build.lua`)

| Key | Action |
|---|---|
| `<leader>rb` | `cargo build` |
| `<leader>rr` | `cargo run` |
| `<leader>rt` | `cargo test` |
| `<leader>rc` | `cargo check` |
| `<leader>rcl` | `cargo clippy` |
| `<leader>rf` | `cargo fmt` |

> `<leader>rc` and `<leader>rcl` share a prefix, so pressing `<leader>rc` has a short (`timeoutlen = 300ms`) pause before it fires, while Neovim waits to see if you're typing `rcl` instead — that's inherent to having both bindings, not a bug.

### Debug (nvim-dap)

| Key | Action |
|---|---|
| `F5` | Start / continue |
| `F9` | Toggle breakpoint |
| `F10` | Step over |
| `F11` | Step into |
| `F12` | Step out |
| `<leader>db` | Conditional breakpoint |
| `<leader>du` | Toggle debug UI |
| `<leader>dr` | Toggle debug console (REPL) |
| `<leader>dw` | Add watch expression |
| `<leader>dx` | Terminate session |

### Test (neotest)

| Key | Action |
|---|---|
| `<leader>tt` | Run nearest test |
| `<leader>tf` | Run tests in file |
| `<leader>ta` | Run all tests |
| `<leader>ts` | Toggle summary panel |
| `<leader>to` | Show output for nearest test |
| `<leader>tO` | Toggle output panel |
| `<leader>tj` / `<leader>tk` | Jump to next / previous failed test |
| `<leader>tx` | Stop running test |

### Sessions / misc

| Key | Action |
|---|---|
| `<leader>ps` | Restore session for cwd |
| `<leader>pl` | Restore last session |
| `<leader>pd` | Don't save this session on exit |
| `<leader>bo` / `<leader>br` | Toggle / run generic build task panel (overseer) |
| `gnn` / `grn` / `grm` | Treesitter incremental selection: init / expand / shrink |
| `af`/`if`, `ac`/`ic`, `aa`/`ia` | Treesitter textobjects: function, class, parameter |
| `]f`/`[f`, `]c`/`[c` | Jump to next/previous function/class start |

---

## 11. Plugin list

| Plugin | Purpose |
|---|---|
| `folke/lazy.nvim` | Plugin manager |
| `neovim/nvim-lspconfig` | Base LSP server definitions (clangd wired via native `vim.lsp.config`) |
| `mrcjkb/rustaceanvim` | rust-analyzer client, Cargo-aware, runnables/debuggables |
| `saghen/blink.cmp` | Completion + snippet engine |
| `rafamadriz/friendly-snippets` | Snippet collection (C/C++/Rust and more) |
| `nvim-treesitter/nvim-treesitter` (main) | Parser install; highlighting/indent/fold via native `vim.treesitter` |
| `nvim-treesitter/nvim-treesitter-textobjects` (main) | Function/class/parameter textobjects, motions |
| `nvim-neo-tree/neo-tree.nvim` | File explorer with git status |
| `nvim-telescope/telescope.nvim` (+ fzf-native) | Fuzzy finder |
| `lewis6991/gitsigns.nvim` | Git signs, hunks, blame |
| `stevearc/conform.nvim` | Formatting (clang-format, rustfmt) |
| `stevearc/overseer.nvim` | Generic task runner (quickfix-backed) for Make/Ninja/Meson/Cargo |
| `Civitasv/cmake-tools.nvim` | CMake configure/build/run/test/clean/targets |
| `mfussenegger/nvim-dap` (+ dap-ui, dap-virtual-text, nvim-nio) | Debugger |
| `mason-org/mason.nvim` + `jay-babu/mason-nvim-dap.nvim` | Installs `codelldb` only |
| `nvim-neotest/neotest` (+ neotest-rust, neotest-gtest) | Test runner |
| `akinsho/toggleterm.nvim` | Integrated terminal |
| `nvim-lualine/lualine.nvim` | Statusline |
| `folke/which-key.nvim` | Keymap hints |
| `folke/persistence.nvim` | Session save/restore |
| `catppuccin/nvim` | Colorscheme (with integrations for every plugin above) |

---

## 12. CMake workflow

1. Open a file inside a project with `CMakeLists.txt` at its root.
2. `<leader>cg` — configure (also regenerates `compile_commands.json`, symlinked to the project root automatically by `cmake-tools.nvim`, so clangd always finds it).
3. `<leader>cs` — pick Debug / Release / RelWithDebInfo.
4. `<leader>cb` — build.
5. `<leader>cT` / `<leader>cL` — pick a specific build/launch target if the project has more than one.
6. `<leader>cr` — run the selected launch target.
7. `<leader>ct` — run CTest.
8. `<leader>cd` — build + launch under the debugger in one step.
9. `<leader>cc` — clean.

If there's no `CMakeLists.txt` but there is a `Makefile`, `meson.build`, or `build.ninja`, the same `<leader>cb`/`<leader>cr`(n/a)/`<leader>ct`/`<leader>cc` keys fall back to running `make`/`ninja`/`meson compile` directly through `overseer.nvim` (output in the task panel, `<leader>bo` to reopen it).

---

## 13. Cargo workflow

Open any file inside a Cargo workspace (or a single-crate project) — rustaceanvim attaches rust-analyzer automatically, workspace-aware (multi-crate workspaces, build scripts, proc macros, `dev-dependencies`, examples, benches).

- `<leader>rc` — `cargo check` (fast, use this while iterating)
- `<leader>rcl` — `cargo clippy`
- `<leader>rb` / `<leader>rr` / `<leader>rt` — build / run / test
- `<leader>rf` — `cargo fmt` (whole workspace; `<leader>cf` formats just the current buffer via rustfmt)
- `:RustLsp runnables` / `:RustLsp debuggables` — rustaceanvim's own picker for `#[test]` functions, `main`, examples, benches, including inline "▶ Run"/"⚙ Debug" virtual text if you enable it

Inlay hints are on by default; toggle per-buffer with `<leader>lh`.

---

## 14. Debugging

Default adapter is **codelldb** (installed once via Mason, `:Mason` → search `codelldb`, or it installs automatically the first time `mason-nvim-dap` runs). It works for C, C++, and Rust binaries identically — no per-language adapter juggling.

1. Build with debug info: CMake → `<leader>cs` pick **Debug**, then `<leader>cb`. Cargo → debug builds are the default (`cargo build`, not `--release`).
2. `F9` on the line you want to stop at.
3. `F5` — pick "Launch (codelldb)" from the prompt (or "Launch (gdb fallback)" if you'd rather use plain gdb — no Mason/network required for that path, just needs system `gdb >= 14` for `--interpreter=dap`).
4. Enter the path to the built executable when prompted.
5. `F10`/`F11`/`F12` to step; the UI (`nvim-dap-ui`) shows scopes/variables, call stack, breakpoints, watches, and the console automatically while a session is active — `<leader>du` to toggle it back if you close it.
6. `<leader>dw` to add a watch expression, `<leader>db` for a conditional breakpoint, `<leader>dr` for the raw debug console/REPL, `<leader>dx` to terminate.

For CMake projects, `<leader>cd` skips steps 1-3 above — it builds and launches the debugger against the selected launch target in one command.

---

## 15. Testing

- **Rust**: `neotest-rust` discovers `#[test]` functions via treesitter — `<leader>tt` on/inside a test function runs just that one; `<leader>tf` runs every test in the file; `<leader>ta` runs the whole workspace.
- **C++ (GoogleTest)**: `neotest-gtest` discovers `TEST()`/`TEST_F()` macros the same way — same keys.
- **C++ (plain CTest, no GoogleTest)**: `neotest-gtest` only understands GoogleTest's macros, so a CTest suite that isn't GoogleTest-based won't show individual tests in neotest. Use `<leader>ct` (`lua/plugins/build.lua`) instead — it runs the whole CTest suite through CMake/overseer with `--output-on-failure`, results land in the quickfix list (`<leader>q`-style navigation).
- `<leader>tj`/`<leader>tk` jump between failed tests after a run; `<leader>to` opens the failure output for the test under the cursor; `<leader>ts` toggles the persistent summary panel (pass/fail tree for the whole project).

---

## 16. Git

`gitsigns.nvim` gives inline hunk signs in the sign column immediately on opening any file inside a git repo — no setup needed. Stage/reset/preview/blame hunks with the keys in [§10](#10-keybindings); `<leader>gc`/`<leader>gB` open Telescope pickers for commits/branches (works from any buffer, not just inside a git-aware plugin window).

---

## 17. Troubleshooting

| Symptom | Likely cause | Check | Fix |
|---|---|---|---|
| `clangd not found` / no C++ completion | `clang-tools` not installed, or not on `PATH` | `which clangd` | `sudo zypper install clang clang-tools` (Tumbleweed) / `sudo apt install clangd` (Debian/Ubuntu) |
| `rust-analyzer not found` / no Rust completion | It's genuinely not packaged on Tumbleweed by default | `which rust-analyzer` | `rustup component add rust-analyzer` (see [§5](#5-rust-setup)) |
| `cargo not found` | Rust toolchain not installed, or installed but not on `PATH` | `which cargo`; `echo $PATH` | Install per [§5](#5-rust-setup); if using rustup, make sure `~/.cargo/bin` is in `PATH` (rustup's installer adds this to your shell rc — restart your shell or `source "$HOME/.cargo/env"`) |
| `compile_commands.json missing` (clangd warns on open) | No CMake configure step run yet, or a non-standard build dir name | Look for the warning's listed search paths | `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` (see [§9](#9-compile_commandsjson-workflow)) |
| LSP not starting at all | Wrong filetype detected, or the binary genuinely isn't installed | `:lua print(vim.bo.filetype)`; `:checkhealth vim.lsp`; `:IDEHealth` | Confirm filetype is `c`/`cpp`/`rust`; install the missing tool |
| Treesitter parser missing (no highlighting for a filetype) | Parser not yet compiled — happens once per parser, needs a C compiler | `:TSUpdate`; check for a `cc`/`gcc`/`clang` on `PATH` (parser compilation needs one) | `sudo zypper install gcc` if missing, then `:TSUpdate` again |
| Debugger not found | `codelldb` not installed yet, or `gdb` too old for the DAP fallback | `:Mason` (search codelldb); `gdb --version` (need >= 14 for `--interpreter=dap`) | `:MasonInstall codelldb`, or `sudo zypper install gdb` and pick "Launch (gdb fallback)" at the `F5` prompt |
| CMake not found | Not installed | `which cmake` | `sudo zypper install cmake` |
| `ripgrep not found` (Telescope live_grep does nothing) | `rg` not installed | `which rg` | `sudo zypper install ripgrep` |
| PATH problems in general | Shell rc not sourced in the terminal Neovim was launched from, or a GUI-launched terminal with a different `PATH` than your interactive shell | `nvim -c 'echo $PATH' -c q` from the same terminal you normally use | Make sure `~/.cargo/bin`, `~/.local/bin` etc. are exported in the shell config that actually runs for non-interactive/login shells too (`.profile`/`.zprofile`, not just `.bashrc`/`.zshrc`, if you launch Neovim from a GUI launcher) |

---

## 18. Updating the configuration

```sh
cd ~/.config/nvim
git pull
nvim +Lazy sync
```

---

## 19. Removing the configuration

```sh
rm -rf ~/.config/nvim
mv ~/.config/nvim.backup.<timestamp> ~/.config/nvim
# optionally also restore/clean plugin state:
rm -rf ~/.local/share/nvim ~/.local/state/nvim
mv ~/.local/share/nvim.backup.<timestamp> ~/.local/share/nvim   # if you made one
mv ~/.local/state/nvim.backup.<timestamp> ~/.local/state/nvim   # if you made one
```

---

## 20. Architecture notes

- **No monolithic `init.lua`.** It only sets `mapleader`/`maplocalleader` and requires four small modules under `lua/config/`, in an order that matters (leader before lazy.nvim, since which-key/keymaps read it at registration time).
- **Native LSP API only**, with one documented, deliberate exception: `rustaceanvim` configures rust-analyzer through `vim.g.rustaceanvim` rather than `vim.lsp.config()`, because rustaceanvim manages its own client lifecycle (it needs to, to support things like `:RustLsp debuggables` and rebuilding proc-macros) — it is *not* the legacy `require("lspconfig").rust_analyzer.setup{}` pattern the spec forbids. `clangd` uses `vim.lsp.config()`/`vim.lsp.enable()` exclusively (`lua/plugins/lsp.lua`, `lua/lsp/clangd.lua`).
- **nvim-treesitter's `main` branch only installs parsers.** Neovim 0.12 has native treesitter highlighting; the old `nvim-treesitter.configs` module that used to also turn on highlighting/indent no longer exists upstream, so this config starts them itself per-buffer via a `FileType` autocmd (`lua/config/autocmds.lua`) calling `vim.treesitter.start()`.
- **Security**: nothing here pipes a downloaded script into a shell. Mason installs go through its own registry and only ever install `codelldb`. Build/run/test/debug commands only ever execute when you press the corresponding key — nothing runs automatically on opening a file or a project.
- **No hardcoded paths, usernames, or machine-specific assumptions** — everything is derived from `vim.fn.stdpath(...)`, `vim.uv.cwd()`, or LSP/build-system root detection (`.git`, `CMakeLists.txt`, `Cargo.toml`, `compile_commands.json`, `Makefile`, `meson.build`, checked in that priority order).
