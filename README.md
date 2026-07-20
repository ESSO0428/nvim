---
title: My Neovim Config
author: Andy6
date: 2025-08-16
---

# My Neovim Config

<p align="right">
  <strong>English</strong> | <a href="./README.zh-TW.md">繁體中文</a>
</p>

<!--toc:start-->
- [My Neovim Config](#my-neovim-config)
  - [Introduction](#introduction)
  - [Supported Neovim Version](#supported-neovim-version)
  - [Installation](#installation)
  - [Optional: Reuse old LunarVim data paths](#optional-reuse-old-lunarvim-data-paths)
  - [Notes](#notes)
    - [Neovim binary installation on normal vs old servers](#neovim-binary-installation-on-normal-vs-old-servers)
    - [Tree-sitter / nvim-treesitter requirements](#tree-sitter--nvim-treesitter-requirements)
    - [How to check whether npm is still shadowing tree-sitter](#how-to-check-whether-npm-is-still-shadowing-tree-sitter)
    - [Quick recovery steps for mismatched parser / query state](#quick-recovery-steps-for-mismatched-parser--query-state)
    - [Copilot](#copilot)
    - [CopilotChat](#copilotchat)
<!--toc:end-->

## Introduction

> [!NOTE]
>
> This is my **Neovim** config.
> It is no longer a LunarVim config, although parts of the setup were originally migrated from an older LunarVim-based environment.
>
> Current status:
> - Pure `nvim` config
> - Plugin management via `lazy.nvim`
> - Some old compatibility/migration logic is still kept for my own workflow

## Supported Neovim Version

Current target:

```bash
NVIM v0.12.3
```

If you use a much older Neovim version, some features may not work correctly.

## Installation

1. Clone this repo to `~/.config/nvim`

   ```bash
   cd ~/.config
   git clone git@github.com:ESSO0428/lvim.git nvim
   ```

   or

   ```bash
   cd ~/.config
   git clone https://github.com/ESSO0428/lvim.git nvim
   ```

2. Install a compatible Neovim binary first

   Current target:

   ```bash
   NVIM v0.12.3
   ```

   Recommended options:
   - normal desktop/server with sufficiently new `glibc`: `bob`
   - older server with old `glibc`: compile Neovim locally instead of relying on prebuilt binaries

3. Start Neovim once

   ```bash
   nvim
   ```

   `lazy.nvim` will bootstrap itself and install plugins automatically.

4. Common external dependencies

   Recommended tools:
   - `git`
   - `ripgrep` (`rg`)
   - `fd`
   - `node >= 18`
   - `python3`
   - `gcc` or `clang`
   - `make`
   - `tree-sitter` CLI `>= 0.26.1` for the current `nvim-treesitter` setup

   Optional but useful:
   - `lazygit`
   - `debugpy`
   - `bat`
   - `exa`

> [!IMPORTANT]
>
> This config uses `nvim-treesitter` **main** branch on Neovim `0.12.3`.
> Do **not** pair this config with the old `nvim-treesitter` `master` branch.
> Also prefer installing `tree-sitter` via your system package manager or a local Cargo build, **not** the global npm package.

## Optional: Reuse old LunarVim data paths

If you are migrating from my older LunarVim environment, this config can temporarily reuse old LunarVim user-data paths.

See:

- `lua/opt.lua`

You can switch the path profile there:

```lua
local path_profile = "lvim" -- or "nvim"
```

- `"lvim"`: reuse old LunarVim data/state/cache paths
- `"nvim"`: use normal Neovim paths

There is also a migration helper:

```bash
make migrate-help
make migrate-all
```

## Notes

### Neovim binary installation on normal vs old servers

For `NVIM v0.12.3`, `bob` is convenient on machines with a sufficiently new system library stack.

Recommended `bob` install paths:

- official script

  ```bash
  curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
  ```

- or a local Cargo build

  ```bash
  cargo install bob-nvim --locked
  ```

Important caveats learned during setup:

- Recent `bob-nvim` releases require **Rust 1.85+**. If `cargo install bob-nvim` fails because `rustc` is too old, update via `rustup` first.
- On older servers, even the official `bob` release binary or AppImage can fail with errors such as:

  ```bash
  bob: /lib64/libc.so.6: version `GLIBC_2.39' not found
  ```

- If that happens, do **not** keep retrying the release zip/AppImage. Build `bob` locally on that machine, or skip `bob` entirely and compile Neovim locally.
- If your only goal is a usable `nvim v0.12.3` on an old server, compiling Neovim locally is often simpler than forcing `bob` to work.

### Tree-sitter / nvim-treesitter requirements

This config currently uses:

- Neovim `v0.12.3`
- `nvim-treesitter` **main** branch (`lua/plugins/treesitter.lua`)
- `tree-sitter` CLI `>= 0.26.1`

Important caveats:

- Do **not** combine Neovim `0.12.x` with the old `nvim-treesitter` `master` branch.
- If `:checkhealth nvim-treesitter` still shows wording like `only needed for :TSInstallFromGrammar`, you are probably still loading the old `master`-style plugin/runtime stack somewhere.
- The global npm `tree-sitter-cli` package may ship a prebuilt binary linked against a newer `glibc`, causing `tree-sitter build` to fail even though the command exists.
- Prefer a distro package or a local Cargo build for `tree-sitter`.

Useful install paths for `tree-sitter` CLI:

- preferred: system package manager
- fallback: Cargo full build

  ```bash
  cargo install tree-sitter-cli --locked
  ```

- minimal workaround when only `tree-sitter build` is needed and full Cargo build fails inside `rquickjs` / `bindgen`

  ```bash
  cargo install tree-sitter-cli --locked --no-default-features --force
  ```

Common Cargo-side failure patterns:

- `Unable to find libclang`
  - install `clang-devel` / `libclang-dev`, or set `LIBCLANG_PATH`
- `fatal error: 'stdbool.h' file not found`
  - `bindgen` found `libclang`, but its include path is wrong; set `BINDGEN_EXTRA_CLANG_ARGS` to include your GCC / system headers

Example:

```bash
BINDGEN_EXTRA_CLANG_ARGS='-I/opt/rh/gcc-toolset-13/root/usr/lib/gcc/x86_64-redhat-linux/13/include -I/usr/include' \
cargo install tree-sitter-cli --locked
```

### How to check whether npm is still shadowing tree-sitter

Shell-side checks:

```bash
which tree-sitter
tree-sitter --version
npm list -g tree-sitter-cli --depth=0
```

Neovim-side checks:

```vim
:echo exepath('tree-sitter')
:echo system('tree-sitter --version')
:echo nvim_get_runtime_file('parser/query.so', v:true)
:echo nvim_get_runtime_file('queries/query/highlights.scm', v:true)
```

If the shell or Neovim is still resolving `tree-sitter` from an old global npm path (for example an old `nvm` global install), fix your `PATH` ordering or uninstall the npm copy:

```bash
npm uninstall -g tree-sitter-cli
```

### Quick recovery steps for mismatched parser / query state

If Treesitter suddenly breaks after upgrading Neovim, switching servers, or changing branches:

1. confirm the loaded binary and runtime files with the commands above
2. run:

   ```vim
   :checkhealth nvim-treesitter
   :TSUpdate
   ```

3. if only the `query` parser is broken, try:

   ```vim
   :TSUninstall query
   :TSInstall query
   ```

4. if parser / query mismatches persist, clear old installed parser / query state and reinstall

   ```bash
   rm -rf ~/.local/share/nvim/site/parser
   rm -rf ~/.local/share/nvim/site/queries
   ```

5. if you accidentally mixed old and new `nvim-treesitter` plugin branches, clear the old plugin checkout and sync plugins again

Keep in mind that this config expects the `main`-branch Treesitter stack. When in doubt, prefer a clean reinstall over trying to preserve an unknown mix of parser, query, and plugin versions.

### Copilot

- Copilot is expected to run with **Node.js 18+**.
- If Node.js is too old, related features may not work correctly.
- You can authenticate with:

  ```vim
  :Copilot auth
  ```

### CopilotChat

CopilotChat is configured in:

- `lua/user/copilot.lua`

Prompt files are stored in:

- `docs/CopilotChatPrompts/`

Useful commands:

```vim
:CopilotChatOpen
:lua CopilotChatPromptAction()
```
