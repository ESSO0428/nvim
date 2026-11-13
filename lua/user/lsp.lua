Nvim.builtin = Nvim.builtin or {}
Nvim.builtin.lsp = Nvim.builtin.lsp or {}

Nvim.builtin.lsp.ensure_installed = {
  "lua_ls",
  "basedpyright",
  "ruff",
  "html",
  "cssls",
  "ts_ls",
  "yamlls",
  "tailwindcss",
  "intelephense",
  "marksman",
  "bashls",
  "jsonls",
}

Nvim.builtin.lsp.server_names = vim.deepcopy(Nvim.builtin.lsp.ensure_installed)
Nvim.builtin.lsp.servers = {}
Nvim.builtin.lsp.automatic_installation = {
  exclude = {},
}

vim.hl.priorities.semantic_tokens = 90
vim.api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    if vim.bo[args.buf].filetype ~= "python" then
      return
    end

    local token = args.data.token

    local types = {
      namespace = true,
      ["function"] = true,
      class = true,
    }

    if types[token.type] then
      vim.lsp.semantic_tokens.highlight_token(
        token,
        args.buf,
        args.data.client_id,
        "@lsp.type." .. token.type .. ".python",
        { priority = 110 }
      )
    end
  end,
})

vim.diagnostic.config {
  float = { border = "rounded" },
}

-- FIX: some servers advertise fileOperations filters with globs that vim.glob rejects
-- (e.g. `**/*.{}` from an empty extension list), which crashes mini.files / oil /
-- lsp-file-operations on rename/create/delete. Drop invalid filters; drop the whole
-- operation if none remain, so an empty filter list isn't treated as "match all".
local function sanitize_file_operations(client)
  local ops = vim.tbl_get(client.server_capabilities or {}, "workspace", "fileOperations")
  if type(ops) ~= "table" then
    return
  end
  for method, reg in pairs(ops) do
    if type(reg) == "table" and type(reg.filters) == "table" then
      local valid, dropped = {}, {}
      for _, filter in ipairs(reg.filters) do
        local glob = vim.tbl_get(filter, "pattern", "glob")
        if type(glob) == "string" and pcall(vim.glob.to_lpeg, glob) then
          table.insert(valid, filter)
        else
          table.insert(dropped, tostring(glob))
        end
      end
      if #dropped > 0 then
        reg.filters = valid
        if #valid == 0 then
          ops[method] = nil
        end
        -- see :LspLog
        vim.lsp.log.warn(
          ("%s: ignored invalid fileOperations.%s glob(s): %s"):format(client.name, method, table.concat(dropped, ", "))
        )
      end
    end
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_sanitize_file_operations", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      sanitize_file_operations(client)
    end
  end,
})

-- HACK: Keep the old `_str_utfindex_enc` workaround only for Neovim 0.10.x.
if vim.fn.has("nvim-0.11") == 0 then
  require("vim.lsp.util")._str_utfindex_enc = function(line, index, encoding)
    if not encoding then
      encoding = "utf-16"
    end
    if encoding == "utf-8" then
      if index then
        return index
      else
        return #line
      end
    elseif encoding == "utf-16" then
      local _, col16 = vim.str_utfindex(line, index)
      return col16
    elseif encoding == "utf-32" then
      local col32, _ = vim.str_utfindex(line, index)
      return col32
    else
      error("Invalid encoding: " .. vim.inspect(encoding))
    end
  end
end


local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_lfo, lfo = pcall(require, "lsp-file-operations")
if ok_lfo and type(lfo.default_capabilities) == "function" then
  capabilities = vim.tbl_deep_extend(
    "force",
    capabilities,
    -- returns configured operations if setup() was already called
    -- or default operations if not
    lfo.default_capabilities()
  )
end

capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- WARNING: Disable (comment) this dynamicRegistration avoid neovim hang off when lsp attach (be like basedpyright have watch instead dynamicRegistration)
-- capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
Nvim.builtin.lsp.capabilities = capabilities
Nvim.builtin.lsp.get_capabilities = function()
  return vim.deepcopy(Nvim.builtin.lsp.capabilities or capabilities)
end

Nvim.builtin.lsp.get_server_config = function(server_name)
  local server = vim.deepcopy((Nvim.builtin.lsp.servers or {})[server_name] or {})
  server.capabilities = vim.tbl_deep_extend("force", {}, Nvim.builtin.lsp.capabilities or {}, server.capabilities or {})
  return server
end
