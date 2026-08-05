local base_path = require("blink.cmp.sources.path")
local path_lib = require("blink.cmp.sources.path.lib")

local M = {}

-- 保留 blink.cmp 原本的路徑片段起點計算。
local original_get_last_path_part = path_lib.get_last_path_part

-- 找到字串中最後一個未被跳脫的單引號或雙引號。
local function get_last_unescaped_quote(path)
  for i = #path, 1, -1 do
    local char = path:sub(i, i)

    if char == '"' or char == "'" then
      local backslash_count = 0
      local j = i - 1

      while j >= 1 and path:sub(j, j) == "\\" do
        backslash_count = backslash_count + 1
        j = j - 1
      end

      if backslash_count % 2 == 0 then
        return i
      end
    end
  end

  return nil
end

-- HACK: [2026-08-06 01:04] 補丁：
-- 原生 blink.cmp 只會從最後一個 / 或 \ 後方開始替換。
-- 在 Path("|") 這種空字串中，左側沒有路徑分隔符，
-- 因此原生結果會從整行第 0 欄開始替換。
--
-- 這裡將最近的未跳脫引號後方，也視為合法的路徑起點。
path_lib.get_last_path_part = function(path)
  local original_start = original_get_last_path_part(path)
  local quote_pos = get_last_unescaped_quote(path)

  if quote_pos == nil then
    return original_start
  end

  -- get_last_path_part() 回傳 Lua 1-based index。
  -- 引號後方的位置是 quote_pos + 1。
  return math.max(original_start, quote_pos + 1)
end

local function custom_dirname(opts, context)
  local original = path_lib.dirname(opts, context)
  if original ~= nil then
    return original
  end

  local line_before_cursor = context.line:sub(
    1,
    context.bounds.start_col
    - (context.bounds.length == 0 and 1 or 0)
  )

  local name_regex = [[\%([^/\\:\*?<>'"`\|]\)]]
  local path_regex = vim.regex(
    ([[\%([/"\']PAT\+\)*[/"\']\zePAT*$]]):gsub(
      "PAT",
      name_regex
    )
  )

  local s = path_regex:match_str(line_before_cursor)

  if s then
    local buf_dirname = opts.get_cwd(context)
    local dirname = string.gsub(
      string.sub(line_before_cursor, s + 2),
      "%a*$",
      ""
    )
    local prefix = string.sub(
      line_before_cursor,
      1,
      s + 1
    )

    if prefix:match('"$') or prefix:match("'$") then
      return vim.fn.resolve(
        buf_dirname .. "/" .. dirname
      )
    end
  end

  local orgmode_s = line_before_cursor:find("%[%[file:")

  if orgmode_s then
    local dirname = string.gsub(
      string.sub(line_before_cursor, orgmode_s + 7),
      "%a*$",
      ""
    )
    local prefix = string.sub(
      line_before_cursor,
      7,
      orgmode_s + 7
    )

    if prefix:match(":/$") then
      return vim.fn.resolve("/" .. dirname)
    end
  end

  return nil
end

function M.new(opts)
  local source = base_path.new(opts)

  function source:get_trigger_characters()
    return {
      "/",
      ".",
      "'",
      '"',
      ":",
      "\\",
    }
  end

  function source:get_completions(context, callback)
    callback = vim.schedule_wrap(callback)

    local dirname = custom_dirname(self.opts, context)

    if not dirname then
      return callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = {},
      })
    end

    local include_hidden =
    self.opts.show_hidden_files_by_default
        or (
        string.sub(
          context.line,
          context.bounds.start_col,
          context.bounds.start_col
        ) == "."
            and context.bounds.length == 0
        )
        or (
        string.sub(
          context.line,
          context.bounds.start_col - 1,
          context.bounds.start_col - 1
        ) == "."
            and context.bounds.length > 0
        )

    path_lib
        .candidates(
          context,
          dirname,
          include_hidden,
          self.opts
        )
        :map(function(candidates)
          callback({
            is_incomplete_forward = false,
            is_incomplete_backward = false,
            items = candidates,
          })
        end)
        :catch(function()
          callback({
            is_incomplete_forward = false,
            is_incomplete_backward = false,
            items = {},
          })
        end)
  end

  return source
end

return M
