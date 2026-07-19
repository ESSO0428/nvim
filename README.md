---
title: My Neovim Config
author: Andy6
date: 2025-08-16
---

# My Neovim Config

<!--toc:start-->
- [My Neovim Config](#my-neovim-config)
  - [Introduction](#introduction)
  - [Supported Neovim Version](#supported-neovim-version)
  - [Installation](#installation)
  - [Optional: Reuse old LunarVim data paths](#optional-reuse-old-lunarvim-data-paths)
  - [Notes](#notes)
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

2. Start Neovim once

   ```bash
   nvim
   ```

   `lazy.nvim` will bootstrap itself and install plugins automatically.

3. Common external dependencies

   Recommended tools:
   - `git`
   - `ripgrep` (`rg`)
   - `fd`
   - `node >= 18`
   - `python3`
   - `gcc` or `clang`
   - `make`

   Optional but useful:
   - `lazygit`
   - `debugpy`
   - `bat`
   - `exa`

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

Some servers may fail to run newer Neovim builds because of `glibc` version issues, for example:

```bash
/lib64/libc.so.6: version `GLIBC_2.2X...' not found
```

In that case, you need a compatible Neovim build or a newer system library provided by the machine administrator.

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
