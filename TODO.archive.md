# TODO

## 快捷鍵遷移筆記

### 值得補回的缺少快捷鍵

#### Harpoon

- [x] `n +` -> `require('harpoon.ui').nav_next()` `來源: lvim.keys.normal_mode`
- [x] `n _` -> `require('harpoon.ui').nav_prev()` `來源: lvim.keys.normal_mode`
- [x] `n =` -> `Telescope harpoon marks` `來源: lvim.keys.normal_mode`
- [x] `n mf` -> `require('harpoon.mark').add_file()` `來源: lvim.keys.normal_mode`
- [x] `n mw` -> `require('harpoon.ui').toggle_quick_menu()` `來源: lvim.keys.normal_mode`

#### Quickfix / Trouble / 其他

- [x] `n [q` -> `:cprev` `來源: LunarVim 上游預設 lvim.keymappings.defaults.normal_mode["[q"]`
- [x] `n ]q` -> `:cnext` `來源: LunarVim 上游預設 lvim.keymappings.defaults.normal_mode["]q"]`
- [x] `n sq` -> `FloatIntoCurrent` `來源: lvim.keys.normal_mode`
- [x] `n ga` -> `TSJToggle` `來源: lvim.keys.normal_mode`
- [x] `n sgh` -> `require('hoversplit').split_remain_focused()` `來源: lvim.keys.normal_mode`
- [x] `n me` -> `Nvim.Buffer_Manager.scratch_opener.open_scratch()` `來源: lvim.keys.normal_mode`
- [x] `n <Space>ta` -> `Limelight` `來源: 一般 normal mapping 目前在 lvim table 中未定義；功能入口來自 lvim.builtin.which_key.mappings.t.a`
  - 已補普通 normal mapping，也已補 which-key 註冊項
- [x] `v <Space>ta` -> `Limelight` `來源: lvim.keys.visual_mode`
  - 已改成與 `lvim` 一致：`<Plug>(Limelight)`
- [x] `which-key <Space>ta` -> `Limelight` `來源: lvim.builtin.which_key.mappings.t.a`
  - `lvim`: `lvim.builtin.which_key.mappings["ta"] = { "<cmd>Limelight<cr>", "Limelight Close" }`
  - `nvim`: 已補對應的 which-key 註冊項
- [x] `which-key <Space>tA` -> `Limelight!` `來源: lvim.builtin.which_key.mappings.t.A`
  - `lvim`: `lvim.builtin.which_key.mappings["tA"] = { "<cmd>Limelight!<cr>", "Limelight Close (All)" }`
  - `nvim`: 已補普通 `n <Space>tA` mapping，也已補對應的 which-key 註冊項
- [x] `x <M-j>` -> 將選取區塊往下移 `來源: LunarVim 上游預設 lvim.keymappings.defaults.visual_block_mode["<A-j>"]`
- [x] `x <M-k>` -> 將選取區塊往上移 `來源: LunarVim 上游預設 lvim.keymappings.defaults.visual_block_mode["<A-k>"]`
- [x] `v <` -> `<gv` `來源: LunarVim 上游預設 lvim.keymappings.defaults.visual_mode["<"]`
- [x] `v >` -> `>gv` `來源: LunarVim 上游預設 lvim.keymappings.defaults.visual_mode[">"]`

#### DBUI / LSP / 診斷

- [x] `n <Space>de` -> `DBUIToggle` `來源: lvim.keys.normal_mode`
- [x] `n <Space>dE` -> `tab DBUI` `來源: lvim.keys.normal_mode`
- [x] `n <Space>ui` -> `LspInfo` `來源: lvim.keys.normal_mode`
- [x] `n <Space>uI` -> `Mason` `來源: lvim.keys.normal_mode`
- [x] `n <Space>ud` -> `Telescope diagnostics bufnr=0 theme=get_ivy` `來源: lvim.keys.normal_mode`
- [x] `n <Space>ue` -> `Telescope quickfix` `來源: lvim.keys.normal_mode`
- [x] `n <Space>ul` -> `vim.lsp.codelens.run()` `來源: lvim.keys.normal_mode`
- [x] `n <Space>uq` -> `vim.lsp.diagnostic.setloclist()` `來源: lvim.keys.normal_mode`
- [x] `n <Space>us` -> `Telescope lsp_document_symbols` `來源: lvim.keys.normal_mode`
- [x] `n <Space>uS` -> `Telescope lsp_dynamic_workspace_symbols` `來源: lvim.keys.normal_mode`
- [x] `n <Space>uw` -> `Telescope diagnostics` `來源: lvim.keys.normal_mode`
- [x] `n <Space>rn` -> `LspbufRename` `來源: lvim.keys.normal_mode`

### Table 層級待盤點

#### `<leader>t` table 入口

- [x] `n <Space>td` -> `Trouble diagnostics toggle filter.buf=0` `來源: lvim.builtin.which_key.mappings.t.d`
- [x] `n <Space>tf` -> `Trouble lsp_definitions` `來源: lvim.builtin.which_key.mappings.t.f`
- [x] `n <Space>tl` -> `Trouble loclist` `來源: lvim.builtin.which_key.mappings.t.l`
- [x] `n <Space>tq` -> `Trouble quickfix` `來源: lvim.builtin.which_key.mappings.t.q`
- [x] `n <Space>tr` -> `Trouble lsp_references` `來源: lvim.builtin.which_key.mappings.t.r`
- [x] `n <Space>tw` -> `Trouble diagnostics toggle` `來源: lvim.builtin.which_key.mappings.t.w`

#### `<leader>g` table 入口

- [x] `n <Space>gD` -> `DiffviewFileHistory %` `來源: lvim.builtin.which_key.mappings.g.D`
- [x] `n <Space>gI` -> `Gitsigns toggle_current_line_blame` `來源: lvim.builtin.which_key.mappings.g.I`
- [x] `n <Space>gL` -> `gitsigns.blame_line({ full = true })` `來源: lvim.builtin.which_key.mappings.g.L`
- [x] `n <Space>gR` -> `gitsigns.reset_buffer()` `來源: LunarVim 上游 which-key g.R`
- [x] `n <Space>gj` -> `Floggit blame` `來源: lvim.builtin.which_key.mappings.g.j`
- [x] `n <Space>gm` -> `Flogsplit` `來源: lvim.builtin.which_key.mappings.g.m`
- [x] `n <Space>gv` -> `DiffviewFileHistory` `來源: lvim.builtin.which_key.mappings.g.v`

#### `<leader>U` table 入口

- [x] `n <Space>UF` -> `Find Lazy pack files` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.U.F`
  - `nvim` 搜尋目標已對齊為本地 lazy 套件根目錄：`require("lazy.core.config").options.root`
- [x] `n <Space>UG` -> `Grep Lazy pack files` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.U.G`
  - `nvim` 搜尋目標已對齊為本地 lazy 套件根目錄：`require("lazy.core.config").options.root`
- [x] `n <Space>Uf` -> `Find LunarVim files` `來源: LunarVim 上游 which-key L.f；本地以 U.f 承接`
  - `nvim` 這次依需求改成搜尋使用者設定目錄：`vim.fn.stdpath("config")`
- [x] `n <Space>Ug` -> `Grep LunarVim files` `來源: LunarVim 上游 which-key L.g；本地以 U.g 承接`
  - `nvim` 這次依需求改成搜尋使用者設定目錄：`vim.fn.stdpath("config")`

#### `<leader>d` table 入口

- [x] `n <Space>d;` -> `telescope.extensions.dap.commands()` `來源: lvim.builtin.which_key.mappings.d[";"]`
- [x] `n <Space>dL` -> `Toggle UI Auto-Open` `來源: lvim.builtin.which_key.mappings.d.L`
  - `nvim` 以等價語意實作：切換 `Nvim.DAPUI.auto_open`，控制 debug 初始化時是否自動開啟 DAP UI
- [x] `n <Space>dU` -> `dapui.toggle({ reset = true })` `來源: LunarVim 上游 which-key d.U`
- [x] `n <Space>d\` -> `persistent-breakpoints.api.clear_all_breakpoints()` `來源: lvim.builtin.which_key.mappings.d["\\"]`
- [x] ``n <Space>d` `` -> `dap.restart()` `來源: lvim.builtin.which_key.mappings.d["`"]`
- [x] `n <Space>dfW` -> `diffoff!` `來源: lvim.builtin.which_key.mappings.d.fW`
- [x] `n <Space>dfe` -> `windo set noscrollbind` `來源: lvim.builtin.which_key.mappings.d.fe`
- [x] `n <Space>dfs` -> `set scrollbind!` `來源: lvim.builtin.which_key.mappings.d.fs`
- [x] `n <Space>dft` -> `diffthis` `來源: lvim.builtin.which_key.mappings.d.ft`
- [x] `n <Space>dfw` -> `diffoff` `來源: lvim.builtin.which_key.mappings.d.fw`
- [x] `n <Space>dlc` -> `persistent-breakpoints.api.set_breakpoint(...)` `來源: lvim.builtin.which_key.mappings.d.lc`
- [x] `n <Space>dle` -> `Edit Breakpoint` `來源: lvim.builtin.which_key.mappings.d.le`
- [x] `n <Space>dll` -> `persistent-breakpoints.api.set_breakpoint(..., log point message)` `來源: lvim.builtin.which_key.mappings.d.ll`

#### neo-tree / telescope 集成

- [x] `neo-tree: n <Space>sf` -> `find_files(cwd=node_basedir)` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/telescope.lua::neotree_telescope_find_file`
- [x] `neo-tree: n <Space>sF` -> `Telescope file_browser path=node_basedir` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/telescope.lua::telescope_file_browser`
- [x] `neo-tree: n <Space>sg` -> `live_grep(cwd=node_basedir)` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/telescope.lua::neotree_telescope_live_grep`
- [x] `neo-tree: n <Space>sG` -> `Telescope live_grep_args search_dirs=node_basedir` `來源: ~/.config/lvim lua/user/nvimtree.lua + lua/user/telescope.lua::telescope_live_grep_args`
- [x] `neo-tree: n <Space>sm` -> `telescope.extensions.media_files.media_files()` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/telescope.lua::telescope_media_files`
- [x] `neo-tree: n <Space>sd` -> `CderOpen(node_basedir)` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/nvimtree.lua::CderOpen`
- [x] `neo-tree: n <Space>TT` -> `TodoTelescope cwd=node_basedir theme=get_ivy` `來源: ~/.config/lvim lua/user/neotree.lua + lua/user/nvimtree.lua::ToDoOpen`
  - 這一組是 `neo-tree` 視窗內的 local mapping，不是一般 buffer 的全域 `<leader>s*>` / `<leader>T*>` 對應。

#### visual / table 入口

- [x] `v <Space>o` -> `zA<Esc>` `來源: lvim.keys.visual_mode`
- [x] `v <Space>ta` -> `<Plug>(Limelight)` `來源: lvim.keys.visual_mode`

#### 其他後補群組

- [x] `n <Space>TT` -> `TodoTelescope theme=get_ivy` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.T.T`
  - `nvim` 現在同時具備全域 runtime mapping，且在 `neo-tree` 內仍會用節點目錄作為 `cwd`
- [x] `n <Space>Tw` -> `TodoTrouble` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.T.w`
- [x] `n <Space>Td` -> `Trouble todo filter.buf=0` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.T.d`
- [x] `n <Space>Oa` -> `ufo.closeAllFolds()` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.Oa`
  - `nvim` 目前以等價行為存在：`<leader>Oa` 會走 fold all，runtime 目前對應 `zM`
- [x] `n <Space>Od` -> `ufo.openAllFolds()` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.Od`
  - `nvim` 目前以等價行為存在：`<leader>Od` 會走 unfold all，runtime 目前對應 `zR`
- [x] `n <Space>Ox` -> `zx` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.Ox`
- [x] `n <Space>On` -> `narrow_except_selection()` `來源: ~/.config/lvim user/config/plugins/Narrowing.lua -> lvim.builtin.which_key.mappings.On`
- [x] `n <Space>E` -> `Neotree toggle remote` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.E`
- [x] `n <Space>t1` -> `tabn 1` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t1`
- [x] `n <Space>t2` -> `tabn 2` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t2`
- [x] `n <Space>t3` -> `tabn 3` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t3`
- [x] `n <Space>t4` -> `tabn 4` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t4`
- [x] `n <Space>t5` -> `tabn 5` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t5`
- [x] `n <Space>t6` -> `tabn 6` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t6`
- [x] `n <Space>t7` -> `tabn 7` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t7`
- [x] `n <Space>t8` -> `tabn 8` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t8`
- [x] `n <Space>t9` -> `tabn 9` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t9`
- [x] `n <Space>t0` -> `tablast` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t0`
- [x] `n <Space>t-` -> `g<Tab>` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t-`
- [x] `n <Space>t'` -> `tab split` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t'`
- [x] `n <Space>t/` -> `tabn 1` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t/`
- [x] `n <Space>t,` -> `tabprevious` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t,`
- [x] `n <Space>t.` -> `tabnext` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t.`
- [x] `n <Space>t\` -> `tabclose` `來源: ~/.config/lvim lvim.builtin.which_key.mappings.t\`
