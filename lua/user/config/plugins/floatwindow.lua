local M = {}

local ns_previewer = vim.api.nvim_create_namespace("telescope.previewers")

local function jump_to_line(self, bufnr, lnum)
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_previewer, 0, -1)
  if lnum and lnum > 0 then
    pcall(vim.api.nvim_buf_add_highlight, bufnr, ns_previewer, "TelescopePreviewLine", lnum - 1, 0, -1)
    pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, 0 })
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("norm! zz")
    end)
  end
end

local function open_float_window()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    filepath = "[No Name]"
  end

  local width = 120
  local height = 15

  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  local row = math.max(0, cursor_row - 1)
  local col = math.max(0, cursor_col - 1)

  local float_win = vim.api.nvim_open_win(0, true, {
    relative = "cursor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "single",
    title = "<- " .. filepath,
  })

  vim.api.nvim_set_option_value("cursorline", true, { win = float_win })
  vim.api.nvim_set_option_value("winblend", 0, { win = float_win })
end

local function float_into_current_window()
  local float_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  local cfg = vim.api.nvim_win_get_config(float_win)
  if cfg.relative == "" then
    return -- 不是 float
  end

  -- 找一個普通 window（通常是上一個）
  vim.cmd("wincmd p")

  -- 把 float 的 buffer 放進現在這個 window
  vim.api.nvim_win_set_buf(0, buf)

  -- 關掉 float
  vim.api.nvim_win_close(float_win, true)
end

-- 將此函數添加到 Neovim 命令
vim.api.nvim_create_user_command('OpenFloat', open_float_window, {})
vim.api.nvim_create_user_command('FloatIntoCurrent', float_into_current_window, {})
Nvim.keys.normal_mode['sw'] = "<cmd>OpenFloat<CR>"
Nvim.keys.normal_mode['sq'] = "<Cmd>FloatIntoCurrent<CR>"

local function close_selected_window(window_infos, prompt_bufnr, action_state, actions, finders)
  local ok = pcall(function()
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if selection and selection.value and vim.api.nvim_win_is_valid(selection.value.win) then
      vim.api.nvim_win_close(selection.value.win, false)

      for i, win_info in ipairs(window_infos) do
        if win_info.win == selection.value.win then
          table.remove(window_infos, i)
          break
        end
      end

      current_picker:refresh(
        finders.new_table({
          results = window_infos,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.name,
              ordinal = entry.name,
              bufnr = entry.bufnr,
            }
          end,
        }),
        { reset_prompt = true }
      )
    end
  end)

  if not ok then
    vim.notify("Cannot close the last window", vim.log.levels.WARN)
  end
end

-- HACK: Avoid edgy.nvim layout conflict
-- local edgy_config = require("user.edgy").config
-- M.restricted_fts = {}
M.restricted_fts_set = {}

local function list_and_select_windows_in_tab()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("telescope.nvim is not available", vim.log.levels.WARN)
    return
  end

  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local window_infos = {}
  local windows = vim.api.nvim_tabpage_list_wins(0)

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.fn.expand("#" .. buf .. ":t")
    local filepath = vim.fn.expand("#" .. buf .. ":p")
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    local src_filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })

    if name == "" then
      name = "[No Name]"
    end
    if filepath ~= "" then
      name = name .. " (" .. filepath .. ")"
    end

    local is_float = vim.api.nvim_win_get_config(win).relative ~= ""
    local prefix = is_float and "[Float]" or "[Normal]"

    if not M.restricted_fts_set[src_filetype] then
      local display_text = string.format("%-6s %-8s %s", tostring(win), prefix, name)
      table.insert(window_infos, { win = win, name = display_text, bufnr = buf, lnum = lnum })
    end
  end

  table.sort(window_infos, function(a, b)
    return a.name < b.name
  end)

  pickers
      .new({}, {
        prompt_title = "Windows",
        finder = finders.new_table({
          results = window_infos,
          entry_maker = function(entry)
            if not entry or not entry.bufnr then
              return nil
            end
            return {
              value = entry,
              display = entry.name,
              ordinal = entry.name,
              bufnr = entry.bufnr,
              lnum = entry.lnum,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
          define_preview = function(self, entry, _)
            if not entry or not entry.bufnr or not vim.api.nvim_buf_is_loaded(entry.bufnr) then
              return
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})
            local content = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)

            local filetype = vim.api.nvim_get_option_value("filetype", { buf = entry.bufnr })
            pcall(function()
              vim.api.nvim_set_option_value("filetype", filetype, { buf = self.state.bufnr })
            end)

            pcall(function()
              vim.api.nvim_command("setlocal foldmethod=expr")
              vim.api.nvim_command("setlocal foldexpr=nvim_treesitter#foldexpr()")
              vim.schedule(function()
                jump_to_line(self, self.state.bufnr, entry.lnum)
              end)
            end)
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection and selection.value and vim.api.nvim_win_is_valid(selection.value.win) then
              vim.api.nvim_set_current_win(selection.value.win)
            end
          end)

          map("i", "<c-d>", function()
            close_selected_window(window_infos, prompt_bufnr, action_state, actions, finders)
          end)
          map("n", "dd", function()
            close_selected_window(window_infos, prompt_bufnr, action_state, actions, finders)
          end)
          map("n", "<c-w>", function()
            local ok_delete = pcall(function()
              actions.delete_buffer(prompt_bufnr)
            end)
            if not ok_delete then
              vim.notify("Cannot close the buffer", vim.log.levels.WARN)
            end
          end)
          return true
        end,
      })
      :find()
end

vim.api.nvim_create_user_command("ListTabWindows", list_and_select_windows_in_tab, {})

return M
