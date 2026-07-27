# 多語言 LSP 遷移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 LunarVim 中有用的多語言 LSP 設定，以目前 Neovim 0.12 + mason-lspconfig + nvim-lspconfig 相容的方式搬到這份 nvim 設定，並優先收斂到 `after/lsp/*.lua`。

**Architecture:** 保留 `lua/user/lsp.lua` 作為共用能力、安裝清單與全域 handler 的入口；把語言特化設定放到 `after/lsp/*.lua`，讓 `vim.lsp.config(server_name, {})` 透過 runtime `lsp/*.lua` 預設加上 user `after/lsp/*.lua` 覆寫。只搬目前確定有價值、且與現行版本相容的設定，避免照抄過時的 lvim API。

**Tech Stack:** Neovim 0.12.3、內建 `vim.lsp.config()` / `vim.lsp.enable()`、`mason.nvim`、`mason-lspconfig.nvim`、`nvim-lspconfig`、`schemastore.nvim`

## Global Constraints

- 使用中文註解與回報。
- 最小、正確改動。
- 不修改 `/root/.config/lvim/`。
- `lua/user/lsp.lua` 保持精簡，語言特化放 `after/lsp/*.lua`。
- 只做輕量 syntax/headless 驗證，不做重型整合測試。

---

### Task 1: 盤點目前 nvim/lvim LSP 配置邊界

**Files:**
- Modify: `lua/user/lsp.lua`
- Create: `after/lsp/bashls.lua`
- Create: `after/lsp/jsonls.lua`
- Create: `after/lsp/html.lua`
- Create: `after/lsp/cssls.lua`
- Create: `after/lsp/ts_ls.lua`
- Create: `after/lsp/yamlls.lua`
- Create: `after/lsp/tailwindcss.lua`
- Modify: `lua/user/lsp/helpers.lua`

**Interfaces:**
- Consumes: `vim.lsp.config()`, `vim.lsp.enable()`, `Nvim.builtin.lsp.ensure_installed`, `Nvim.builtin.lsp.capabilities`
- Produces: 每個 server 的 `after/lsp/<server>.lua` 覆寫檔；`helpers.get_json_schemas()`

- [ ] **Step 1: 確認 lvim 來源與 nvim 現況**

Run:
```bash
cd /root/.config/nvim && rg -n "jsonls|bashls|yamlls|cssls|ts_ls|tailwindcss|vim\.lsp\.config|vim\.lsp\.enable" lua after -g '*.lua'
```

Expected: 看出目前 `jsonls/bashls` 缺席，且部分語言特化仍留在 `lua/user/lsp.lua`。

- [ ] **Step 2: 確認當前 `nvim-lspconfig` 預設**

Run:
```bash
sed -n '1,220p' ~/.local/share/nvim/lazy/nvim-lspconfig/lsp/{bashls,jsonls,html,cssls,ts_ls,yamlls,tailwindcss}.lua
```

Expected: 確認哪些值應沿用 upstream 預設、哪些只需在 `after/lsp/*.lua` 補差異。

### Task 2: 將語言特化配置收斂到 after/lsp

**Files:**
- Modify: `lua/user/lsp.lua`
- Modify: `lua/user/lsp/helpers.lua`
- Create: `after/lsp/bashls.lua`
- Create: `after/lsp/jsonls.lua`
- Create: `after/lsp/html.lua`
- Create: `after/lsp/cssls.lua`
- Create: `after/lsp/ts_ls.lua`
- Create: `after/lsp/yamlls.lua`
- Create: `after/lsp/tailwindcss.lua`

**Interfaces:**
- Consumes: `require("user.lsp.helpers")`
- Produces:
  - `get_json_schemas(): table`
  - `after/lsp/jsonls.lua` 提供 `settings.json.schemas`
  - `after/lsp/bashls.lua` 提供 bash/sh filetypes 與 globPattern 保護
  - 既有 html/cssls/ts_ls/yamlls/tailwindcss 差異設定拆出至 `after/lsp/*.lua`

- [ ] **Step 1: 精簡共用入口**

在 `lua/user/lsp.lua` 只保留：
```lua
Nvim.builtin.lsp.ensure_installed = {
  "lua_ls",
  "basedpyright",
  "ruff",
  "html",
  "cssls",
  "ts_ls",
  "yamlls",
  "tailwindcss",
  "intelephense",
  "marksman",
  "bashls",
  "jsonls",
}
```
以及共用 capabilities / handlers。

- [ ] **Step 2: 補 `helpers.get_json_schemas()`**

加入：
```lua
function M.get_json_schemas()
  local ok, schemastore = pcall(require, "schemastore")
  if ok and schemastore.json and type(schemastore.json.schemas) == "function" then
    return schemastore.json.schemas()
  end
  return {}
end
```

- [ ] **Step 3: 建立各語言 `after/lsp/*.lua`**

內容原則：
- `bashls.lua`: 沿用當前 lspconfig 的 `bashIde.globPattern` 保護與 shell filetypes
- `jsonls.lua`: 加 `settings.json.schemas = helpers.get_json_schemas()`
- `html.lua`: 補 `htmldjango`
- `cssls.lua`: 補 unknownAtRules ignore
- `ts_ls.lua`: 補 inlay hints 與 filtered definition handler
- `yamlls.lua`: 補 schemastore yaml schemas 與顯式 hover/completion/validate/schemaStore
- `tailwindcss.lua`: 補 lvim 風格 root_dir；filetypes 盡量沿用 upstream 預設，不縮窄

### Task 3: 輕量驗證配置可載入

**Files:**
- Test: `lua/user/lsp.lua`
- Test: `lua/user/lsp/helpers.lua`
- Test: `after/lsp/*.lua`

**Interfaces:**
- Consumes: `nvim --headless`, `luac -p`
- Produces: 驗證輸出字串，證明配置檔可載入與 server 名稱可解析

- [ ] **Step 1: 語法檢查**

Run:
```bash
luac -p lua/user/lsp.lua lua/user/lsp/helpers.lua after/lsp/*.lua
```

Expected: 無語法錯誤。

- [ ] **Step 2: headless 驗證 server config 可註冊**

Run:
```bash
nvim --headless '+lua require("user.lsp"); local names = {"bashls","jsonls","html","cssls","ts_ls","yamlls","tailwindcss"}; for _, name in ipairs(names) do vim.lsp.config(name, {}); end; print("LSP_MULTILANG_OK")' +qa
```

Expected: 印出 `LSP_MULTILANG_OK`。

- [ ] **Step 3: 驗證關鍵覆寫生效**

Run:
```bash
nvim --headless '+lua require("user.lsp"); local json = vim.lsp.config.jsonls; local bash = vim.lsp.config.bashls; assert(json and bash); print("LSP_JSON_BASH_OK")' +qa
```

Expected: 印出 `LSP_JSON_BASH_OK`。
