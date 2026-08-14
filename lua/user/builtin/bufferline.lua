Nvim.builtin = Nvim.builtin or {}
Nvim.builtin.bufferline = Nvim.builtin.bufferline or {}
Nvim.builtin.bufferline.options = Nvim.builtin.bufferline.options or {}

local function custom_filter(buf, buf_nums)
  local function is_ft(b, ft)
    return vim.bo[b].filetype == ft
  end

  local logs = vim.tbl_filter(function(b)
    return is_ft(b, "log")
  end, buf_nums or {})

  if vim.tbl_isempty(logs) then
    return true
  end

  local tab_num = vim.fn.tabpagenr()
  local last_tab = vim.fn.tabpagenr("$")
  local is_log = is_ft(buf, "log")

  if last_tab == 1 then
    return true
  end

  return (tab_num == last_tab and is_log) or (tab_num ~= last_tab and not is_log)
end

local function diagnostics_indicator(num, _, diagnostics, _)
  local result = {}
  local symbols = {
    error = "",
    warning = "",
    info = "",
  }

  for name, count in pairs(diagnostics) do
    if symbols[name] and count > 0 then
      table.insert(result, symbols[name] .. " " .. count)
    end
  end

  result = table.concat(result, " ")
  return #result > 0 and result or ""
end

local function jumplist_state()
  local jumps, idx = unpack(vim.fn.getjumplist())

  return {
    back = #jumps > 0 and idx > 0,
    forward = #jumps > 0 and idx < #jumps - 1,
  }
end

local function jumplist_state_changed(a, b)
  if not a or not b then
    return true
  end

  return a.back ~= b.back
      or a.forward ~= b.forward
end

-----------------------------------------------------------------------
-- Bufferline cache invalidate hook
--
-- 在真正的 bufferline config 載入完成後，
-- install_bufferline_render_cache() 會覆寫這個 function。
-----------------------------------------------------------------------

_G.BufferlineCacheInvalidate = function()
end

-- IDE-style jumplist Back / Forward
local function jump_and_refresh(keys)
  local before = jumplist_state()

  local termcodes =
      vim.api.nvim_replace_termcodes(
        keys,
        true,
        false,
        true
      )

  vim.api.nvim_feedkeys(termcodes, "n", false)

  -- feedkeys 不保證在這個 Lua function return 前完成，
  -- 所以排到下一輪 event loop 再檢查 jumplist。
  vim.schedule(function()
    local after = jumplist_state()

    if jumplist_state_changed(before, after) then
      _G.BufferlineCacheInvalidate()
    end
  end)
end

_G.BufferlineJumpBack = function(...)
  jump_and_refresh("<C-o>")
end

_G.BufferlineJumpForward = function(...)
  jump_and_refresh("<C-i>")
end

vim.api.nvim_set_hl(0, "BufferLineJumpDisabled", {
  link = "Comment",
})

Nvim.builtin.bufferline.highlights = vim.tbl_deep_extend("force", Nvim.builtin.bufferline.highlights or {}, {
  background = {
    italic = true,
  },
  buffer_selected = {
    bold = true,
  },
})

Nvim.builtin.bufferline.options = vim.tbl_deep_extend("force", {
  themable = true,
  get_element_icon = nil,
  show_duplicate_prefix = true,
  duplicates_across_groups = true,
  auto_toggle_bufferline = true,
  move_wraps_at_ends = false,
  groups = {
    items = {},
    options = { toggle_hidden_on_enter = true },
  },
  custom_areas = {
    left = function()
      local state = jumplist_state()

      return {
        {
          text = "%@v:lua.BufferlineJumpBack@"
              .. "  "
              .. "%X",
          link = state.back
              and "Normal"
              or "BufferLineJumpDisabled",
        },
        {
          text =
              "%@v:lua.BufferlineJumpForward@"
              .. "  "
              .. "%X",
          link = state.forward
              and "Normal"
              or "BufferLineJumpDisabled",
        },
        {
          text = " ",
          link = "BufferLineFill",
        },
      }
    end,
  },
  mode = "buffers",
  numbers = "none",
  -- close_command = "bdelete! %d",
  close_command = "ForceBufferLineKill %d",
  right_mouse_command = "vert sbuffer %d",
  left_mouse_command = "buffer %d",
  middle_mouse_command = nil,
  indicator = {
    icon = "▎",
    style = "icon",
  },
  buffer_close_icon = "󰅖",
  modified_icon = "",
  close_icon = "",
  left_trunc_marker = "",
  right_trunc_marker = "",
  name_formatter = function(buf)
    if buf.name:match("%.md") then
      return vim.fn.fnamemodify(buf.name, ":t:r")
    end
  end,
  max_name_length = 18,
  max_prefix_length = 15,
  truncate_names = true,
  tab_size = 18,
  diagnostics = "nvim_lsp",
  diagnostics_update_in_insert = false,
  diagnostics_indicator = diagnostics_indicator,
  custom_filter = custom_filter,
  offsets = {
    {
      filetype = "undotree",
      text = "Undotree",
      highlight = "PanelHeading",
      padding = 1,
    },
    {
      filetype = "NvimTree",
      text = "Explorer",
      highlight = "PanelHeading",
      padding = 1,
    },
    {
      filetype = "DiffviewFiles",
      text = "Diff View",
      highlight = "PanelHeading",
      padding = 1,
    },
    {
      filetype = "flutterToolsOutline",
      text = "Flutter Outline",
      highlight = "PanelHeading",
    },
    {
      filetype = "lazy",
      text = "Lazy",
      highlight = "PanelHeading",
      padding = 1,
    },
  },
  color_icons = true,
  show_buffer_icons = true,
  show_buffer_close_icons = true,
  show_close_icon = false,
  show_tab_indicators = false,
  persist_buffer_sort = true,
  separator_style = "thin",
  enforce_regular_tabs = false,
  always_show_bufferline = true,
  hover = {
    enabled = false,
    delay = 200,
    reveal = { "close" },
  },
  sort_by = "id",
  debug = { logging = false },
}, Nvim.builtin.bufferline.options or {})

local dap_filetypes = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches" }

for _, filetype in ipairs(dap_filetypes) do
  table.insert(Nvim.builtin.bufferline.options.offsets, {
    filetype = filetype,
    text = "DAP",
    highlight = "PanelHeading",
    padding = 1
  })
end
