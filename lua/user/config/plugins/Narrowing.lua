local function get_manual_fold_range()
  local line = vim.fn.line(".")

  if vim.fn.foldlevel(line) == 0 then
    return nil
  end

  -- 若目前 fold 是開的
  vim.cmd("normal! zc")

  local start = vim.fn.foldclosed(line)
  local finish = vim.fn.foldclosedend(line)

  vim.cmd("normal! zo")

  if start == -1 then
    return nil
  end

  return start, finish
end

local function get_treesitter_fold_range(current_line)
  local current_level = vim.fn.foldlevel(current_line)
  if current_level <= 0 then
    return nil
  end

  local start_line = current_line
  local end_line = current_line
  local last_line = vim.api.nvim_buf_line_count(0)

  -- 找最近的同層 fold 起點
  for line = current_line, 1, -1 do
    local expr = tostring(vim.treesitter.foldexpr(line))
    local started_level = tonumber(expr:match("^>(%d+)$"))

    if started_level and started_level == current_level then
      start_line = line
      break
    end

    if vim.fn.foldlevel(line) < current_level then
      break
    end
  end

  -- 下一個同層 fold 起點之前，就是目前 fold 結束
  for line = start_line + 1, last_line do
    local level = vim.fn.foldlevel(line)
    local expr = tostring(vim.treesitter.foldexpr(line))
    local started_level = tonumber(expr:match("^>(%d+)$"))

    if level < current_level then
      end_line = line - 1
      break
    end

    if started_level and started_level == current_level then
      end_line = line - 1
      break
    end

    end_line = line
  end

  return start_line, end_line
end

local function narrowing_uses_manual_foldexpr()
  return vim.wo.foldmethod == "manual"
end

local function narrowing_uses_treesitter_foldexpr()
  if vim.wo.foldmethod ~= "expr" then
    return false
  end
  local foldexpr = vim.wo.foldexpr or ""
  return foldexpr:find("vim%.treesitter%.foldexpr%(") ~= nil
end

local function narrowing_find_open_fold_start(current_line, current_fold_level)
  for line = current_line, 1, -1 do
    local fold_level = vim.fn.foldlevel(line)
    local prev_fold_level = line > 1 and vim.fn.foldlevel(line - 1) or 0
    if fold_level == current_fold_level and prev_fold_level < current_fold_level then
      return line
    end
  end

  return current_line
end

local function narrowing_find_open_fold_end(current_line, current_fold_level)
  local total_lines = vim.fn.line("$")
  for line = current_line + 1, total_lines do
    if vim.fn.foldlevel(line) < current_fold_level then
      return line - 1
    end
  end

  return total_lines
end

local function narrowing_get_fold_range()
  local current_line = vim.fn.line(".")
  if narrowing_uses_manual_foldexpr() then
    local manual_fold_start, manual_fold_end = get_manual_fold_range()
    if manual_fold_start and manual_fold_end and manual_fold_start ~= manual_fold_end then
      return manual_fold_start, manual_fold_end
    end
  end
  if narrowing_uses_treesitter_foldexpr() then
    local ts_fold_start, ts_fold_end = get_treesitter_fold_range(current_line)
    if ts_fold_start and ts_fold_end and ts_fold_start ~= ts_fold_end then
      return ts_fold_start, ts_fold_end
    end
  end

  local fold_start = vim.fn.foldclosed(current_line)
  local fold_end = vim.fn.foldclosedend(current_line)
  if fold_start ~= -1 and fold_end ~= -1 then
    return fold_start, fold_end
  end

  local current_fold_level = vim.fn.foldlevel(current_line)
  if current_fold_level > 0 then
    fold_start = narrowing_find_open_fold_start(current_line, current_fold_level)
    fold_end = narrowing_find_open_fold_end(current_line, current_fold_level)
    return fold_start, fold_end
  end

  local current_indent = vim.fn.indent(current_line)
  local current_text = vim.fn.getline(current_line)
  if current_text:match("^%s*$") then
    return current_line, current_line
  end

  fold_start = current_line
  fold_end = current_line

  for line = current_line - 1, 1, -1 do
    local line_text = vim.fn.getline(line)
    if line_text:match("^%s*$") then
      goto continue_start
    end

    local line_indent = vim.fn.indent(line)
    if line_indent < current_indent then
      break
    end

    if line_indent == current_indent then
      fold_start = line
    end

    ::continue_start::
  end

  for line = current_line + 1, vim.fn.line("$") do
    local line_text = vim.fn.getline(line)
    if line_text:match("^%s*$") then
      goto continue_end
    end

    local line_indent = vim.fn.indent(line)
    if line_indent < current_indent then
      break
    end

    fold_end = line
    ::continue_end::
  end

  return fold_start, fold_end
end

local function delete_upstream_folds(line)
  while vim.fn.foldlevel(line) > 0 do
    local before = vim.fn.foldlevel(line)
    local ok = pcall(vim.cmd, "normal! zd")
    if not ok or vim.fn.foldlevel(line) >= before then
      break
    end
  end
end

local function delete_upstream_same_level_folds(fold_start_line)
  local target_level = vim.fn.foldlevel(fold_start_line)
  if target_level <= 0 then
    return
  end

  for line = fold_start_line - 1, 1, -1 do
    if vim.fn.foldlevel(line) > 0 then
      vim.fn.cursor(line, 1)
      delete_upstream_folds(line)
    end
  end

  vim.fn.cursor(fold_start_line, 1)
end

-- Custom function to implement the Narrow effect outside the selected area
local function narrow_except_selection(visual_mode, zoom_mode)
  local start_line, start_col, fold_start_line, end_line
  if visual_mode then
    _, start_line, _, _ = unpack(vim.fn.getpos("'<"))
    _, end_line, _, _ = unpack(vim.fn.getpos("'>"))
    fold_start_line = start_line
    start_col = 0
  else
    start_line, start_col = unpack(vim.api.nvim_win_get_cursor(0))
    fold_start_line, end_line = narrowing_get_fold_range()
    if fold_start_line == end_line then
      print("Not Found Fold")
      return
    end
  end
  if zoom_mode then
    vim.cmd('fclose')
    vim.cmd('NeoZoomToggle')
  else
    vim.cmd('split')
  end
  require("ufo").detach()
  vim.cmd('setlocal foldtext=')
  pcall(function() vim.cmd('normal! zR') end)
  vim.fn.cursor(fold_start_line, 0)

  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"

  -- 折疊上方：1 ～ fold_start_line - 1
  if fold_start_line > 1 then
    delete_upstream_same_level_folds(fold_start_line)
    vim.fn.cursor(fold_start_line - 1, 1)
    pcall(function()
      vim.cmd("normal! Vggzf")
    end)
  end

  -- 折疊下方：end_line + 1 ～ 最後一行
  local last_line = vim.api.nvim_buf_line_count(0)
  if end_line < last_line then
    vim.fn.cursor(end_line + 1, 1)
    delete_upstream_folds(end_line + 1)
    pcall(function() vim.cmd("normal! " .. "VGzf") end)
  end

  vim.fn.cursor(start_line, start_col)

  local win_id = vim.api.nvim_get_current_win()
  vim.b.narrow_mode = true

  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      if tonumber(args.match) == win_id then
        require("ufo").attach()
        vim.b.narrow_mode = false
      end
    end,
    desc = "Automatically re-attach UFO when this specific window closes",
    pattern = tostring(win_id),
    once = true,
  })
end

-- Bind the function to the shortcut key <leader>On in visual mode
-- Nvim.keys.visual_mode['<leader>On'] = ':<C-u>lua narrow_except_selection(true)<CR>'
Nvim.keys.visual_mode['<leader>On'] = { function() narrow_except_selection(true, false) end }
Nvim.keys.normal_mode['<leader>On'] = { function() narrow_except_selection(false, false) end,
  { desc = 'Zoom-in Folding to split' } }
Nvim.keys.normal_mode['<leader>ON'] = { function() narrow_except_selection(false, true) end,
  { desc = 'Neo-Zoom-in Folding to split' } }
