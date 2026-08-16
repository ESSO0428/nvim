local Path = require "plenary.path"
local config = require "session_manager.config"
local utils = require "session_manager.utils"
local config_group = vim.api.nvim_create_augroup("MyConfigGroup", {}) -- A global group for all your config autocommands

-- NOTE: Below is a fix for the `bufferline` pinning status, integrated with `neovim-session-manager`
-- `vim.api.nvim_buf_delete(buffer, { force = true })` can cause abnormal bufferline pinning status.
-- This issue mainly occurs when Neovim just starts and sources the session view.
-- `utils.first_load` is used to check if Neovim has just started.
-- If Neovim just started, `vim.api.nvim_buf_delete(buffer, { force = true })` is not executed.
-- After the first view load, the status is set to false.
-- On subsequent session loads, unnecessary buffers are closed.
utils.first_load = true
utils.session_loading = false
function utils.load_session(filename, discard_current)
  -- 尚未開始切換 session，先處理未儲存內容。
  if not discard_current then
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buffer)
          and vim.api.nvim_get_option_value("modified", { buf = buffer }) then
        local choice = vim.fn.confirm(
          "The files in the current session have changed. Save changes?",
          "&Yes\n&No\n&Cancel"
        )

        if choice == 3 or choice == 0 then
          return false
        end

        if choice == 1 then
          vim.cmd("silent wall")
        end

        break
      end
    end
  end

  -- 從刪除舊 buffers 之前就進入 loading 狀態，
  -- 避免 BufDelete / BufWipeout 讓 bufferline 反覆重算。
  utils.session_loading = true
  vim.g.session_loading = true

  local reset_lsp_bootstrap_ready = vim.tbl_get(Nvim, "runtime", "reset_lsp_bootstrap_ready")
  if type(reset_lsp_bootstrap_ready) == "function" then
    reset_lsp_bootstrap_ready()
  else
    vim.g.lsp_bootstrap_ready = false
  end

  -- 保留 upstream 的 SessionLoadPre/Post 介面，
  -- 同時維持本地自訂的 SessionManagerLoadPre/Post 別名。
  local pre_event_data = {
    filename = filename,
  }
  for _, pattern in ipairs({ "SessionLoadPre", "SessionManagerLoadPre" }) do
    vim.api.nvim_exec_autocmds("User", {
      pattern = pattern,
      modeline = false,
      data = pre_event_data,
    })
  end

  local current_buffer = vim.api.nvim_get_current_buf()

  -- 第一次啟動自動載入時，不清除全部既有 buffers，
  -- 保留原本針對 bufferline pinning 狀態的 workaround。
  if not utils.first_load then
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buffer)
          and buffer ~= current_buffer then
        pcall(vim.api.nvim_buf_delete, buffer, {
          force = true,
        })
      end
    end
  end

  if vim.api.nvim_buf_is_valid(current_buffer) then
    pcall(vim.api.nvim_buf_delete, current_buffer, {
      force = true,
    })
  end

  local ok_source, source_err = pcall(
    vim.cmd,
    "silent source " .. vim.fn.fnameescape(filename)
  )

  -- Post event 前先解除 loading，
  -- bufferline 的 Post callback 才能清除快取並重繪。
  utils.session_loading = false
  vim.g.session_loading = false

  if ok_source then
    utils.active_session_filename = filename
    utils.first_load = false
  end

  local post_event_data = {
    success = ok_source,
    filename = filename,
    error = ok_source and nil or tostring(source_err),
  }
  for _, pattern in ipairs({ "SessionLoadPost", "SessionManagerLoadPost" }) do
    vim.api.nvim_exec_autocmds("User", {
      pattern = pattern,
      modeline = false,
      data = post_event_data,
    })
  end

  if ok_source then
    local emit_lsp_bootstrap_ready = vim.tbl_get(Nvim, "runtime", "emit_lsp_bootstrap_ready")
    if type(emit_lsp_bootstrap_ready) == "function" then
      emit_lsp_bootstrap_ready(vim.tbl_extend("force", {
        source = "session_manager",
      }, post_event_data))
    else
      vim.g.lsp_bootstrap_ready = true
      vim.api.nvim_exec_autocmds("User", {
        pattern = "LspBootstrapReady",
        modeline = false,
        data = vim.tbl_extend("force", {
          source = "session_manager",
        }, post_event_data),
      })
    end
  end

  if not ok_source then
    vim.notify(
      ("Failed to load session %q:\n%s"):format(
        filename,
        source_err
      ),
      vim.log.levels.ERROR
    )

    return false
  end

  return true
end

function Check_and_clear_empty_vars(vars)
  for _, var_name in ipairs(vars) do
    local var_value = vim.g[var_name]
    if
        (type(var_value) == "table" and vim.tbl_isempty(var_value))
        or (type(var_value) == "string" and var_value == "")
    then
      vim.g[var_name] = nil
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "SessionSavePre",
  group = config_group,
  callback = function()
    -- HACK: Check and adjust the global variable for Bufferline's pinned state before saving the session.
    -- If BufferlinePinnedBuffers is empty (e.g., "" or {}), set it to nil to prevent restoration issues.
    local check_variables = { "BufferlinePinnedBuffers" }
    Check_and_clear_empty_vars(check_variables)
  end,
})
local session_manager = require "session_manager"
local opt = {
  sessions_dir = Path:new(Nvim.paths.sessions_dir), -- The directory where the session files will be saved.
  path_replacer = "__",                             -- The character to which the path separator will be replaced for session files.
  colon_replacer = "++",                            -- The character to which the colon symbol will be replaced for session files.
  -- autoload_mode = require('session_manager.config').AutoloadMode.LastSession, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
  autoload_mode = config.AutoloadMode.CurrentDir,   -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
  autosave_last_session = true,                     -- Automatically save last session on exit and on session switch.
  autosave_ignore_not_normal = true,                -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
  autosave_ignore_dirs = {},                        -- A list of directories where the session will not be autosaved.
  autosave_ignore_filetypes = {                     -- All buffers of these file types will be closed before the session is saved.
    "gitcommit",
  },
  autosave_ignore_buftypes = {
    "terminal",
    "toggleterm",
  },                                -- All buffers of these bufer types will be closed before the session is saved.
  autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
  max_path_length = 80,             -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
}
if next(vim.fn.argv()) ~= nil then
  opt.autoload_mode = require("session_manager.config").AutoloadMode.Disabled
  opt.autosave_last_session = false
end
session_manager.setup(opt)
