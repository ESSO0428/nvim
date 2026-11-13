-- Snacks
-- Scratch File
-- raw toggle that supports count slots
vim.keymap.set("n", "<Plug>(snacks-scratch-raw)", function()
  Snacks.scratch()
end, { desc = "Snacks scratch raw toggle" })
-- Scratch manager (Oil-like)
-- Every line carries a hidden id prefix "/<nonce>:<n> " that maps it to a scratch.
-- The id lives in the text, so dd/p, undo and reordering keep the mapping intact.
-- Lines without a valid id are new scratches; ids missing from the buffer are deletions.
local function open_scratch_manager()
  local uv = vim.uv or vim.loop
  local ns = vim.api.nvim_create_namespace("scratch_manager_id")
  local scratch_cfg = Snacks.config.get("scratch", { root = Nvim.paths.scratch_dir, filekey = {} })
  local root_dir = vim.fs.normalize(scratch_cfg.root or Nvim.paths.scratch_dir)
  local filekey = scratch_cfg.filekey or {}

  -- per-open nonce: ids copied from an older panel are never mistaken for ours
  local nonce = ""
  local ok_rand, bytes = pcall(uv.random, 4)
  if not ok_rand or type(bytes) ~= "string" then
    bytes = tostring(uv.hrtime()):sub(-4)
  end
  for i = 1, 4 do
    nonce = nonce .. string.char(97 + bytes:byte(i) % 26)
  end

  ---@type table<string, { scratch: table, meta: string? }>
  local entries = {}
  local next_id = 0

  -- identity signature of a scratch's .meta (field based, JSON key order doesn't matter)
  local function read_meta_text(file)
    local ok, lines = pcall(vim.fn.readfile, file .. ".meta")
    if not ok then return nil end
    local ok_json, m = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok_json or type(m) ~= "table" then return nil end
    return table.concat({ tostring(m.id), tostring(m.name), tostring(m.ft), tostring(m.count),
      tostring(m.cwd), tostring(m.branch) }, "\0")
  end

  local function register(scratch, id)
    if not id then
      next_id = next_id + 1
      id = tostring(next_id)
    end
    scratch.stat = nil
    entries[id] = { scratch = scratch, meta = read_meta_text(scratch.file) }
    return id
  end

  local function format_scratch_line(sc)
    local line = string.format("[%s] %s", sc.ft or "txt", sc.name or "Scratch")
    if sc.count and sc.count > 1 then line = line .. "  × " .. sc.count end
    if sc.cwd then line = line .. "  @ " .. vim.fn.fnamemodify(sc.cwd, ":~") end
    if sc.branch then line = line .. "  # " .. sc.branch end
    return line
  end

  local function render_line(id, sc)
    return ("/%s:%s "):format(nonce, id) .. format_scratch_line(sc)
  end

  --- Split a buffer line into (valid id or nil, prefix byte length, rest)
  local function split_id(line)
    local n, id, rest = line:match("^/(%l+):(%d+) ?(.*)$")
    if not n then
      return nil, 0, line
    end
    local plen = #line - #rest
    if n == nonce and entries[id] then
      return id, plen, rest
    end
    -- stale / foreign id: strip it, the line counts as new
    return nil, plen, rest
  end

  -- Parse "[ft] name  × n  @ cwd  # branch" -> name, ft
  local function parse_line(line)
    line = vim.trim(line)
    local end_pos = #line
    for _, sep in ipairs({ "  × ", "  @ ", "  # " }) do
      local p = line:find(sep, 1, true)
      if p then end_pos = math.min(end_pos, p - 1) end
    end
    local name_part = vim.trim(line:sub(1, end_pos))
    local ft = "markdown"
    local ft_match = name_part:match("^%[(%w+)%]")
    if ft_match then
      ft = ft_match
      name_part = name_part:gsub("^%[%w+%]%s*", "")
    end
    return vim.trim(name_part), ft
  end

  local scratches = Snacks.scratch.list()
  local buf_lines = {}
  for _, sc in ipairs(scratches) do
    table.insert(buf_lines, render_line(register(sc), sc))
  end
  if #buf_lines == 0 then
    table.insert(buf_lines, "[markdown] new_scratch")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  pcall(vim.api.nvim_buf_set_name, buf, "Scratch_Manager")
  -- initial content is not undoable (undo can't empty the list and delete everything on :w)
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
  vim.bo[buf].undolevels = vim.go.undolevels
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modified = false

  local width = 80
  local height = math.min(20, math.max(10, #buf_lines + 2))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " Manage Scratches (<CR>: open, gh: preview toggle, edit freely, undo/redo, :w: apply) ",
    title_pos = "center",
  })
  vim.wo[win].conceallevel = 3
  vim.wo[win].concealcursor = "nvic"

  -- conceal ids (recomputed from text, so it follows yank/put/undo)
  local function refresh_conceal()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      local _, plen = split_id(line)
      if plen > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = plen, conceal = "" })
      end
    end
  end
  refresh_conceal()

  local function prefix_len(row)
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local _, plen = split_id(line)
    return plen, line
  end

  -- keep the cursor out of the hidden id
  local function clamp_cursor()
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win then return end
    local row, col = unpack(vim.api.nvim_win_get_cursor(win))
    local plen, line = prefix_len(row)
    local insert = vim.fn.mode():find("^i") ~= nil
    if plen > 0 and col < plen and (insert or plen < #line) then
      vim.api.nvim_win_set_cursor(win, { row, plen })
    end
  end

  -- ------------------------------------------------------------------
  -- Preview
  -- ------------------------------------------------------------------
  local preview_enabled = false
  local preview_win = nil
  local preview_file = nil

  local function close_preview()
    preview_file = nil
    if preview_win then
      pcall(preview_win.hide, preview_win)
      preview_win = nil
    end
  end

  local function scratch_at_cursor()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local id = split_id(line)
    return id and entries[id].scratch or nil, id
  end

  local function preview_win_opts()
    local cfg = vim.api.nvim_win_get_config(win)
    local manager_width = cfg.width or width
    local manager_height = cfg.height or height
    local manager_col = math.floor(tonumber(cfg.col) or ((vim.o.columns - manager_width) / 2))
    local manager_row = math.floor(tonumber(cfg.row) or ((vim.o.lines - manager_height) / 2))
    local gap = 2
    local preview_col = manager_col + manager_width + gap
    local max_preview_width = math.min(100, math.max(20, vim.o.columns - 4))
    local right_space = vim.o.columns - preview_col - 2
    local preview_width = math.min(max_preview_width, math.max(20, right_space))
    preview_col = math.max(0, math.min(preview_col, vim.o.columns - preview_width - 2))

    local max_preview_height = math.max(8, vim.o.lines - 4)
    local desired_preview_height = math.max(manager_height + 6, math.floor(vim.o.lines * 0.7))
    local preview_height = math.min(desired_preview_height, max_preview_height)
    local preview_row = math.max(0, math.min(manager_row, vim.o.lines - preview_height - 2))

    return {
      style = "scratch",
      buf = nil,
      position = "float",
      enter = false,
      focusable = true,
      footer_keys = false,
      width = preview_width,
      height = preview_height,
      row = preview_row,
      col = preview_col,
    }
  end

  local function ensure_preview_buffer(scratch)
    local preview_buf = vim.fn.bufadd(scratch.file)
    if not vim.api.nvim_buf_is_loaded(preview_buf) then
      vim.fn.bufload(preview_buf)
    end

    vim.bo[preview_buf].buftype = ""
    vim.bo[preview_buf].bufhidden = "hide"
    vim.bo[preview_buf].buflisted = false
    vim.bo[preview_buf].swapfile = false
    vim.bo[preview_buf].modifiable = true
    vim.bo[preview_buf].readonly = false
    if scratch.ft and scratch.ft ~= "" then
      vim.bo[preview_buf].filetype = scratch.ft
    end

    if not vim.b[preview_buf].snacks_scratch_preview_autowrite then
      vim.b[preview_buf].snacks_scratch_preview_autowrite = true
      vim.api.nvim_create_autocmd("BufHidden", {
        group = vim.api.nvim_create_augroup("snacks_scratch_preview_autowrite_" .. preview_buf, { clear = true }),
        buffer = preview_buf,
        callback = function(ev)
          vim.api.nvim_buf_call(ev.buf, function()
            vim.cmd("silent! write")
            vim.bo[ev.buf].buflisted = false
          end)
        end,
      })
    end

    return preview_buf
  end

  local function update_preview()
    if not preview_enabled then return end

    local scratch = scratch_at_cursor()
    if not scratch then
      close_preview()
      return
    end

    if preview_file == scratch.file and preview_win and preview_win:valid() then
      return
    end

    close_preview()
    preview_file = scratch.file
    local opts = preview_win_opts()
    opts.buf = ensure_preview_buffer(scratch)
    opts.title = string.format(" Scratch Preview: %s [%s] ", scratch.name or "Scratch", scratch.ft or "txt")
    preview_win = Snacks.win(opts):show()
  end

  local function scroll_preview(preview_keys, fallback_keys)
    local target_win = preview_win and preview_win:valid() and preview_win.win or nil
    local keys = preview_keys

    if not (target_win and vim.api.nvim_win_is_valid(target_win)) then
      target_win = win
      keys = fallback_keys or preview_keys
    end

    local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_win_call(target_win, function()
      vim.cmd.normal({ bang = true, args = { termcodes } })
    end)
  end

  -- ------------------------------------------------------------------
  -- File operations
  -- ------------------------------------------------------------------
  -- same key scheme as Snacks.scratch (_write_meta)
  local function scratch_file_for(sc)
    local key = { sc.id or sc.name }
    key[#key + 1] = sc.count and tostring(sc.count) or nil
    key[#key + 1] = sc.cwd and sc.cwd or nil
    key[#key + 1] = sc.branch and sc.branch or nil
    local hash = vim.fn.sha256(table.concat(key, "|")):sub(1, 8)
    return vim.fs.normalize(("%s/%s.%s"):format(root_dir, hash, sc.ft))
  end

  local function with_icon(sc)
    local ok, icon, hl = pcall(Snacks.util.icon, sc.ft, "filetype")
    if ok and icon then
      sc.icon, sc.icon_hl = icon, hl
    end
    return sc
  end

  local function write_meta(sc)
    local meta = vim.deepcopy(sc)
    meta.stat = nil
    meta.file = ""
    vim.fn.writefile(vim.split(vim.json.encode(meta), "\n"), sc.file .. ".meta")
  end

  local function new_scratch_table(name, ft)
    local sc = { name = name, ft = ft, file = "" }
    if filekey.count ~= false then sc.count = 1 end
    if filekey.cwd ~= false then sc.cwd = vim.fs.normalize(assert(uv.cwd())) end
    if filekey.branch ~= false and uv.fs_stat(".git") then
      local out = vim.trim(vim.fn.systemlist("git branch --show-current")[1] or "")
      if vim.v.shell_error == 0 and out ~= "" then sc.branch = out end
    end
    with_icon(sc)
    sc.file = scratch_file_for(sc)
    return sc
  end

  -- drop every buffer of this nvim that points at `file`, so autowrite can't recreate it
  local function release_buffers(file, keep_changes)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      local bname = vim.api.nvim_buf_get_name(b)
      if bname ~= "" and vim.fs.normalize(bname) == file then
        if keep_changes and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].modified then
          vim.api.nvim_buf_call(b, function() vim.cmd("silent! write") end)
        end
        pcall(vim.api.nvim_del_augroup_by_name, "snacks_scratch_autowrite_" .. b)
        pcall(vim.api.nvim_del_augroup_by_name, "snacks_scratch_preview_autowrite_" .. b)
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end

  -- Build the plan from the buffer: which rows are existing / new, which ids are deleted
  local function build_plan()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local rows, seen, errors = {}, {}, {}

    for row, line in ipairs(lines) do
      local id, _, rest = split_id(line)
      local name, ft = parse_line(rest)
      if name ~= "" then
        local item = { row = row, name = name, ft = ft }
        if id then
          if seen[id] then
            table.insert(errors, row)
          else
            seen[id] = true
            item.id = id
          end
        end
        table.insert(rows, item)
      end
    end

    local deleted = {}
    for id, entry in pairs(entries) do
      if not seen[id] then
        table.insert(deleted, { id = id, scratch = entry.scratch })
      end
    end

    -- id accidentally removed (cc, d0, ...) but same name/ft retyped: keep the original scratch
    for _, item in ipairs(rows) do
      if not item.id then
        for i, d in ipairs(deleted) do
          if d.scratch.name == item.name and d.scratch.ft == item.ft then
            item.id = d.id
            table.remove(deleted, i)
            break
          end
        end
      end
    end

    return rows, deleted, errors
  end

  local function save()
    local rows, deleted, errors = build_plan()

    if #errors > 0 then
      vim.notify(
        ("Scratch: 第 %s 行是複製出來的項目（yy/p），請刪除，或用 o 新增一行"):format(table.concat(errors, ", ")),
        vim.log.levels.ERROR
      )
      return false
    end

    -- something changed these scratches outside this panel (another nvim?)
    local function changed_elsewhere(id)
      local e = entries[id]
      return not uv.fs_stat(e.scratch.file) or read_meta_text(e.scratch.file) ~= e.meta
    end
    for _, item in ipairs(rows) do
      if item.id and changed_elsewhere(item.id) then
        vim.notify("Scratch: 「" .. entries[item.id].scratch.name .. "」已在別處變動，請關閉後重開面板", vim.log.levels.ERROR)
        return false
      end
    end
    for _, d in ipairs(deleted) do
      if changed_elsewhere(d.id) then
        vim.notify("Scratch: 「" .. d.scratch.name .. "」已在別處變動，請關閉後重開面板", vim.log.levels.ERROR)
        return false
      end
    end

    -- compute targets
    local freed = {} -- files that will be moved away or deleted
    for _, d in ipairs(deleted) do freed[d.scratch.file] = true end

    local renames, creates, targets = {}, {}, {}
    for _, item in ipairs(rows) do
      if item.id then
        local sc = entries[item.id].scratch
        if sc.name ~= item.name or sc.ft ~= item.ft then
          local updated = vim.deepcopy(sc)
          updated.name, updated.ft, updated.id = item.name, item.ft, nil
          with_icon(updated)
          updated.file = scratch_file_for(updated)
          item.target = updated
          if updated.file ~= sc.file then
            freed[sc.file] = true
            table.insert(renames, { from = sc.file, sc = updated })
          end
        else
          item.target = sc
        end
      else
        item.target = new_scratch_table(item.name, item.ft)
        table.insert(creates, item.target)
      end
      local f = item.target.file
      if targets[f] then
        vim.notify(("Scratch: 第 %d 行與第 %d 行會對應到同一個 scratch（%s）"):format(targets[f], item.row, item.name),
          vim.log.levels.ERROR)
        return false
      end
      targets[f] = item.row
    end

    local function occupied(f)
      return not freed[f] and (uv.fs_stat(f) or uv.fs_stat(f .. ".meta"))
    end
    for _, r in ipairs(renames) do
      if occupied(r.sc.file) then
        vim.notify("Scratch: 已存在名為「" .. r.sc.name .. "」的 scratch，取消套用", vim.log.levels.ERROR)
        return false
      end
    end
    for _, sc in ipairs(creates) do
      if occupied(sc.file) then
        vim.notify("Scratch: 已存在名為「" .. sc.name .. "」的 scratch，取消套用", vim.log.levels.ERROR)
        return false
      end
    end

    if #deleted > 0 then
      local names = {}
      for _, d in ipairs(deleted) do table.insert(names, "  - " .. format_scratch_line(d.scratch)) end
      local choice = vim.fn.confirm(
        ("將刪除 %d 個 scratch：\n%s"):format(#deleted, table.concat(names, "\n")), "&Yes\n&No", 2)
      if choice ~= 1 then
        vim.notify("Scratch: 已取消", vim.log.levels.WARN)
        return false
      end
    end

    -- release buffers first (preview window writes its buffer when hidden)
    local was_preview = preview_enabled
    close_preview()
    for _, d in ipairs(deleted) do release_buffers(d.scratch.file, false) end
    for _, r in ipairs(renames) do release_buffers(r.from, true) end

    for _, d in ipairs(deleted) do
      os.remove(d.scratch.file)
      os.remove(d.scratch.file .. ".meta")
    end

    -- two-phase rename so swapping names never overwrites a file
    local tmp_suffix = ".scratch-tmp-" .. nonce
    for _, r in ipairs(renames) do
      os.rename(r.from, r.from .. tmp_suffix)
      os.remove(r.from .. ".meta")
    end
    for _, r in ipairs(renames) do
      os.rename(r.from .. tmp_suffix, r.sc.file)
      write_meta(r.sc)
    end

    for _, sc in ipairs(creates) do
      vim.fn.writefile({ "" }, sc.file)
      write_meta(sc)
    end

    -- rebuild entries: existing ids are kept so undo still maps correctly
    local new_entries = {}
    local display = {}
    entries = new_entries
    for _, item in ipairs(rows) do
      local id = register(item.target, item.id)
      table.insert(display, render_line(id, item.target))
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, display)
    vim.bo[buf].modified = false
    refresh_conceal()
    clamp_cursor()
    preview_enabled = was_preview
    update_preview()

    local msg = ("Scratch panel saved! (重新命名 %d、新增 %d、刪除 %d)"):format(#renames, #creates, #deleted)
    vim.notify(msg, vim.log.levels.INFO)
    return true
  end

  -- ------------------------------------------------------------------
  -- Keymaps & autocmds
  -- ------------------------------------------------------------------
  local function bmap(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = buf }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  bmap("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local id, _, rest = split_id(line)
    if parse_line(rest) == "" then return end
    if (vim.bo[buf].modified or not id) and not save() then return end
    local scratch = scratch_at_cursor()
    if not scratch then return end

    preview_enabled = false
    close_preview()
    vim.api.nvim_win_close(win, true)
    Snacks.scratch.open({ file = scratch.file, ft = scratch.ft, name = scratch.name })
  end, { desc = "Open Scratch" })

  bmap("n", "gh", function()
    preview_enabled = not preview_enabled
    if preview_enabled then
      update_preview()
    else
      close_preview()
    end
  end, { desc = "Toggle Scratch Preview" })

  bmap("n", "<C-u>", function() scroll_preview("<C-u>") end, { desc = "Scroll Preview Up" })
  bmap("n", "<C-o>", function() scroll_preview("<C-d>", "<C-o>") end, { desc = "Scroll Preview Down" })

  -- editing keys that would otherwise eat into the hidden id
  local function chars_after_prefix()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local plen, line = prefix_len(row)
    return plen, line, col
  end

  bmap("i", "<BS>", function()
    local plen, _, col = chars_after_prefix()
    return col <= plen and "" or "<BS>"
  end, { expr = true, desc = "Backspace (keep id)" })

  bmap("i", "<C-u>", function()
    local plen, line, col = chars_after_prefix()
    if col <= plen then return "" end
    return string.rep("<BS>", vim.fn.strchars(line:sub(plen + 1, col)))
  end, { expr = true, desc = "Delete to line start (keep id)" })

  bmap("i", "<C-w>", function()
    local plen, line, col = chars_after_prefix()
    if col <= plen then return "" end
    local before = line:sub(plen + 1, col)
    local kept = before:gsub("%s+$", ""):gsub("%S+$", "")
    local n = vim.fn.strchars(before) - vim.fn.strchars(kept)
    return string.rep("<BS>", n > 0 and n or vim.fn.strchars(before))
  end, { expr = true, desc = "Delete word (keep id)" })

  for _, lhs in ipairs({ "cc", "S" }) do
    bmap("n", lhs, function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local plen = prefix_len(row)
      if plen == 0 then return lhs end
      return (plen + 1) .. "|C"
    end, { expr = true, desc = "Change line (keep id)" })
  end

  bmap({ "n", "x", "o" }, "0", function()
    local plen = prefix_len(vim.api.nvim_win_get_cursor(0)[1])
    return plen > 0 and ((plen + 1) .. "|") or "0"
  end, { expr = true, desc = "Line start (after id)" })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    callback = function()
      clamp_cursor()
      update_preview()
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      refresh_conceal()
      update_preview()
    end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function() save() end,
  })

  local close_ui = function()
    preview_enabled = false
    close_preview()
    vim.bo[buf].modified = false
    vim.cmd("close")
  end
  bmap("n", "q", close_ui, { desc = "Close" })
  bmap("n", "<Esc>", close_ui, { desc = "Close" })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      preview_enabled = false
      close_preview()
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      preview_enabled = false
      close_preview()
    end,
  })

  clamp_cursor()
end

Nvim.keys.normal_mode["<leader>r."] = {
  function()
    Snacks.scratch.open({
      name = vim.fn.expand("%:."),
      ft = "markdown",
    })

    vim.schedule(function()
      pcall(vim.cmd, "FloatIntoCurrent")
    end)

    vim.schedule(function()
      local ft = vim.bo.filetype
      local marker = Nvim.builtin.FtFoldMarker[ft]
      if marker and type(marker) == "string" and marker:find(",") then
        vim.opt_local.foldmarker = marker
      end
    end)
  end,
  desc = "Quick Note (current window)",
}

Nvim.keys.normal_mode["<leader>."] = {
  function()
    local function prompt_key(lines)
      vim.cmd("redraw!")
      return Nvim.Menu.menu_getkeys(lines)
    end

    local function prompt_text(prompt, default)
      vim.cmd("redraw!")
      local value = vim.fn.input(prompt, default or "")
      vim.cmd("redraw!")
      return vim.trim(value)
    end

    local lines = {
      "Scratch Command:",
      "----------------------------------",
      "  .   → note to current",
      "  d   → NOTE scratch to current",
      "  <   → quick note (float)",
      "  w   → manage scratches UI",
      "  i/j/k/l → top/bottom/left/right",
      "  n/<CR> → new scratch",
      "  q → cancel",
      "----------------------------------",
      "Press key: ",
    }

    local cmd = prompt_key(lines)
    local pos = { i = "top", k = "bottom", j = "left", l = "right" }

    -- normalize <CR>
    if cmd == "" then cmd = "n" end

    if cmd == "q" then
      return
    end

    if cmd == "w" then
      open_scratch_manager()
      return
    end

    if cmd == "d" then
      Snacks.scratch.open({
        name = "NOTE",
        ft = "markdown",
        win = { position = "float" },
      })

      vim.schedule(function()
        pcall(vim.cmd, "FloatIntoCurrent")
      end)

      vim.schedule(function()
        local ft = vim.bo.filetype
        local marker = Nvim.builtin.FtFoldMarker[ft]
        if marker and type(marker) == "string" and marker:find(",") then
          vim.opt_local.foldmarker = marker
        end
      end)

      return
    end

    -- quick note
    if cmd == "." or cmd == "<" or pos[cmd] then
      local position = "float"

      if cmd == "<" then
        position = "float" -- 先 float，再 dock
      elseif pos[cmd] then
        position = pos[cmd]
      end

      Snacks.scratch.open({
        name = vim.fn.expand("%:."),
        ft = "markdown",
        win = { position = position },
      })

      if cmd == "." then
        vim.schedule(function()
          pcall(vim.cmd, "FloatIntoCurrent")
        end)
      end

      vim.schedule(function()
        local ft = vim.bo.filetype
        local marker = Nvim.builtin.FtFoldMarker[ft]
        if marker and type(marker) == "string" and marker:find(",") then
          vim.opt_local.foldmarker = marker
        end
      end)

      return
    end

    -- only "n" goes to the create/new flow
    if cmd ~= "n" then
      return
    end
    local name = prompt_text("Scratch name (number/name/%/./>/</nothing): ")

    if name == "%" or name == "." then
      -- expand % early so all branches see final name
      name = vim.fn.expand("%:.")
    end

    local ExecuteSnackOpen = function(_) end

    if name:match("^%d+$") then
      -- number -> count slot scratch
      ExecuteSnackOpen = function(filename)
        local count = tonumber(filename)
        local keys = tostring(count) .. "<Plug>(snacks-scratch-raw)"
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
      end
    elseif name == "" then
      -- empty -> default toggle
      ExecuteSnackOpen = function(_)
        Snacks.scratch()
      end
    elseif name == "<" or name == ">" then
      ExecuteSnackOpen = function(mark)
        local filename = vim.fn.expand("%:.")
        local mode = {
          ["<"] = "float",
          [">"] = "n"
        }
        local choice = mode[mark]
        local position = (choice == "n" or choice == ".") and "float" or (pos[choice] or "float")
        Snacks.scratch.open({
          name = filename,
          win = { position = position },
        })
        return choice
      end
    else
      -- named scratch (ask ft)
      ExecuteSnackOpen = function(filename)
        local ft = prompt_text("Filetype (markdown/lua/python/./...): ")
        local mode = prompt_key({ "Window? [Enter]=float, [n/.]=current, i,k,j,l:top/bottom/left/right: " })
        mode = vim.trim(mode):lower()

        if mode == "" then mode = "n" end
        if ft == "" or ft == "." then
          ft = nil
        end
        local pos = { i = "top", k = "bottom", j = "left", l = "right" }

        -- "n" is always float first (then FloatIntoCurrent)
        local position = (mode == "n" or mode == ".") and "float" or (pos[mode] or "float")
        Snacks.scratch.open({
          name = filename,
          ft = ft,
          win = { position = position },
        })
        return mode
      end
    end

    -- MUST run for all paths
    if name:match("^%d+$") or name == "" then
      ExecuteSnackOpen(name)
    else
      local mode = ExecuteSnackOpen(name)
      if mode == "n" or mode == "." then
        vim.schedule(function()
          pcall(vim.cmd, "FloatIntoCurrent")
        end)
      end
    end

    vim.schedule(function()
      local ft = vim.bo.filetype
      local marker = Nvim.builtin.FtFoldMarker[ft]
      if marker and type(marker) == "string" and marker:find(",") then
        vim.opt_local.foldmarker = marker
      end
    end)
  end,
  desc = "Create Scratch (named)",
}

Nvim.keys.normal_mode["<leader>>"] = {
  "<cmd>lua Snacks.scratch.select()<cr>",
  desc = "Select Scratch Buffer",
}
