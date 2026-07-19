local base_path = require("blink.cmp.sources.path")
local path_lib = require("blink.cmp.sources.path.lib")

local M = {}

local function custom_dirname(opts, context)
  local original = path_lib.dirname(opts, context)
  if original ~= nil then
    return original
  end

  local line_before_cursor = context.line:sub(1, context.bounds.start_col - (context.bounds.length == 0 and 1 or 0))
  local name_regex = [[\%([^/\\:\*?<>'"`\|]\)]]
  local path_regex = vim.regex(([[\%([/"\']PAT\+\)*[/"\']\zePAT*$]]):gsub("PAT", name_regex))

  local s = path_regex:match_str(line_before_cursor)
  if s then
    local buf_dirname = opts.get_cwd(context)
    local dirname = string.gsub(string.sub(line_before_cursor, s + 2), "%a*$", "")
    local prefix = string.sub(line_before_cursor, 1, s + 1)
    if prefix:match('"$') or prefix:match("'$") then
      return vim.fn.resolve(buf_dirname .. "/" .. dirname)
    end
  end

  local orgmode_s = line_before_cursor:find("%[%[file:")
  if orgmode_s then
    local dirname = string.gsub(string.sub(line_before_cursor, orgmode_s + 7), "%a*$", "")
    local prefix = string.sub(line_before_cursor, 7, orgmode_s + 7)
    if prefix:match(":/$") then
      return vim.fn.resolve("/" .. dirname)
    end
  end

  return nil
end

function M.new(opts)
  local source = base_path.new(opts)

  function source:get_trigger_characters()
    return { "/", ".", "'", '"', ":", "\\" }
  end

  function source:get_completions(context, callback)
    callback = vim.schedule_wrap(callback)

    local dirname = custom_dirname(self.opts, context)
    if not dirname then
      return callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    end

    local include_hidden = self.opts.show_hidden_files_by_default
      or (string.sub(context.line, context.bounds.start_col, context.bounds.start_col) == "." and context.bounds.length == 0)
      or (
        string.sub(context.line, context.bounds.start_col - 1, context.bounds.start_col - 1) == "."
        and context.bounds.length > 0
      )

    path_lib
      .candidates(context, dirname, include_hidden, self.opts)
      :map(function(candidates)
        callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = candidates })
      end)
      :catch(function()
        callback()
      end)
  end

  return source
end

return M
