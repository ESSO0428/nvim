local M = {}

local ft_map = require("user.lsp.lvim_ft_map")
local ft_overrides = require("user.lsp.lvim_ft_overrides")

local configured_servers = {}
local enabled_servers = {}
local pending_installs = {}
local unsupported_servers = {}

local function resolve_servers_for_filetype(filetype)
  local servers = ft_overrides[filetype] or ft_map[filetype] or {}
  local out = {}
  local seen = {}

  for _, server_name in ipairs(servers) do
    if not seen[server_name] then
      seen[server_name] = true
      table.insert(out, server_name)
    end
  end

  return out
end

local function build_server_filetype_map()
  local known_filetypes = {}
  local out = {}

  for filetype in pairs(ft_map) do
    known_filetypes[filetype] = true
  end
  for filetype in pairs(ft_overrides) do
    known_filetypes[filetype] = true
  end

  for filetype in pairs(known_filetypes) do
    for _, server_name in ipairs(resolve_servers_for_filetype(filetype)) do
      out[server_name] = out[server_name] or {}
      table.insert(out[server_name], filetype)
    end
  end

  return out
end

local server_filetypes = build_server_filetype_map()

local function get_server_config(server_name)
  local get = Nvim.builtin.lsp.get_server_config
  local config = type(get) == "function" and get(server_name) or {}

  if server_filetypes[server_name] and config.filetypes == nil then
    config.filetypes = vim.deepcopy(server_filetypes[server_name])
  end

  return config
end

local function auto_install_excluded(server_name)
  local exclude = vim.tbl_get(Nvim, "builtin", "lsp", "automatic_installation", "exclude") or {}
  return vim.tbl_contains(exclude, server_name)
end

local function notify_once(msg, level)
  if vim.in_fast_event() then
    vim.schedule(function()
      vim.notify_once(msg, level)
    end)
    return
  end

  vim.notify_once(msg, level)
end

function M.get_servers_for_filetype(filetype)
  return resolve_servers_for_filetype(filetype)
end

function M.configure_server(server_name)
  if configured_servers[server_name] or unsupported_servers[server_name] then
    return not unsupported_servers[server_name]
  end

  local ok, err = pcall(vim.lsp.config, server_name, get_server_config(server_name))
  if not ok then
    unsupported_servers[server_name] = err or true
    notify_once(("Skipping unsupported LSP server: %s"):format(server_name), vim.log.levels.WARN)
    return false
  end

  configured_servers[server_name] = true
  return true
end

function M.enable_server(server_name)
  if enabled_servers[server_name] then
    return true
  end

  if not M.configure_server(server_name) then
    return false
  end

  local config = vim.lsp.config[server_name]
  local cmd = config and config.cmd or nil
  if type(cmd) == "string" and vim.fn.executable(cmd) ~= 1 then
    return false
  end
  if type(cmd) == "table" and type(cmd[1]) == "string" and vim.fn.executable(cmd[1]) ~= 1 then
    return false
  end

  vim.lsp.enable(server_name)
  enabled_servers[server_name] = true
  return true
end

function M.ensure_server(server_name)
  if enabled_servers[server_name] or pending_installs[server_name] or unsupported_servers[server_name] then
    return
  end

  local mappings = require("mason-lspconfig.mappings").get_mason_map()
  local pkg_name = mappings.lspconfig_to_package[server_name]
  if not pkg_name then
    M.enable_server(server_name)
    return
  end

  local registry = require("mason-registry")
  if registry.is_installed(pkg_name) then
    M.enable_server(server_name)
    return
  end

  if auto_install_excluded(server_name) then
    M.enable_server(server_name)
    return
  end

  local ok_pkg, pkg = pcall(registry.get_package, pkg_name)
  if not ok_pkg then
    M.enable_server(server_name)
    return
  end

  pending_installs[server_name] = true
  notify_once(("Installation in progress for [%s]"):format(server_name), vim.log.levels.INFO)
  pkg:install():once("closed", function()
    pending_installs[server_name] = nil
    if pkg:is_installed() then
      vim.schedule(function()
        if M.enable_server(server_name) then
          notify_once(("Installation complete for [%s]"):format(server_name), vim.log.levels.INFO)
        end
      end)
    end
  end)
end

function M.maybe_enable_for_filetype(filetype)
  if not filetype or filetype == "" then
    return
  end

  for _, server_name in ipairs(M.get_servers_for_filetype(filetype)) do
    M.ensure_server(server_name)
  end
end

function M.maybe_enable_for_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  M.maybe_enable_for_filetype(vim.bo[bufnr].filetype)
end

function M.bootstrap_existing_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.maybe_enable_for_buffer(bufnr)
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_lsp_lvim_auto_enable", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      M.maybe_enable_for_buffer(args.buf)
    end,
  })
end

return M
