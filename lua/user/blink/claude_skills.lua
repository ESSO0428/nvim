-- blink.cmp source：Claude Code prompt 檔（$EDITOR 開的 claude-prompt-*.md）裡的 `/` skill / command 補全
--
-- 來源（同名時前面的優先）：
--   <cwd>/.claude/skills/<name>/SKILL.md      專案 skill
--   ~/.claude/skills/<name>/SKILL.md          個人 skill（多半是連到 ~/.agents/skills 的 symlink）
--   <cwd>/.claude/commands/<name>.md          專案 slash command
--   ~/.claude/commands/<name>.md              個人 slash command
--   ~/.claude/plugins/cache/<market>/<plugin>/<ver>/skills/<name>/SKILL.md   → /<plugin>:<name>
--
-- 只在行首或空白後的 `/` 觸發，像 `src/foo` 這種路徑不會跳出來。

local uv = vim.uv or vim.loop

local M = {}

local PROMPT_PATTERN = "/claude%-[^/]*/claude%-prompt%-[^/]*%.md$"
local CACHE_TTL_MS = 10000

local cache = { at = 0, cwd = nil, items = nil }

--- frontmatter 的 name / description（支援單行、引號與 `>` / `|` 多行）
---@param file string
---@return string|nil name, string|nil description
local function read_frontmatter(file)
  local ok, lines = pcall(vim.fn.readfile, file, "", 60)
  if not ok or lines[1] ~= "---" then
    return nil, nil
  end
  local meta, key = {}, nil
  for i = 2, #lines do
    local line = lines[i]
    if line == "---" then
      break
    end
    local k, v = line:match("^([%w_-]+):%s*(.*)$")
    if k then
      key = k
      v = v:gsub("^[>|][-+]?%s*$", "")
      meta[k] = v
    elseif key and line:match("^%s+%S") then
      meta[key] = vim.trim((meta[key] or "") .. " " .. vim.trim(line))
    end
  end
  local function clean(s)
    if not s or s == "" then
      return nil
    end
    s = vim.trim(s)
    return (s:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1"))
  end
  return clean(meta.name), clean(meta.description)
end

local function list_dir(dir)
  local out = {}
  local handle = uv.fs_scandir(dir)
  if not handle then
    return out
  end
  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    table.insert(out, { name = name, type = typ })
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

local function collect()
  local home = vim.fn.expand("~")
  local cwd = vim.fn.getcwd()
  local entries, seen = {}, {}

  local function add(label, kind, desc, file)
    if seen[label] then
      return
    end
    seen[label] = true
    table.insert(entries, { label = label, kind = kind, description = desc, file = file })
  end

  local function scan_skills(dir, prefix)
    for _, e in ipairs(list_dir(dir)) do
      if e.name:sub(1, 1) ~= "." then
        local file = dir .. "/" .. e.name .. "/SKILL.md"
        if uv.fs_stat(file) then
          local name, desc = read_frontmatter(file)
          add((prefix or "") .. (name or e.name), "skill", desc, file)
        end
      end
    end
  end

  local function scan_commands(dir)
    for _, e in ipairs(list_dir(dir)) do
      local base = e.name:match("^(.+)%.md$")
      if base then
        local file = dir .. "/" .. e.name
        local _, desc = read_frontmatter(file)
        add(base, "command", desc, file)
      end
    end
  end

  scan_skills(cwd .. "/.claude/skills")
  scan_skills(home .. "/.claude/skills")
  -- 不掃 ~/.agents/skills：Claude Code 不讀那裡，沒在 ~/.claude/skills 建 symlink 的 skill 用不了
  scan_commands(cwd .. "/.claude/commands")
  scan_commands(home .. "/.claude/commands")

  -- plugin skills：同一個 plugin 有多個版本時取最新（排序後最後一個）
  local plugin_root = home .. "/.claude/plugins/cache"
  for _, market in ipairs(list_dir(plugin_root)) do
    for _, plugin in ipairs(list_dir(plugin_root .. "/" .. market.name)) do
      local versions = list_dir(plugin_root .. "/" .. market.name .. "/" .. plugin.name)
      local latest = versions[#versions]
      if latest then
        local base = table.concat({ plugin_root, market.name, plugin.name, latest.name }, "/")
        scan_skills(base .. "/skills", plugin.name .. ":")
      end
    end
  end

  return entries
end

local function get_entries()
  local now = uv.now()
  local cwd = vim.fn.getcwd()
  if cache.items and cache.cwd == cwd and now - cache.at < CACHE_TTL_MS then
    return cache.items
  end
  cache = { at = now, cwd = cwd, items = collect() }
  return cache.items
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.api.nvim_buf_get_name(0):find(PROMPT_PATTERN) ~= nil
end

function M:get_trigger_characters()
  return { "/" }
end

function M:get_completions(ctx, callback)
  local row, col = ctx.cursor[1], ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  -- `/` 必須在行首或空白後；後面只能是 skill 名稱字元
  local slash = before:match("()/[%w._:-]*$")
  if not slash or (slash > 1 and not before:sub(slash - 1, slash - 1):match("%s")) then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local kinds = require("blink.cmp.types").CompletionItemKind
  local items = {}
  for _, e in ipairs(get_entries()) do
    local doc = ("**/%s**  _(%s)_\n\n%s\n\n`%s`"):format(
      e.label, e.kind, e.description or "", vim.fn.fnamemodify(e.file, ":~"))
    table.insert(items, {
      label = "/" .. e.label,
      -- blink 的 keyword 不含 `/`，輸入 `/bra` 時比對的是 `bra`
      filterText = e.label,
      kind = e.kind == "skill" and kinds.Function or kinds.Event,
      labelDetails = { description = e.kind },
      documentation = { kind = "markdown", value = doc },
      textEdit = {
        newText = "/" .. e.label .. " ",
        range = {
          start = { line = row - 1, character = slash - 1 },
          ["end"] = { line = row - 1, character = col },
        },
      },
    })
  end
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

-- for tests / :lua
M._collect = collect

return M
