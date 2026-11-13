local stdpath = vim.fn.stdpath
local path_sep = package.config:sub(1, 1)

_G.Nvim = _G.Nvim or {}

local function path_join(...)
  return table.concat({ ... }, path_sep)
end

local function sibling_app_path(path, appname)
  return (path:gsub(vim.pesc(path_sep) .. "nvim$", path_sep .. appname))
end

local native_paths = {
  config = stdpath "config",
  data = stdpath "data",
  state = stdpath "state",
  cache = stdpath "cache",
}

local path_profile = "lvim" -- change to "nvim / lvim" to switch back to Neovim's own user-data paths.
local path_profiles = {
  nvim = {
    data = native_paths.data,
    state = native_paths.state,
    cache = native_paths.cache,
  },
  lvim = {
    data = sibling_app_path(native_paths.data, "lvim"),
    state = sibling_app_path(native_paths.state, "lvim"),
    cache = sibling_app_path(native_paths.cache, "lvim"),
  },
}

local selected_paths = path_profiles[path_profile] or path_profiles.nvim
Nvim.paths = {
  profile = path_profile,
  profiles = path_profiles,
  native = native_paths,
  config = native_paths.config,
  data = selected_paths.data,
  state = selected_paths.state,
  cache = selected_paths.cache,
}
Nvim.paths.sessions_dir = path_join(Nvim.paths.data, "sessions")
Nvim.paths.scratch_dir = path_join(Nvim.paths.data, "scratch")
Nvim.paths.snacks_dir = path_join(Nvim.paths.data, "snacks")
Nvim.paths.bookmarks_dir = path_join(Nvim.paths.data, "nvim_bookmarks")
Nvim.paths.harpoon_file = path_join(Nvim.paths.data, "harpoon.json")
Nvim.paths.shada_dir = path_join(Nvim.paths.state, "shada")
Nvim.paths.shadafile = path_join(Nvim.paths.shada_dir, "main.shada")
Nvim.paths.undodir = path_join(Nvim.paths.state, "undo")

for _, dir in ipairs {
  Nvim.paths.sessions_dir,
  Nvim.paths.scratch_dir,
  Nvim.paths.snacks_dir,
  Nvim.paths.bookmarks_dir,
  Nvim.paths.shada_dir,
  Nvim.paths.undodir,
} do
  vim.fn.mkdir(dir, "p")
end

vim.opt.shadafile = Nvim.paths.shadafile
vim.opt.undodir = Nvim.paths.undodir

--  HACK: Use '/' in netrw to prevent tree view breaking on Windows after 'x'
if vim.fn.exists("+shellslash") == 1 then
  vim.o.shellslash = true
end

-- NOTE: Neovim writes session data (registers, marks, etc.) to the `main.shada` file on exit.
-- Sometimes, it creates temporary files like `main.shada.tmp.x`, but if many of these accumulate (e.g. .tmp.a to .tmp.z),
-- Neovim may fail to write and show error E138: "All tmp.X files exist, cannot write ShaDa file".
-- To prevent this, we automatically remove empty `.tmp.*` files in the shada directory during shutdown.
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local uv = vim.loop
    local path = Nvim.paths.shada_dir
    local pattern = "^main%.shada%.tmp%.([a-z])$"

    local fs = uv.fs_scandir(path)
    if not fs then
      return
    end

    -- { {name=..., full=..., size=..., suffix=...}, ... }
    local tmp_files = {}

    for name in function()
      return uv.fs_scandir_next(fs)
    end do
      local suffix = name:match(pattern)
      if suffix then
        local fullpath = path_join(path, name)
        local stat = uv.fs_stat(fullpath)
        if stat then
          table.insert(tmp_files, {
            name = name,
            full = fullpath,
            size = stat.size,
            suffix = suffix,
          })
        end
      end
    end

    -- Delete empty shada tmp
    for _, file in ipairs(tmp_files) do
      if file.size == 0 then
        uv.fs_unlink(file.full)
      end
    end

    -- Delete shada tmp only keep one
    local non_empty = vim.tbl_filter(function(f)
      return f.size > 0
    end, tmp_files)
    if #non_empty > 1 then
      table.sort(non_empty, function(a, b)
        return a.suffix < b.suffix
      end)

      for i = 1, #non_empty - 1 do
        uv.fs_unlink(non_empty[i].full)
      end
    end
  end,
  desc = "Smart cleanup of ShaDa tmp files",
})


-- lunarvim default options
local default_options = {
  backup = false,            -- creates a backup file
  clipboard = "unnamedplus", -- allows neovim to access the system clipboard
  cmdheight = 1,             -- more space in the neovim command line for displaying messages
  completeopt = { "menuone", "noselect" },
  conceallevel = 0,          -- so that `` is visible in markdown files
  fileencoding = "utf-8",    -- the encoding written to a file
  foldmethod = "manual",     -- folding, set to "expr" for treesitter based folding
  foldexpr = "",             -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
  hidden = true,             -- required to keep multiple buffers and open multiple buffers
  hlsearch = true,           -- highlight all matches on previous search pattern
  ignorecase = true,         -- ignore case in search patterns
  mouse = "a",               -- allow the mouse to be used in neovim
  pumheight = 10,            -- pop up menu height
  showmode = false,          -- we don't need to see things like -- INSERT -- anymore
  smartcase = true,          -- smart case
  splitbelow = true,         -- force all horizontal splits to go below current window
  splitright = true,         -- force all vertical splits to go to the right of current window
  swapfile = false,          -- creates a swapfile
  termguicolors = true,      -- set term gui colors (most terminals support this)
  timeoutlen = 1000,         -- time to wait for a mapped sequence to complete (in milliseconds)
  title = true,              -- set the title of window to the value of the titlestring
  -- opt.titlestring = "%<%F%=%l/%L - nvim" -- what the title of the window will be set to
  undofile = true,           -- enable persistent undo
  updatetime = 100,          -- faster completion
  writebackup = false,       -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  expandtab = true,          -- convert tabs to spaces
  shiftwidth = 2,            -- the number of spaces inserted for each indentation
  tabstop = 2,               -- insert 2 spaces for a tab
  cursorline = true,         -- highlight the current line
  number = true,             -- set numbered lines
  numberwidth = 4,           -- set number column width to 2 {default 4}
  signcolumn = "yes",        -- always show the sign column, otherwise it would shift the text each time
  wrap = false,              -- display lines as one long line
  scrolloff = 8,             -- minimal number of screen lines to keep above and below the cursor.
  sidescrolloff = 8,         -- minimal number of screen lines to keep left and right of the cursor.
  showcmd = false,
  ruler = false,
  laststatus = 3,
}

for k, v in pairs(default_options) do
  vim.opt[k] = v
end

-- References: https://github.com/nvim-lua/kickstart.nvim
-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- 摺疊代碼
vim.wo.foldlevel = 99
vim.wo.foldenable = true
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- vim.g.conda_auto_activate_base = 0 -- 关闭 base 环境的自动激活
-- vim.g.conda_auto_env = 1 -- 开启自动激活环境
-- vim.g.conda_env = 'base' -- 设置自动激活的 conda 环境
-- add rtp $HOME/.cheetseet/ as help file
vim.opt.rtp:append { os.getenv("HOME") .. "/.cheatsheet" }

local function get_clipboard_content()
  local content = vim.fn.getreg('')
  local regtype = vim.fn.getregtype('')
  return { vim.fn.split(content, '\n'), regtype }
end

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    -- neovim official pasted method (will delay in windows terminal)
    -- ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    -- ['*'] = require('vim.ui.clipboard.osc52').paste('*')
    -- my custom pasted method (will not delay in windows terminal)
    ['+'] = get_clipboard_content,
    ['*'] = get_clipboard_content
  }
}
vim.opt.termguicolors = true

-- 取消預覽取代結果
-- vim.o.fileformats = "unix"
-- vim.opt.inccommand = ""
vim.opt.inccommand = "split"

-- vim.opt.spell = true
local filetypes = vim.tbl_extend("force", require("user.core.filetypes"), {
  text = true,
  plaintex = true,
  typst = true,
  gitcommit = true,
  markdown = true,
})
-- 排除 Terminal
filetypes.terminal = nil
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup('spell_text', { clear = true }),
  pattern = vim.tbl_keys(filetypes),
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end

    -- vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.opt.spelllang = "en,cjk"
-- spell options noplainbuffer (default) add camel
vim.opt.spelloptions:append "camel"

vim.opt.list = false
vim.opt.listchars:append "space:·"

-- Pmenu
vim.opt.completeopt = "menuone,noselect,popup"

vim.g.PythonEnv = os.getenv("CONDA_DEFAULT_ENV") or os.getenv("VIRTUAL_ENV")
vim.g.WorkDirectoryPath = vim.fn.getcwd()

-- NOTE: For Nvim 0.11+, the python3 provider no longer falls back to system python.
-- If `g:python3_host_prog` is not set, it defaults to `v:null`, causing errors like
-- "E475: Invalid value for argument cmd: 'v:null' is not executable".
-- This restores the old behavior by auto-detecting python3 from system PATH.
if vim.g.python3_host_prog == nil then
  local python3 = vim.fn.exepath("python3")
  if python3 ~= "" then
    vim.g.python3_host_prog = python3
  end
end

-- vim options
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- signcolumn
vim.opt.numberwidth = 3
vim.opt.signcolumn = "auto:6"
vim.opt.foldcolumn = "auto:1"

-- conceal
vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"

-- 與 vscode 集成
-- ex: code --remote ssh-remote+LabServerDP
-- default hostname
vim.g.host = "YourVscodeReomoteServerName"

-- 與 `vscode remote ssh` 集成
-- 取得如範例的指令: `code --remote ssh-remote+LabServerDP`
-- 這裡用於取得 `hostname`, ex : `LabServerDP`（Windows ~/.ssh/config 的 Host 別名）
-- 查詢順序：
--   1. ~/.ssh/host_names.d/<本機 IP>（內容是 Host 別名；每個 IP 一個檔案，共用 NFS 的 server 不會互相覆蓋）
--   2. 舊格式 ~/.ssh/host_names（每行 "Host IP"）
-- 本機 IP 依序嘗試：預設路由的來源 IP，再來是所有 global IPv4（多網卡 / docker0 也對得上）
-- 找不到時保留 `vim.g.host`（預設或最後一次使用的 hostname）
-- 登錄方式：server 上 :UpdateRegisterHostHameFromLocal，或在 WSL 執行 `vscode-remote-host-sync <Host>`
-- ---
-- 特別注意範例的 `YourVscodeReomoteServerName` 在 `rcode` 會被視為排除對象
Nvim.vscode_remote = Nvim.vscode_remote or {}
Nvim.vscode_remote.host_names_dir = vim.fn.expand("~/.ssh/host_names.d")
Nvim.vscode_remote.legacy_host_names = vim.fn.expand("~/.ssh/host_names")

function Nvim.vscode_remote.valid_host_alias(name)
  return type(name) == "string" and name:match("^[%w._-]+$") ~= nil
end

--- Local IPv4 addresses, primary (default route source) first
---@return string[]
function Nvim.vscode_remote.local_ipv4s()
  local ips, seen = {}, {}
  local function add(ip)
    if ip and not seen[ip] then
      seen[ip] = true
      table.insert(ips, ip)
    end
  end
  local ipv4 = "(%d+%.%d+%.%d+%.%d+)"

  if vim.fn.executable("ip") == 1 then
    local route = vim.fn.system({ "ip", "-o", "route", "get", "8.8.8.8" })
    if vim.v.shell_error == 0 then
      add(route:match("src%s+" .. ipv4))
    end
    local addrs = vim.fn.system({ "ip", "-o", "-4", "addr", "show", "scope", "global" })
    if vim.v.shell_error == 0 then
      for ip in addrs:gmatch("inet%s+" .. ipv4) do
        add(ip)
      end
    end
  end
  if #ips == 0 and vim.fn.executable("hostname") == 1 then
    local out = vim.fn.system({ "hostname", "-I" })
    if vim.v.shell_error == 0 then
      for ip in out:gmatch(ipv4) do
        add(ip)
      end
    end
  end
  return ips
end

--- Registered Host alias for this server
---@return string|nil host, string|nil ip
function Nvim.vscode_remote.lookup_host()
  local valid = Nvim.vscode_remote.valid_host_alias
  local ips = Nvim.vscode_remote.local_ipv4s()

  for _, ip in ipairs(ips) do
    local file = Nvim.vscode_remote.host_names_dir .. "/" .. ip
    if vim.fn.filereadable(file) == 1 then
      local name = vim.trim(vim.fn.readfile(file, "", 1)[1] or "")
      if valid(name) then
        return name, ip
      end
    end
  end

  local legacy = Nvim.vscode_remote.legacy_host_names
  if vim.fn.filereadable(legacy) == 1 then
    local wanted = {}
    for _, ip in ipairs(ips) do
      wanted[ip] = true
    end
    for _, line in ipairs(vim.fn.readfile(legacy)) do
      local name, ip = line:match("^%s*(%S+)%s+(%S+)")
      if ip and wanted[ip] and valid(name) then
        return name, ip
      end
    end
  end
  return nil
end

---@param host string|nil
function GetServerHostName(host)
  vim.g.host = Nvim.vscode_remote.lookup_host() or host or vim.g.host
  return vim.g.host
end

-- `rcode` resolves the host on demand, so avoid shell/file IO on every startup.

-- terminal events
local term_group = vim.api.nvim_create_augroup("TerminalEvents", { clear = true })

-- trigger User BufferTermOpen when terminal buffer is opened
vim.api.nvim_create_autocmd("BufLeave", {
  group = term_group,
  pattern = "term://*",
  callback = function(args)
    vim.api.nvim_exec_autocmds("User", {
      pattern = "BufTermLeave",
      modeline = false,
      data = { bufnr = args.buf }
    })
  end,
})

-- checktime when focus gained, terminal closed or left
local group = vim.api.nvim_create_augroup("checktime", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "BufTermLeave", -- 你的自定義事件名稱要放在 pattern
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- DownloadToLocal / UpdateRegisterHostHameFromLocal (vscode remote ssh helpers)
vim.schedule(function()
  local file = vim.fs.joinpath(vim.fn.stdpath("config"), "vim/ssh_command.vim")
  if vim.fn.filereadable(file) == 1 then
    vim.cmd("source " .. vim.fn.fnameescape(file))
  end
end)
vim.cmd("source " .. vim.fn.stdpath("config") .. "/keymap.vim")
