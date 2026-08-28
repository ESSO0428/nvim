local M = {}

local function cmd_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function is_table_like_file(fileName)
  local ext = vim.fn.fnamemodify(fileName, ":e"):lower()

  return vim.tbl_contains({
    "csv",
    "tsv",
    "xlsx",
    "xls",
    "json",
    "jsonl",
    "parquet",
    "sqlite",
    "db",
  }, ext)
end

local function build_bigfile_viewers(fileName)
  local escaped = vim.fn.shellescape(fileName)
  local viewers = {}

  local function add_bat()
    if cmd_exists("bat") then
      table.insert(viewers, {
        name = "bat",
        desc = "View with bat",
        cmd = "bat --paging=always --style=full --wrap=never " .. escaped,
      })
      return true
    end

    return false
  end

  local function add_visidata()
    if cmd_exists("vd") then
      table.insert(viewers, {
        name = "visidata",
        desc = "Open with VisiData",
        cmd = "vd " .. escaped,
      })
      return true
    elseif cmd_exists("visidata") then
      table.insert(viewers, {
        name = "visidata",
        desc = "Open with VisiData",
        cmd = "visidata " .. escaped,
      })
      return true
    end

    return false
  end

  local function add_fallback_pager()
    if cmd_exists("less") then
      table.insert(viewers, {
        name = "less",
        desc = "View with less",
        cmd = "less -S " .. escaped,
      })
      return true
    elseif cmd_exists("more") then
      table.insert(viewers, {
        name = "more",
        desc = "View with more",
        cmd = "more " .. escaped,
      })
      return true
    end

    return false
  end

  if is_table_like_file(fileName) then
    add_visidata()
    add_bat()
    add_fallback_pager()
  else
    add_bat()
    add_visidata()
    add_fallback_pager()
  end

  return viewers
end

function M.open_bigfile_viewer(fileName)
  local viewers = build_bigfile_viewers(fileName)

  if #viewers == 0 then
    vim.notify(
      "No available viewer found: bat, vd/visidata, less, or more",
      vim.log.levels.WARN
    )
    return
  end

  vim.ui.select(viewers, {
    prompt = "Open large file with:",
    format_item = function(item)
      return item.desc
    end,
  }, function(choice)
    if not choice then
      return
    end

    local Terminal = require("toggleterm.terminal").Terminal
    local viewer = Terminal:new {
      cmd = choice.cmd,
      hidden = true,
      direction = "float",
      close_on_exit = true,
      on_open = function(term)
        vim.cmd "startinsert!"
        vim.keymap.set({ "t", "n" }, "<C-\\>", "<cmd>bd!<cr>", {
          buffer = term.bufnr,
          noremap = true,
          silent = true,
        })
      end,
    }

    viewer:open()
  end)
end

return M
