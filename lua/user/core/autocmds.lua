Nvim = Nvim or {}

local _file_opened_group = vim.api.nvim_create_augroup("_file_opened", { clear = true })
local _lsp_bootstrap_ready_group = vim.api.nvim_create_augroup("_lsp_bootstrap_ready", { clear = true })

vim.g.lsp_bootstrap_ready = vim.g.lsp_bootstrap_ready == true

Nvim.runtime = Nvim.runtime or {}

local function emit_lsp_bootstrap_ready(data)
  if vim.g.lsp_bootstrap_ready == true then
    return false
  end

  vim.g.lsp_bootstrap_ready = true

  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", {
      pattern = "LspBootstrapReady",
      modeline = false,
      data = data,
    })
  end)

  return true
end

local function reset_lsp_bootstrap_ready()
  vim.g.lsp_bootstrap_ready = false
end

Nvim.runtime.emit_lsp_bootstrap_ready = emit_lsp_bootstrap_ready
Nvim.runtime.reset_lsp_bootstrap_ready = reset_lsp_bootstrap_ready

vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufNewFile" }, {
  group = _file_opened_group,
  nested = true,
  callback = function(args)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
    if not (vim.fn.expand "%" == "" or buftype == "nofile") then
      vim.api.nvim_del_augroup_by_name "_file_opened"
      vim.api.nvim_exec_autocmds("User", { pattern = "FileOpened" })
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = _lsp_bootstrap_ready_group,
  pattern = "SessionLoadPre",
  callback = reset_lsp_bootstrap_ready,
})

vim.api.nvim_create_autocmd("User", {
  group = _lsp_bootstrap_ready_group,
  pattern = "SessionLoadPost",
  callback = function(args)
    -- 若已啟用 session-manager，交給 user/session.lua 走更精準的
    -- SessionManagerLoadPost 路徑來定義 LspBootstrapReady。
    if package.loaded["session_manager"] or package.loaded["session_manager.utils"] then
      return
    end

    emit_lsp_bootstrap_ready(vim.tbl_extend("force", {
      source = "session_load_post",
    }, args.data or {}))
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = _lsp_bootstrap_ready_group,
  pattern = "FileOpened",
  callback = function()
    if vim.g.session_loading == true or vim.g.lsp_bootstrap_ready == true then
      return
    end

    emit_lsp_bootstrap_ready({
      source = next(vim.fn.argv()) ~= nil and "argv" or "file_opened",
    })
  end,
})
