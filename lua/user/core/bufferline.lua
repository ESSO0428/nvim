local M = {}

-- Common kill function for bdelete and bwipeout
-- Adapted from LunarVim's lvim.core.bufferline.buf_kill with local-only deps.
---@param kill_command? string defaults to "bd"
---@param bufnr? number defaults to current buffer
---@param force? boolean defaults to false
function M.buf_kill(kill_command, bufnr, force)
  kill_command = kill_command or "bd"

  local bo = vim.bo
  local api = vim.api
  local fmt = string.format
  local fn = vim.fn

  if bufnr == 0 or bufnr == nil then
    bufnr = api.nvim_get_current_buf()
  end

  local bufname = api.nvim_buf_get_name(bufnr)

  if not force then
    local choice
    if bo[bufnr].modified then
      choice = fn.confirm(fmt([[Save changes to "%s"?]], bufname), "&Yes\n&No\n&Cancel")
      if choice == 1 then
        api.nvim_buf_call(bufnr, function()
          vim.cmd("w")
        end)
      elseif choice == 2 then
        force = true
      else
        return
      end
    elseif api.nvim_get_option_value("buftype", { buf = bufnr }) == "terminal" then
      choice = fn.confirm(fmt([[Close "%s"?]], bufname), "&Yes\n&No\n&Cancel")
      if choice == 1 then
        force = true
      else
        return
      end
    end
  end

  local windows = vim.tbl_filter(function(win)
    return api.nvim_win_get_buf(win) == bufnr
  end, api.nvim_list_wins())

  if force then
    kill_command = kill_command .. "!"
  end

  local buffers = vim.tbl_filter(function(buf)
    return api.nvim_buf_is_valid(buf) and bo[buf].buflisted
  end, api.nvim_list_bufs())

  if #buffers > 1 and #windows > 0 then
    for i, buf in ipairs(buffers) do
      if buf == bufnr then
        local prev_buf_idx = i == 1 and #buffers or (i - 1)
        local prev_buffer = buffers[prev_buf_idx]
        for _, win in ipairs(windows) do
          api.nvim_win_set_buf(win, prev_buffer)
        end
        break
      end
    end
  end

  if api.nvim_buf_is_valid(bufnr) and bo[bufnr].buflisted then
    vim.cmd(string.format("%s %d", kill_command, bufnr))
  end
end

return M
