-- blink.cmp source：Claude Code prompt 檔（claude-prompt-*.md）裡的 `@` 檔案 / 資料夾補全
--
-- 檔案清單：cwd 底下 `rg --files --hidden`（遵守 .gitignore、排除 .git），
-- 沒有 rg 時改用 fd，再不行用 git ls-files。結果依 cwd 快取 30 秒，非同步取得。
--
-- blink 的 keyword 只取最後一個 `/` 之後（`@lua/user/bl` 只會拿 `bl` 比對），
-- 所以這裡用 `@` 後的完整字串自己篩選、排序，再交給 blink。
-- 只在行首或空白後的 `@` 觸發，email 之類的 `a@b` 不會跳出來。

local uv = vim.uv or vim.loop

local M = {}

local PROMPT_PATTERN = "/claude%-[^/]*/claude%-prompt%-[^/]*%.md$"
local CACHE_TTL_MS = 30000
local MAX_FILES = 50000
local MAX_ITEMS = 100

---@type table<string, { at: integer, entries: { path: string, dir: boolean }[]?, pending: function[]? }>
local cache = {}

local function list_cmd()
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--files", "--hidden", "--glob", "!.git" }
  elseif vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
  elseif vim.fn.executable("git") == 1 then
    return { "git", "ls-files", "--cached", "--others", "--exclude-standard" }
  end
end

--- files plus every parent directory (directories end with `/`)
local function build_entries(stdout)
  local entries, dirs = {}, {}
  local n = 0
  for path in stdout:gmatch("[^\r\n]+") do
    path = path:gsub("^%./", "")
    n = n + 1
    if n > MAX_FILES then
      break
    end
    table.insert(entries, { path = path, dir = false })
    local parent = path:match("^(.*)/[^/]+$")
    while parent and not dirs[parent] do
      dirs[parent] = true
      table.insert(entries, { path = parent .. "/", dir = true })
      parent = parent:match("^(.*)/[^/]+$")
    end
  end
  return entries
end

--- async; cb(entries) runs on the main loop
local function get_entries(cwd, cb)
  local c = cache[cwd]
  local now = uv.now()
  if c and c.entries and now - c.at < CACHE_TTL_MS then
    return cb(c.entries)
  end
  if c and c.pending then
    table.insert(c.pending, cb)
    return
  end
  local cmd = list_cmd()
  if not cmd then
    return cb({})
  end
  cache[cwd] = { at = now, entries = c and c.entries, pending = { cb } }
  vim.system(cmd, { cwd = cwd, text = true, timeout = 5000 }, vim.schedule_wrap(function(res)
    local entries = build_entries(res.stdout or "")
    local waiting = cache[cwd].pending or {}
    cache[cwd] = { at = uv.now(), entries = entries }
    for _, fn in ipairs(waiting) do
      fn(entries)
    end
  end))
end

--- rank a path against the typed query (lower is better), nil = no match
local function rank(path, query)
  if query == "" then
    return select(2, path:gsub("/", "")) * 10 + #path / 1000 -- shallow first
  end
  local p, q = path:lower(), query:lower()
  if p == q then
    return nil -- 已經完整輸入的資料夾本身
  end
  if vim.startswith(p, q) then
    return 0 + #p / 1000
  end
  local base = p:match("[^/]*/?$")
  local s = p:find(q, 1, true)
  if s then
    return (base:find(q, 1, true) and 1 or 2) + s / 1000
  end
  -- subsequence (fuzzy)：整段落在檔名裡的優先
  local function subseq(str)
    local pos = 0
    for i = 1, #q do
      pos = str:find(q:sub(i, i), pos + 1, true)
      if not pos then
        return false
      end
    end
    return true
  end
  if subseq(base) then
    return 3 + #base / 1000
  end
  if subseq(p) then
    return 4 + #p / 1000
  end
  return nil
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.api.nvim_buf_get_name(0):find(PROMPT_PATTERN) ~= nil
end

function M:get_trigger_characters()
  return { "@", "/", "." }
end

function M:get_completions(ctx, callback)
  local row, col = ctx.cursor[1], ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  local at, query = before:match("()@([^%s@]*)$")
  local empty = { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
  if not at or (at > 1 and not before:sub(at - 1, at - 1):match("%s")) then
    return callback(empty)
  end

  local cancelled = false
  get_entries(vim.fn.getcwd(), function(entries)
    if cancelled then
      return
    end
    local matched = {}
    for _, e in ipairs(entries) do
      local r = rank(e.path, query)
      if r then
        table.insert(matched, { e = e, r = r })
      end
    end
    table.sort(matched, function(a, b)
      return a.r < b.r
    end)

    local kinds = require("blink.cmp.types").CompletionItemKind
    local items = {}
    for i = 1, math.min(#matched, MAX_ITEMS) do
      local e = matched[i].e
      table.insert(items, {
        label = "@" .. e.path,
        -- blink 只拿最後一段 keyword 比對；給完整路徑讓它一定命中，順序由 score_offset 決定
        filterText = e.path,
        kind = e.dir and kinds.Folder or kinds.File,
        score_offset = MAX_ITEMS - i,
        textEdit = {
          -- 資料夾不加空白，方便繼續往下補全
          newText = "@" .. e.path .. (e.dir and "" or " "),
          range = {
            start = { line = row - 1, character = at - 1 },
            ["end"] = { line = row - 1, character = col },
          },
        },
      })
    end
    -- 每打一個字都重新篩選（完整路徑比對由這裡負責）
    callback({ items = items, is_incomplete_forward = true, is_incomplete_backward = true })
  end)
  return function()
    cancelled = true
  end
end

-- for tests
M._rank = rank
M._get_entries = get_entries

return M
