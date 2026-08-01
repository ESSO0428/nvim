-- NOTE: 這裡刻意不再追求「高階語意分組」或嚴格避免 matcher 重疊。
-- 原則是：前面保留少數我明確想保留的 group；後面直接用
-- nvim-web-devicons 提供的 filetype 表暴力補上 ft -> group。
-- 因此 bufferline 最終看到什麼 filetype，就可能呈現成什麼 group。
-- 這份設定重點是降低後續維護成本，而不是建立一套完美分類法。
-- 另外 auto-generated ft groups 不再額外塞 icon，避免和 bufferline 本身的
-- show_buffer_icons 重複，出現同一個圖示被畫兩次。
local ok_filetypes, devicon_filetypes = pcall(require, "nvim-web-devicons.filetypes")
if not ok_filetypes then
  devicon_filetypes = require("user.core.filetypes")
end

local core_matchers = {
  readme = function(buf)
    local name = buf.id and vim.fn.bufname(buf.id) or ""
    name = name:lower()
    return name:match("readme") ~= nil
  end,
}
local util_matchers = {
  readme = function(buf)
    return core_matchers.readme(buf)
  end,
  docs = function(buf)
    if core_matchers.readme(buf) then
      return false
    end
    return (buf.id and vim.fn.bufname(buf.id):match("%.md"))
        or (buf.id and vim.fn.bufname(buf.id):match("%.txt"))
  end,
}
local ft_catch = function(buf)
  local ft = vim.bo[buf.id].filetype
  if ft == "" then
    ft = vim.filetype.match({
      filename = vim.api.nvim_buf_get_name(buf.id),
    })
  end
  return ft
end

local special_items = {
  {
    name = "Dotfiles",
    matcher = function(buf)
      return buf.name and buf.name:sub(1, 1) == "."
    end,
  },
  {
    name = "OrgMode",
    auto_close = false,
    matcher = function(buf)
      return buf.id and ft_catch(buf) == "org"
    end,
  },
  {
    name = "README",
    auto_close = false,
    matcher = util_matchers.readme,
  },
  {
    name = "Docs",
    auto_close = false,
    matcher = util_matchers.docs,
  },
  {
    name = "Shell",
    auto_close = false,
    matcher = function(buf)
      return buf.id and vim.fn.bufname(buf.id):match("%.sh")
    end,
  },
  {
    name = "Tests",
    priority = 2,
    icon = "",
    matcher = function(buf)
      local name = buf.id and vim.fn.bufname(buf.id) or ""
      return name:match("_test") ~= nil or name:match("_spec") ~= nil
    end,
  },
  {
    name = "Table",
    auto_close = false,
    matcher = function(buf)
      return (buf.id and vim.fn.bufname(buf.id):match("%.csv"))
          or (buf.id and vim.fn.bufname(buf.id):match("%.tsv"))
    end,
  },
  {
    name = "Lua/Vim",
    auto_close = false,
    matcher = function(buf)
      if not buf.id then
        return false
      end
      local ft = ft_catch(buf)
      return ft == "lua" or ft == "vim"
    end,
  },
}

local excluded_fts = {
  org = true,
  lua = true,
  vim = true,
}
local exclude_matchers = {
  dotfiles = function(buf)
    return buf.name and buf.name:sub(1, 1) == "."
  end,
  readme = util_matchers.readme,
  docs = util_matchers.docs,
  tests = function(buf)
    local name = buf.id and vim.fn.bufname(buf.id) or ""
    return name:match("_test") ~= nil or name:match("_spec") ~= nil
  end,
  shell = function(buf)
    return buf.id and vim.fn.bufname(buf.id):match("%.sh")
  end,
  Table = function(buf)
    return (buf.id and vim.fn.bufname(buf.id):match("%.csv"))
        or (buf.id and vim.fn.bufname(buf.id):match("%.tsv"))
  end,
}

local auto_ft_names = {}
for ft in pairs(devicon_filetypes) do
  if not excluded_fts[ft] then
    table.insert(auto_ft_names, ft)
  end
end

table.sort(auto_ft_names)

local auto_ft_items = {}
for _, ft in ipairs(auto_ft_names) do
  table.insert(auto_ft_items, {
    name = ft,
    auto_close = false,
    matcher = function(buf)
      for _, exclude in pairs(exclude_matchers) do
        if exclude(buf) then
          return false
        end
      end
      return buf.id and ft_catch(buf) == ft
    end,
  })
end

Nvim.builtin.bufferline.options.groups = {
  options = {
    toggle_hidden_on_enter = true,
  },
  items = vim.list_extend(special_items, auto_ft_items),
}
