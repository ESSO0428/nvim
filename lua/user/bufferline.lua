-- NOTE:
-- 保留少數特殊 group，其他已知 filetype 則自動建立同名 group。
--
-- 效能策略：
-- 1. 每個 buffer 只做一次完整分類，結果存入 group_cache。
-- 2. bufferline 即使反覆呼叫數百個 group matcher，
--    matcher 也只會讀取快取並比較字串。
-- 3. FileType、改名、刪除 buffer 時清除對應快取。
--
-- 這樣保留完整 filetype 自動分組，同時避免原本每次 redraw：
-- buffer 數 × group 數 × exclude matcher 數 × Vim API 呼叫。

local ok_filetypes, devicon_filetypes = pcall(require, "nvim-web-devicons.filetypes")

if not ok_filetypes then
  devicon_filetypes = require("user.core.filetypes")
end

-- 特殊處理的 filetype 不再建立普通同名 group。
local excluded_fts = {
  org = true,
  lua = true,
  vim = true,
}

-- group_cache[bufnr]:
--   string = 最終 group 名稱
--   false  = 沒有匹配的 group
--   nil    = 尚未計算或快取已失效
local group_cache = {}

local function detect_filetype(bufnr, filename)
  local ft = vim.bo[bufnr].filetype

  if ft ~= "" then
    return ft
  end

  -- 對 unloaded-but-listed buffer，filetype 經常為空。
  -- 這個 fallback 只會在該 buffer 第一次分類時執行。
  return vim.filetype.match({
    filename = filename,
  }) or ""
end

local function classify_buffer(buf)
  local bufnr = buf and buf.id

  if type(bufnr) ~= "number" or bufnr <= 0 then
    return nil
  end

  -- cache 命中：直接回傳，不做任何 API 呼叫
  local cached = group_cache[bufnr]
  if cached ~= nil then
    return cached ~= false and cached or nil
  end

  -- cache 未命中：才做完整驗證（每個 buffer 只跑一次）
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local basename = vim.fs.basename(filename)
  local lower_basename = basename:lower()
  local lower_filename = filename:lower()
  local ft = detect_filetype(bufnr, filename)

  local group

  -- 分類優先順序：
  -- 特殊語意分類優先，普通 filetype group 最後兜底。
  if basename:sub(1, 1) == "." then
    group = "Dotfiles"
  elseif ft == "org" then
    group = "OrgMode"
  elseif lower_basename:find("readme", 1, true) then
    group = "README"
  elseif lower_filename:match("%.md$") or lower_filename:match("%.txt$") then
    group = "Docs"
  elseif lower_basename:find("_test", 1, true)
      or lower_basename:find("_spec", 1, true) then
    group = "Tests"
  elseif lower_filename:match("%.csv$") or lower_filename:match("%.tsv$") then
    group = "Table"
  elseif lower_filename:match("%.sh$") then
    group = "Shell"
  elseif ft == "lua" or ft == "vim" then
    group = "Lua/Vim"
  elseif ft ~= ""
      and not excluded_fts[ft]
      and devicon_filetypes[ft] ~= nil then
    group = ft
  end

  group_cache[bufnr] = group or false
  return group
end

local function make_group_matcher(group_name)
  return function(buf)
    return classify_buffer(buf) == group_name
  end
end

local special_items = {
  {
    name = "Dotfiles",
    matcher = make_group_matcher("Dotfiles"),
  },
  {
    name = "OrgMode",
    auto_close = false,
    matcher = make_group_matcher("OrgMode"),
  },
  {
    name = "README",
    auto_close = false,
    matcher = make_group_matcher("README"),
  },
  {
    name = "Docs",
    auto_close = false,
    matcher = make_group_matcher("Docs"),
  },
  {
    name = "Shell",
    auto_close = false,
    matcher = make_group_matcher("Shell"),
  },
  {
    name = "Tests",
    priority = 2,
    icon = "",
    matcher = make_group_matcher("Tests"),
  },
  {
    name = "Table",
    auto_close = false,
    matcher = make_group_matcher("Table"),
  },
  {
    name = "Lua/Vim",
    auto_close = false,
    matcher = make_group_matcher("Lua/Vim"),
  },
}

-- 保留所有 devicons 已知 filetype。
-- 因此 session 啟動後首次開啟的新 filetype 也能立即分組。
local auto_ft_names = {}

for ft in pairs(devicon_filetypes) do
  if type(ft) == "string" and ft ~= "" and not excluded_fts[ft] then
    auto_ft_names[#auto_ft_names + 1] = ft
  end
end

table.sort(auto_ft_names)

local auto_ft_items = {}

for _, ft in ipairs(auto_ft_names) do
  -- 明確建立每輪獨立 local，避免 closure 捕捉迴圈變數的相容性問題。
  local group_name = ft

  auto_ft_items[#auto_ft_items + 1] = {
    name = group_name,
    auto_close = false,
    matcher = make_group_matcher(group_name),
  }
end

local group_items = {}

vim.list_extend(group_items, special_items)
vim.list_extend(group_items, auto_ft_items)

Nvim.builtin.bufferline.options.groups = {
  options = {
    toggle_hidden_on_enter = true,
  },
  items = group_items,
}

-- 清除單一 buffer 的分類快取。
local function invalidate_buffer_cache(bufnr)
  if type(bufnr) == "number" and bufnr > 0 then
    group_cache[bufnr] = nil
  end
end

local cache_group = vim.api.nvim_create_augroup("BufferlineGroupClassificationCache", {
  clear = true,
})

-- 這些事件可能改變檔名或 filetype，因此需要重新分類。
vim.api.nvim_create_autocmd({
  "BufAdd",
  "BufFilePost",
  "FileType",
}, {
  group = cache_group,
  callback = function(args)
    invalidate_buffer_cache(args.buf)
  end,
})

-- buffer 消失時移除快取，避免長期 session 留下無用資料。
vim.api.nvim_create_autocmd({
  "BufDelete",
  "BufWipeout",
}, {
  group = cache_group,
  callback = function(args)
    invalidate_buffer_cache(args.buf)
  end,
})

-- 可選的手動清除命令。
-- 修改分類規則後，不必重啟 Neovim：
--
--   :BufferlineGroupCacheClear
--
vim.api.nvim_create_user_command("BufferlineGroupCacheClear", function()
  group_cache = {}

  -- 強制 tabline 重新繪製。
  vim.cmd.redrawtabline()
end, {
  desc = "Clear cached bufferline group classifications",
})
