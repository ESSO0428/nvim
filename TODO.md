# TODO

## LunarVim 使用者資料遷移筆記

### 這次要保留 / 遷移的使用者資料

- [x] `sessions`
  - `~/.local/share/lvim/sessions` -> `~/.local/share/nvim/sessions`
- [x] `scratch`
  - `~/.local/share/lvim/scratch` -> `~/.local/share/nvim/scratch`
- [x] `snacks`
  - `~/.local/share/lvim/snacks` -> `~/.local/share/nvim/snacks`
  - 目前觀察到的內容以 `picker_*.history` 為主，屬於 Snacks picker / scratch 相關歷史資料，不是 plugin 安裝內容。
- [x] `nvim_bookmarks`
  - `~/.local/share/lvim/nvim_bookmarks` -> `~/.local/share/nvim/nvim_bookmarks`
- [x] `shada`
  - `~/.local/state/lvim/shada/main.shada` -> `~/.local/state/nvim/shada/main.shada`
- [x] `undo`
  - `~/.local/state/lvim/undo` -> `~/.local/state/nvim/undo`

### 明確不遷移的項目

- [x] `lazy/`
- [x] `mason/`
- [x] plugin / package 安裝內容
- [x] 其他非使用者狀態資料

### 路徑切換策略

- [x] `lua/opt.lua` 採集中式 `path_profile` 變數切換，目前預設 `"lvim"`。
- [x] 要切回原生 Neovim 路徑時，只需要把 `path_profile` 改成 `"nvim"`。
- [x] 目前集中管理的路徑：
  - `sessions_dir`
  - `scratch_dir`
  - `snacks_dir`
  - `bookmarks_dir`
  - `shada_dir` / `shadafile`
  - `undodir`
- [x] `session-manager`、`bookmarks.nvim`、`Snacks scratch root`、Neovim 原生 `shadafile` / `undodir` 都應改吃這組集中路徑。

### Makefile 行為

- [x] 提供分項 targets：
  - `migrate-sessions`
  - `migrate-scratch`
  - `migrate-snacks`
  - `migrate-bookmarks`
  - `migrate-shada`
  - `migrate-undo`
  - `migrate-all`
- [x] 行為規則：
  - 來源存在才複製
  - 來源不存在就略過
  - 直接覆寫 Neovim 目標資料
  - 必要時自動建立目標目錄

### 補充觀察

- [x] `Snacks scratch` 的實體檔案與 metadata 主要在 `scratch/`；`snacks/` 另外保存 picker / history 類資料。
- [x] `shada` 應該視為 `state` 路徑下的資料，不是 `data`。
- [x] 這次需求是延續使用者狀態，不是共用或搬移 plugin runtime / package manager 狀態。

## Lsp 配置遷移筆記

### LunarVim 官方 baseline

- 官方 baseline 不是只綁少數語言，而是依 `lvim.lsp.automatic_configuration` 對 Mason / lspconfig 可支援、且不在 `skipped_servers` 清單中的 server 做自動配置。
- 目前官方明確跳過很多 server，例如 `basedpyright`、`emmet_ls`、`eslint`、`ruff_lsp`、`sqls`、`vtsls`、`vuels` 等；因此這些通常代表要嘛交給使用者自訂，要嘛避免和其他方案衝突。
- 官方另外有大量 `site/after/ftplugin/*.lua` 語言模板；就你目前這份配置，後續最值得追的官方語言面向至少有：
  - [x] `lua`
  - [x] `python`
  - [x] `php`
  - [x] `html`
  - [x] `htmldjango`
  - [x] `css`
  - [x] `scss`
  - [x] `less`
  - [x] `javascript`
  - [x] `javascriptreact`
  - [x] `typescript`
  - [x] `typescriptreact`
  - [x] `yaml`
  - [x] `markdown`
  - [x] `tailwindcss`
    - 注意：`tailwindcss` 對你目前的 web 開發很重要，但它不是 LunarVim 官方 `site/after/ftplugin/*.lua` 裡的一個語言模板，應視為額外需要追蹤的 LSP。

### 共用非預設 LSP 行為

- [x] `共用能力(capabilities)`
  - 已在 `~/.config/lvim/lua/user/lsp.lua` 額外補上 `foldingRange` 與 `workspace.didChangeWatchedFiles.dynamicRegistration = true`；後續 `nvim` 遷移時應保留這份 capability 增強。
- [x] `on_attach_callback`
  - 若 server 支援 `documentSymbolProvider`，會自動 `navbuddy.attach(client, bufnr)`。
- [x] `Neovim 0.10.x 相容修補`
  - 有覆蓋 `vim.lsp.util._str_utfindex_enc`，註解明確指出是為了修正 `0.10.2+` 對 CJK / `marksman` 等 completion 行為的問題。
- [-] `移除 LunarVim 預設 ftplugin`
  - `lua`、`python`、`php` 會先從 runtimepath 移除 LunarVim 預設 ftplugin，避免官方預設 LSP 先載入後難以覆蓋。
  - 目前本地是純 `nvim 0.12.3` 配置，不再沿用 LunarVim 自動配置流程，因此這個繞路不需要直接照搬。

### 目前使用者層明確接管的語言

- [x] `Lua`
  - 使用 `lua_ls`。
  - 重要特化：啟用 `Lua.hint.enable = true`。
- [x] `Python`
  - 使用 `basedpyright` + `ruff`，且主動跳過 `pyright`、`ruff_lsp`。
  - 重要特化：自訂 `root_dir`、`basedpyright.analysis`、並且在進出 `*.py` buffer 時動態調整 `PYTHONPATH`。
- [x] `PHP`
  - 使用 `intelephense`，並主動跳過自動配置同名 server 後自行 `setup`。
  - 重要特化：自訂 `root_dir`；另外會一起啟用 `tailwindcss`。
- [x] `HTML / htmldjango`
  - 使用 `html`，並額外把 `htmldjango` 併入 `filetypes`。
  - 重要特化：這是明確手動 `setup("html", opts)` 的語言，不只是沿用官方預設。
- [x] `CSS / SCSS / LESS`
  - 使用 `cssls`。
  - 重要特化：把 `unknownAtRules` lint 全部設成 `ignore`，明顯是在配合 Tailwind / 其他 at-rule 場景。
- [x] `JavaScript / TypeScript / React`
  - 使用 `ts_ls`（安裝清單裡仍寫 `tsserver`，但實際 `setup` 是 `ts_ls`）。
  - 重要特化：大量 `inlayHints` 啟用，並覆蓋 `textDocument/definition` handler，過濾 `node_modules/@types/.../index.d.ts` 結果。
- [x] `YAML`
  - 使用 `yamlls`。
  - 重要特化：目前以 `vim.lsp.config("yamlls", ...)` 直接配置，並接上 `schemastore.yaml.schemas()`。
- [x] `Markdown`
  - 使用 `marksman`。
  - 來源是 `~/.config/lvim/after/ftplugin/markdown.lua`，原本這條在遷移過程中漏掉，現在已補回純 `nvim` 配置。

### 維護結構

- [x] `核心與語言別 extra 分流`
  - `lua/user/lsp.lua` 保留共用 handler、capabilities、server 清單，以及主線語言配置。
  - 參考原本 `lvim` 的維護習慣，但在純 `nvim 0.12` 改成更貼近原生 LSP runtime 的 `after/lsp/*.lua`。
  - `after/ftplugin/*.lua` 只保留真正的 filetype / buffer-local 邏輯，例如 Python REPL 與 `PYTHONPATH`。
  - 目前已放入 `after/lsp` 的語言別 extra：
    - `lua_ls.lua`
    - `basedpyright.lua`
    - `ruff.lua`
    - `intelephense.lua`
    - `marksman.lua`
- [x] `TailwindCSS`
  - 這份 `lvim` 配置明確依賴 TailwindCSS；HTML / PHP / CSS 與 web 類場景都把它當成重要組成。
  - 重要特化：除了安裝清單外，`null-ls` 還補了 Tailwind 排序 / conceal 的 code actions。

### 安裝與周邊清單

- [x] `Mason ensure_installed`
  - 目前本地 `nvim 0.12.3` 直接維護的 LSP 安裝清單是：`lua_ls`、`html`、`cssls`、`ts_ls`、`yamlls`、`tailwindcss`、`basedpyright`、`ruff`、`intelephense`、`marksman`。
- [-] `null-ls / formatter / code action 補充`
  - `python`: Ruff format code action
  - `html` / `htmldjango` / `php` / `css` / `javascriptreact` / `typescriptreact`: Tailwind code actions
  - `css` / `javascript` / `typescript` / `typescriptreact`: Prettier formatter
  - 這一節屬於 formatter / code action 周邊，不是這次 `0.12.3` LSP 主遷移的阻塞項。

### 融合版策略

- [x] `總原則`
  - 以 `Neovim 0.12+` 的 `vim.lsp.config(...)` / `vim.lsp.enable(...)` 為主軸。
  - `nvim-lspconfig` 保留作為 server config 來源，但不再以 `require('lspconfig').xxx.setup {}` 為核心。
- [x] `LunarVim 內部機制只保留必要精神`
  - `skipped_servers`、移除 LunarVim 預設 ftplugin、避免官方自動配置搶先載入，這些主要是在 LunarVim 分發版內部避免重複配置與覆蓋衝突。
  - 純 `nvim` 重建時通常不需要照搬整套跳過/移除機制，只需要明確決定「要啟用哪些 server、不要啟用哪些 server」。
- [x] `純 nvim 最小可行方案`
  - 若某語言只需要單一 server，直接安裝並啟用該 server 即可；例如 Python 只用 `basedpyright` 時，通常不需要額外重建 LunarVim 的跳過邏輯。
  - 只有在同語言要並用多個 server，或要避開預設自動啟用時，才需要額外寫排除策略。
- [x] `本配置建議採混合遷移`
  - 保留真正有價值的使用者層特化：`basedpyright.analysis`、自訂 `root_dir`、動態 `PYTHONPATH`、`Lua.hint.enable`、TS definition 過濾、YAML schemastore、Tailwind 相關 filetypes / code actions。
  - 不保留純為 LunarVim 內部自動配置模型服務的相容繞路，除非本地 `nvim` 真的出現重複 attach、錯誤 server 被啟用、或 ftplugin 搶載入的實際衝突。
- [x] `Python 融合版建議`
  - 最小版：只啟用 `basedpyright`。
  - 常用版：`basedpyright` + `ruff`，並明確分工，避免重疊能力造成噪音。
  - 遷移版：若要忠實接近目前 `lvim` 行為，再補上 `root_dir`、`PYTHONPATH`、analysis 設定與其他使用者層特化。

### 0.12.3 實測結果

- [x] `lua`
  - `lua_ls` 可 attach。
- [x] `python`
  - 以 `/tmp/opencode/lsp-fixtures/python-app/app.py` 實測，`basedpyright`、`ruff` 皆可 attach。
- [x] `typescript`
  - 以 `/tmp/opencode/lsp-fixtures/ts-app/index.ts` 實測，`ts_ls` 可 attach。
- [x] `php`
  - 以 `/tmp/opencode/lsp-fixtures/php-app/index.php` 實測，`intelephense` 可 attach。
- [x] `html`
  - 以 `/tmp/opencode/lsp-fixtures/web-app/index.html` 實測，`html`、`emmet_ls`、`tailwindcss` 可同時 attach。
- [x] `css`
  - 以 `/tmp/opencode/lsp-fixtures/web-app/style.css` 實測，`cssls`、`emmet_ls`、`tailwindcss` 可同時 attach。
- [x] `php + tailwind`
  - 以 `/tmp/opencode/lsp-fixtures/web-app/index.php` 實測，`intelephense`、`tailwindcss` 可同時 attach。
- [x] `yaml`
  - 以 `/tmp/opencode/lsp-fixtures/yaml-app/pipeline.yaml` 實測，`yamlls` 可 attach。
- [x] `本地舊式 LSP 寫法清理`
  - 本地配置已無 `require('lspconfig').*.setup(...)`、`vim.lsp.with(...)`、`client.supports_method(...)`。
- [x] `主要語言 hover UI 實測`
  - `gh` / `vim.lsp.buf.hover({ border = 'rounded' })` 已用 headless UI 路徑驗證可正常開出 floating window。
  - 已實測語言：`lua`、`python`、`typescript`、`php`、`yaml`。
  - `lua` 額外在早期初始化明確指定 `vim.treesitter.language.add('lua', { path = stdpath('data') .. '/site/parser/lua.so' })`，固定使用重建後的 `tree-sitter-lua v0.5.0` parser，避開 runtime 誤載入舊 parser 導致的 `operator` field mismatch。
- [x] `Orgmode / Treesitter 新版相容整理`
  - `orgmode` 目前本地 lock 已在 upstream 最新 `master`，上游 README 標示支援 `Neovim 0.11+`，可直接用於 `0.12.x`。
  - 已移除舊的 `require('nvim-treesitter.configs').setup(...)` 寫法，不再依賴已刪除的 `nvim-treesitter.configs` 相容層。
  - 為了更貼近上游安裝方式，目前改回 `event = 'VeryLazy'` + `ft = { 'org' }`，讓 `orgmode` 在打開 org 檔前先有機會完成 `setup()` 與 parser 管理。
  - 先前加在 user config 的 org query override 與 parser pin 已移除，改回優先依賴 orgmode 官方的 parser 安裝 / 衝突檢查路線。
- [x] `session restore 後 LSP / filetype 初始化時序`
  - 根因不是 session-manager 本身，而是 `vim.lsp.enable()` 太早在 `User FileOpened` 路徑裡執行。
  - 在 `0.12.x` 上，這會和 session restore 的第一輪 `FileType` 流程互撞，表現成部分 buffers 還原後狀態不完整。
  - 修法：先 `vim.lsp.config(server_name, server)`，真正 `vim.lsp.enable(server_name)` 延後到當前事件循環之後；若正在 session restore，則延到 `SessionLoadPost` 後再 enable。enable 完成後再對已載入且已有 filetype 的真實 buffers 補跑一次 `FileType` autocmd，確保第一批 buffers 也能 attach。
  - headless 驗證：`silent source /root/.local/share/nvim/sessions/__root__research` 後，逐個切換 session 內 listed buffers，`lua/html/python/sh` filetype 都可正確恢復，對應 LSP 也能正常 attach。
  - 同時驗證 `markdown` 首開 buffer：`TODO.md` 可正確 attach `marksman`。

## 快捷鍵遷移筆記

### 已導出的快捷鍵檔案

- `nvim`: `/root/keymap-migration/nvim-keymaps.txt`
- `lvim`: `/root/keymap-migration/lvim-keymaps.txt`
- 正規化後的比對輸入檔：
  - `/root/keymap-migration/nvim-keymaps-normalized.tsv`
  - `/root/keymap-migration/lvim-keymaps-normalized.tsv`
- 比對報表：
  - `/root/keymap-migration/lvim-only-keymaps.tsv`
  - `/root/keymap-migration/lvim-vs-nvim-report.tsv`

### 比對摘要

- 依照最新嚴格重跑結果，`lvim` 專有快捷鍵共 `37` 條。
- `lvim-vs-nvim-report.tsv` 目前共有 `231` 條差異，其中包含 `MISSING` 與 `DIFF`。
- 這次匯出流程已改成：開啟真實檔案、等待啟動完成、手動載入 lazy plugins、再匯出 keymaps；因此比前一版更接近實際使用狀態。
- 重新確認後，`lvim` 仍然沒有可被 `:nmap` 列出的 `n <Space>ta`；只有 `v <Space>ta` 與 which-key 註冊項目 `ta` / `tA`。
- 補查 `lvim` 的 keymap / which-key table 後，確認目前 `TODO` 主要仍是根據 runtime `:map` 報表整理；若把 `lvim.builtin.which_key.mappings` 與 `lvim.keys.*` 也算進來，待遷移入口會比這份清單更多。
- 這輪也確認先前遺漏了 `which-key` 型的 `<leader>U` 群組；原因是當時排查重心偏在既有 runtime 差異與 `t/u/s/d/g` 群組，沒有把 `~/.config/lvim` 與 LunarVim 上游裡較偏「配置/維護工具」的 `U` 群組一起列入 `TODO`。
- 注意：部分 `DIFF` 不一定代表真的有功能差異，可能只是下列因素造成：
  - Lua 函式位址不同
  - plugin 安裝路徑不同
  - `lazy.nvim` handler 路徑不同
  - `<SNR>` 編號不同

### 值得補回的缺少快捷鍵

#### 視窗 / 面板 / 終端

- [-] `n <C-H>` -> `<C-W>h` `來源: LunarVim 上游預設 lvim.keymappings.defaults.normal_mode["<C-h>"]`
- [x] `n <C-K>` -> `NvimTreeFocus` `來源: ~/.config/lvim lua/user/keymappings/whichkey.lua 中覆蓋 lvim.keys.normal_mode["<c-k>"]`
- [x] `n <C-T>` -> `Outline!` `來源: lvim.keys.normal_mode`
- [-] `n <C-Up>` -> `:resize -2` `來源: LunarVim 上游預設 lvim.keymappings.defaults.normal_mode["<C-Up>"]`
- [-] `n <C-Down>` -> `:resize +2` `來源: LunarVim 上游預設 lvim.keymappings.defaults.normal_mode["<C-Down>"]`
  - `nvim` 目前仍被 VM 的 `<Plug>(VM-Add-Cursor-Up/Down)` 蓋掉，尚未真正對齊 LunarVim 行為
- [x] `n <Space><C-T>` -> `OutlineFocusOutline` `來源: lvim.keys.normal_mode`
- [x] `n <Space>I` -> `wincmd W` `來源: lvim.keys.normal_mode`
- [x] `n <Space>K` -> `wincmd w` `來源: lvim.keys.normal_mode`
- [-] `n <C-0>`、`n <C-8>`、`n <C-9>` -> LunarVim 的 terminal 快捷鍵 `來源: 待確認（terminal.lua 自訂，不屬於 lvim.keys / lvim.builtin.which_key）`

### 同一快捷鍵但功能不同

- [-] `n gh`
  - `lvim`: `lsp_or_jupyter_hover()`
  - `來源`: `lvim.keys.normal_mode`
  - `nvim`: `vim.lsp.buf.hover({ border = 'rounded' })`
- [-] `n <C-Bslash>`
  - `lvim`: LunarVim 的 terminal handler
  - `來源`: `terminal.lua` 自訂，不屬於 `lvim.keys` / `lvim.builtin.which_key`
  - `nvim`: `ToggleTerm`
- [x] `n <M-o>`
  - `lvim`: `vim.lsp.buf.definition()`
  - `來源`: `lvim.keys.normal_mode`
  - `nvim`: 這個按鍵目前沒有直接對應；現在的配置是用 `<leader><M-o>` 做 preview definition
- [x] `n <M-q>`
  - `lvim`: `copen`
  - `來源`: `lvim.keys.normal_mode`
  - `nvim`: 自訂 utility mapping
- [x] `n <Space>rc`
  - 不需要修改
  - `lvim`: 開啟 `~/.config/lvim/config.lua`
  - `來源`: `lvim.keys.normal_mode`
  - `nvim`: 開啟 `~/.config/nvim/lua/config.lua`
- [x] `v <Space>o`
  - `來源`: `lvim.keys.visual_mode`
  - 已改成與 `lvim` 一致：`zA<Esc>`

### after/ 比對結果

- [x] `after/ftplugin/sql.vim` 的 `n <Space>rn` -> `<Plug>(DBUI_EditBindParameters)` 兩邊一致
- [x] `after/ftplugin/python.lua` 的 REPL 快捷鍵兩邊一致
  - `n [w` / `]w`
  - `n [r` / `]r`
  - `n [R` / `]R`
  - `v [w` / `]w`
  - `v [r` / `]r`
- [x] 下列 `after/ftplugin` 快捷鍵目前也與 `lvim` 一致
  - `undotree.vim`
  - `minifiles.vim`
  - `markdown.vim`
  - `help.vim`
  - `copilot-chat.vim`
- [x] `after/ftplugin/AvanteInput.vim` 仍有差異
  - `lvim`: 會 `source after/ftplugin/markdown.vim`
  - `nvim`: 目前是空檔案
  - 影響：`AvanteInput` buffer 內可能少掉 markdown 類快捷鍵，例如 `i ,,`、`i ,c`、`i ,f`、`n <leader><leader>`
- [ ] `after/` 其他差異目前不是快捷鍵差異
  - `lua.lua`、`markdown.lua`、`php.lua` 主要是 LSP / filetype 設定，不是 keymap
  - `after/syntax/markdown.lua` 只出現在 `lvim`
  - `after/syntax/python.lua` 只有檔尾空行差異，與快捷鍵無關

### Table 層級待盤點

#### `<leader>s` table 入口

- [x] `n <Space>s.` -> `require('lvim.core.telescope.custom-finders').find_project_files { previewer = true }` `來源: lvim.builtin.which_key.mappings.s["."]`
  - `nvim` 以等價語意實作：先 `git_files({ previewer = true })`，失敗時退回 `find_files({ previewer = true })`
- [x] `n <Space>s/` -> `Telescope search_history` `來源: lvim.builtin.which_key.mappings.s["/"]`
- [x] `n <Space>s'` -> `execute 'Telescope find_files default_text=' . expand('<cfile>')` `來源: lvim.builtin.which_key.mappings.s["'"]`
- [x] `n <Space>sF` -> `Telescope file_browser` `來源: lvim.builtin.which_key.mappings.s.F`
- [x] `n <Space>sG` -> `Telescope live_grep_args` `來源: lvim.builtin.which_key.mappings.s.G`
- [x] `n <Space>sH` -> `Telescope highlights` `來源: LunarVim 上游 which-key s.H`
- [x] `n <Space>sM` -> `Telescope man_pages` `來源: LunarVim 上游 which-key s.M`
- [-] `n <Space>sO` -> `Telescope orgmode search_headings` `來源: lvim.builtin.which_key.mappings.s.O`
  - `nvim` 目前未安裝 / 啟用 `telescope-orgmode.nvim`，暫時無法直接對齊
- [x] `n <Space>sR` -> `Telescope registers` `來源: LunarVim 上游 which-key s.R`
- [x] ``n <Space>s` `` -> `Telescope marks` `來源: lvim.builtin.which_key.mappings.s["`"]`
- [x] `n <Space>sa` -> `require('swenv.api').pick_venv()` `來源: lvim.builtin.which_key.mappings.s.a`
- [x] `n <Space>sb` -> `telescope.extensions.dap.list_breakpoints()` `來源: lvim.builtin.which_key.mappings.s.b`
- [x] `n <Space>sc` -> `Telescope command_history` `來源: lvim.builtin.which_key.mappings.s.c`
- [x] `n <Space>sd` -> `Telescope cder theme=get_ivy` `來源: lvim.builtin.which_key.mappings.s.d`
- [x] `n <Space>sf` -> `Telescope find_files` `來源: LunarVim 上游 which-key s.f`
- [x] `n <Space>sg` -> `Telescope live_grep` `來源: ~/.config/lvim 將上游 which-key s.t 改掛到 s.g`
- [x] `n <Space>sh` -> `Telescope help_tags` `來源: LunarVim 上游 which-key s.h`
- [x] `n <Space>si` -> `telescope_interestingwords_selected(false)` `來源: lvim.builtin.which_key.mappings.s.i`
- [x] `n <Space>sj` -> `Telescope jumplist` `來源: lvim.builtin.which_key.mappings.s.j`
- [x] `n <Space>sk` -> `Telescope keymaps` `來源: LunarVim 上游 which-key s.k`
- [x] `n <Space>sl` -> `Telescope tagstack` `來源: lvim.builtin.which_key.mappings.s.l`
- [x] `n <Space>sm` -> `telescope.extensions.media_files.media_files()` `來源: lvim.builtin.which_key.mappings.s.m`
- [x] `n <Space>sn` -> `Telescope notify` `來源: lvim.builtin.which_key.mappings.s.n`
- [x] `n <Space>so` -> `Telescope oldfiles` `來源: ~/.config/lvim 將上游 which-key s.r 改掛到 s.o`
- [x] `n <Space>sp` -> `telescope.builtin.colorscheme({ enable_preview = true })` `來源: LunarVim 上游 which-key s.p`
- [x] `n <Space>sr` -> `Telescope file_browser path=%:p:h initial_mode=normal grouped=true` `來源: lvim.builtin.which_key.mappings.s.r`
- [x] `n <Space>ss` -> `Telescope buffers` `來源: lvim.builtin.which_key.mappings.s.s`
- [x] `n <Space>su` -> `Telescope telescope-tabs list_tabs` `來源: lvim.builtin.which_key.mappings.s.u`
- [x] `n <Space>sw` -> `ListTabWindows` `來源: lvim.builtin.which_key.mappings.s.w`
- [x] `n <Space>sy` -> `Telescope neoclip theme=get_ivy` `來源: lvim.builtin.which_key.mappings.s.y`

註記：
- 這一節代表「`lvim` table 裡存在、但不一定已出現在 runtime `:map` 差異報表」的候選遷移入口。
- 其中有些可能已被 `nvim` 的其他普通 mapping、plugin 預設行為或不同命名方式覆蓋，所以不能直接全部視為真正缺失，仍需逐條核對。
- `which-key` 不只是顯示介面；在目前這份配置中，`Nvim.which_key` 經 `which-key.add(...)` 後也可以直接定義真正的快捷鍵。
- 當一組按鍵本身有明確群組語意時，優先使用 `which-key` 維護，藉此降低使用者在配置與後續維護快捷鍵時的認知負擔。
- 對於 `來源: lvim.builtin.which_key.mappings.*` 的項目，目前本地配置有一部分需要同時掛在 `Nvim.which_key` 與 `Nvim.keys`：前者負責 which-key 顯示分類，後者負責確保實際 runtime mapping 真的存在。單獨放在 `Nvim.which_key` 時，這批鍵在目前配置下不一定會生成可按的 mapping。

### 大概率可忽略的差異

- `lazy.nvim` handler 路徑不同
- Lua 函式位址不同
- `<SNR>` 編號不同
- 指令寫法不同但功能相同，例如 `:w<CR>` 與 `<Cmd>w<CR>`
- 同一個 plugin 功能只是來自不同安裝根目錄，例如 `lvim` runtime 與 `~/.local/share/nvim/lazy/...`

### 這次排查時順手修掉的設定問題

- 已從 `lua/user/plugins.lua` 移除手動建立的 LSP `document_highlight` autocmd，改成只讓 `vim-illuminate` 負責參照高亮。
- 已修正 `which-key` 與 `<leader>` 的衝突：移除多個 plugin spec 中把裸 `<leader>` 當成 lazy 載入觸發鍵的設定。
- `render-markdown` 已在 `Neovim 0.12.3` 下重新啟用。
  - `nvim-treesitter` 已切到 `main` branch，並以 `tree-sitter-cli 0.26.9` 重裝 parser 後恢復正常。
  - `render-markdown` 與 `headlines.nvim` 可同時載入，實測開啟 `TODO.md` 時兩者都會啟用。
  - 使用者層另外加了 `ignore(buf)`，讓 `render-markdown` 跳過 LSP hover 浮窗，避免 fenced code block 的 Treesitter 高亮再干擾 hover UI。
- 本次修改的檔案：
  - `init.lua`
  - `lua/plugins/markup.lua`
  - `lua/plugins/treesitter.lua`
  - `lua/user/config/plugins/MarkdownNvim.lua`
  - `lua/user/core/autocmds.lua`
  - `lua/user/keymappings/lsp.lua`
  - `lua/user/lsp.lua`
