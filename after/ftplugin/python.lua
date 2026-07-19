if vim.b.CURRENT_REPL == nil then
  vim.b.CURRENT_REPL = "REPL:default"
  vim.keymap.set('n', '[w', ':norm strah<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']w', ':norm strih<cr>', { buffer = true, silent = true })
  -- NOTE: str is iron.nvim command to send current line to repl
  -- And then in visual mode is send selected lines
  vim.keymap.set('n', '[r', ':norm stR<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']r', ':norm stR<cr>', { buffer = true, silent = true })
  -- NOTE: stf is iron.nvim command to send current file to repl
  vim.keymap.set('n', '[R', ':norm stf<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']R', ':norm stf<cr>', { buffer = true, silent = true })
  vim.keymap.set('v', '[w', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', ']w', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', '[r', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', ']r', 'str', { buffer = true, remap = true, silent = true })
end

if vim.b.pythonpath_lsp_initialized ~= true then
  vim.b.pythonpath_lsp_initialized = true

  local function initialize_and_deduplicate_python_paths()
    local custom_python_paths = { vim.fn.getcwd() }
    local unique_paths = {}
    for _, path in ipairs(custom_python_paths) do
      unique_paths[path] = true
    end

    local deduplicated_paths = {}
    for path, _ in pairs(unique_paths) do
      table.insert(deduplicated_paths, path)
    end

    local current_pythonpath = vim.fn.getenv("PYTHONPATH") or ""
    for _, path in ipairs(deduplicated_paths) do
      if current_pythonpath == "" or current_pythonpath == vim.NIL then
        current_pythonpath = path
      else
        current_pythonpath = current_pythonpath .. ":" .. path
      end
    end

    vim.fn.setenv("PYTHONPATH", current_pythonpath)
  end

  local function modify_pythonpath(initial_pythonpath)
    local work_directory = vim.fn.getcwd()
    local file_directory = vim.fn.expand("%:p:h")
    local modified_pythonpath = initial_pythonpath
    if not string.find(":" .. modified_pythonpath .. ":", ":" .. work_directory .. ":") then
      modified_pythonpath = work_directory .. ":" .. modified_pythonpath
    end
    if not string.find(":" .. modified_pythonpath .. ":", ":" .. file_directory .. ":") then
      modified_pythonpath = file_directory .. ":" .. modified_pythonpath
    end
    vim.fn.setenv("PYTHONPATH", modified_pythonpath)
  end

  local function reset_pythonpath(initial_pythonpath)
    vim.fn.setenv("PYTHONPATH", initial_pythonpath)
  end

  initialize_and_deduplicate_python_paths()
  local initial_pythonpath = vim.fn.getenv("PYTHONPATH") or ""
  modify_pythonpath(initial_pythonpath)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = 0,
    callback = function()
      modify_pythonpath(initial_pythonpath)
    end,
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = 0,
    callback = function()
      reset_pythonpath(initial_pythonpath)
    end,
  })
end
