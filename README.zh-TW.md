---
title: 我的 Neovim 設定
author: Andy6
date: 2025-08-16
---

# 我的 Neovim 設定

<p align="right">
  <a href="./README.md">English</a> | <strong>繁體中文</strong>
</p>

<!--toc:start-->
- [我的 Neovim 設定](#我的-neovim-設定)
  - [簡介](#簡介)
  - [支援的 Neovim 版本](#支援的-neovim-版本)
  - [安裝方式](#安裝方式)
  - [可選：沿用舊 LunarVim 資料路徑](#可選沿用舊-lunarvim-資料路徑)
  - [注意事項](#注意事項)
    - [一般環境與舊 server 的 Neovim binary 安裝方式](#一般環境與舊-server-的-neovim-binary-安裝方式)
    - [Tree-sitter / nvim-treesitter 需求](#tree-sitter--nvim-treesitter-需求)
    - [如何檢查是否仍被 npm 版本的 tree-sitter 蓋掉](#如何檢查是否仍被-npm-版本的-tree-sitter-蓋掉)
    - [parser / query 混版時的快速復原步驟](#parser--query-混版時的快速復原步驟)
    - [Copilot](#copilot)
    - [CopilotChat](#copilotchat)
<!--toc:end-->

## 簡介

> [!NOTE]
>
> 這是我的 **Neovim** 設定。
> 它已經不是 LunarVim 設定了，不過有一部分內容最初是從舊的 LunarVim 環境遷移過來的。
>
> 目前狀態：
> - 純 `nvim` 設定
> - 使用 `lazy.nvim` 管理 plugin
> - 仍保留一部分舊的相容／遷移邏輯，方便我自己的工作流程

## 支援的 Neovim 版本

目前目標版本：

```bash
NVIM v0.12.3
```

如果你使用更舊的 Neovim，部分功能可能無法正常運作。

## 安裝方式

1. 將此 repo clone 到 `~/.config/nvim`

   ```bash
   cd ~/.config
   git clone git@github.com:ESSO0428/nvim.git nvim
   ```

   或

   ```bash
   cd ~/.config
   git clone https://github.com/ESSO0428/nvim.git nvim
   ```

2. 先安裝相容的 Neovim binary

   目前目標版本：

   ```bash
   NVIM v0.12.3
   ```

   建議方式：
   - 一般桌機／server，且 `glibc` 夠新：用 `bob`
   - 舊 server、`glibc` 太舊：直接在本機編譯 Neovim，不要依賴預編譯 binary

3. 啟動一次 Neovim

   ```bash
   nvim
   ```

   `lazy.nvim` 會自動 bootstrap 並安裝 plugins。

4. 常見外部依賴

   建議安裝：
   - `git`
   - `ripgrep` (`rg`)
   - `fd`
   - `node >= 18`
   - `python3`
   - `gcc` 或 `clang`
   - `make`
   - `tree-sitter` CLI `>= 0.26.1`（供目前這份 `nvim-treesitter` 設定使用）

   可選但實用：
   - `lazygit`
   - `debugpy`
   - `bat`
   - `exa`

> [!IMPORTANT]
>
> 這份設定在 Neovim `0.12.3` 上使用 `nvim-treesitter` **main** branch。
> **不要**把這份設定和舊的 `nvim-treesitter` `master` branch 混用。
> 另外，`tree-sitter` 請優先使用系統套件管理器或本機 Cargo build 安裝，**不要**優先用 global npm 版本。

## 可選：沿用舊 LunarVim 資料路徑

如果你是從我舊的 LunarVim 環境遷移過來，這份設定可以暫時沿用舊的 LunarVim 使用者資料路徑。

參考：

- `lua/opt.lua`

你可以在那裡切換 path profile：

```lua
local path_profile = "lvim" -- or "nvim"
```

- `"lvim"`：沿用舊 LunarVim 的 data/state/cache 路徑
- `"nvim"`：使用一般 Neovim 路徑

另外也有遷移 helper：

```bash
make migrate-help
make migrate-all
```

## 注意事項

### 一般環境與舊 server 的 Neovim binary 安裝方式

對 `NVIM v0.12.3` 來說，如果系統 library stack 夠新，`bob` 很方便。

建議的 `bob` 安裝方式：

- 官方 script

  ```bash
  curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
  ```

- 或本機 Cargo build

  ```bash
  cargo install bob-nvim --locked
  ```

這次踩到的重要注意事項：

- 新版 `bob-nvim` 需要 **Rust 1.85+**。如果 `cargo install bob-nvim` 因為 `rustc` 太舊而失敗，先用 `rustup` 更新。
- 在舊 server 上，就算是官方 `bob` release binary 或 AppImage，也可能因為系統太舊而失敗，例如：

  ```bash
  bob: /lib64/libc.so.6: version `GLIBC_2.39' not found
  ```

- 如果遇到這種情況，**不要**一直重試 release zip / AppImage。請改成在該機器本機編譯 `bob`，或乾脆跳過 `bob`，直接本機編譯 Neovim。
- 如果你的目標只是讓舊 server 上能用 `nvim v0.12.3`，通常直接本機編譯 Neovim 會比硬救 `bob` 更簡單。

### Tree-sitter / nvim-treesitter 需求

這份設定目前使用：

- Neovim `v0.12.3`
- `nvim-treesitter` **main** branch（`lua/plugins/treesitter.lua`）
- `tree-sitter` CLI `>= 0.26.1`

重要注意事項：

- **不要**把 Neovim `0.12.x` 和舊的 `nvim-treesitter` `master` branch 混用。
- 如果 `:checkhealth nvim-treesitter` 還出現 `only needed for :TSInstallFromGrammar` 這類 wording，通常代表你某處仍在載入舊的 `master` 風格 plugin/runtime stack。
- global npm 的 `tree-sitter-cli` 可能附帶一顆連到較新 `glibc` 的預編譯 binary，導致 `tree-sitter build` 雖然有指令，實際上卻無法執行。
- `tree-sitter` 優先建議用系統套件管理器或本機 Cargo build。

可用的 `tree-sitter` CLI 安裝路徑：

- 首選：系統套件管理器
- 次選：Cargo 完整 build

  ```bash
  cargo install tree-sitter-cli --locked
  ```

- 若你目前只需要 `tree-sitter build`，而完整 Cargo build 卡在 `rquickjs` / `bindgen`，可用的最小 workaround：

  ```bash
  cargo install tree-sitter-cli --locked --no-default-features --force
  ```

Cargo 側常見失敗模式：

- `Unable to find libclang`
  - 安裝 `clang-devel` / `libclang-dev`，或設定 `LIBCLANG_PATH`
- `fatal error: 'stdbool.h' file not found`
  - 代表 `bindgen` 找到 `libclang` 了，但 include path 不對；請設定 `BINDGEN_EXTRA_CLANG_ARGS` 指向 GCC / 系統標頭目錄

範例：

```bash
BINDGEN_EXTRA_CLANG_ARGS='-I/opt/rh/gcc-toolset-13/root/usr/lib/gcc/x86_64-redhat-linux/13/include -I/usr/include' \
cargo install tree-sitter-cli --locked
```

### 如何檢查是否仍被 npm 版本的 tree-sitter 蓋掉

Shell 側檢查：

```bash
which tree-sitter
tree-sitter --version
npm list -g tree-sitter-cli --depth=0
```

Neovim 側檢查：

```vim
:echo exepath('tree-sitter')
:echo system('tree-sitter --version')
:echo nvim_get_runtime_file('parser/query.so', v:true)
:echo nvim_get_runtime_file('queries/query/highlights.scm', v:true)
```

如果 shell 或 Neovim 仍然把 `tree-sitter` 解析到舊的 global npm 路徑（例如舊的 `nvm` global install），請調整 `PATH` 順序，或直接移除 npm 版本：

```bash
npm uninstall -g tree-sitter-cli
```

### parser / query 混版時的快速復原步驟

如果 Treesitter 在升級 Neovim、換 server、切 branch 後突然壞掉：

1. 先用上面的命令確認目前實際載入的 binary 與 runtime files
2. 執行：

   ```vim
   :checkhealth nvim-treesitter
   :TSUpdate
   ```

3. 如果只有 `query` parser 壞掉，先試：

   ```vim
   :TSUninstall query
   :TSInstall query
   ```

4. 如果 parser / query mismatch 仍持續，清掉舊的 installed parser / query state 再重裝

   ```bash
   rm -rf ~/.local/share/nvim/site/parser
   rm -rf ~/.local/share/nvim/site/queries
   ```

5. 如果你曾經把新舊 `nvim-treesitter` plugin branch 混在一起，請清掉舊 plugin checkout，再重新同步 plugins

請記住：這份設定預期使用的是 `main` branch 的 Treesitter stack。若狀態不明，通常乾淨重裝會比硬保留未知的 parser / query / plugin 混搭狀態更省事。

### Copilot

- Copilot 預期使用 **Node.js 18+**。
- 如果 Node.js 太舊，相關功能可能無法正常運作。
- 可以用以下命令登入：

  ```vim
  :Copilot auth
  ```

### CopilotChat

CopilotChat 的設定位置：

- `lua/user/copilot.lua`

Prompt 檔案放在：

- `docs/CopilotChatPrompts/`

常用指令：

```vim
:CopilotChatOpen
:lua CopilotChatPromptAction()
```
