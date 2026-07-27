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

vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
  config = vim.tbl_deep_extend("force", config or {}, {
    border = "rounded",
    close_events = { "BufHidden", "InsertLeave" },
  })
  return vim.lsp.handlers.signature_help(err, result, ctx, config)
end

vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
  config = vim.tbl_deep_extend("force", config or {}, { border = "rounded" })
  return vim.lsp.handlers.hover(err, result, ctx, config)
end
vim.diagnostic.config {
  float = { border = "rounded" },
}

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
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
Nvim.builtin.lsp.capabilities = capabilities

Nvim.builtin.lsp.get_server_config = function(server_name)
  local server = vim.deepcopy((Nvim.builtin.lsp.servers or {})[server_name] or {})
  server.capabilities = vim.tbl_deep_extend("force", {}, Nvim.builtin.lsp.capabilities or {}, server.capabilities or {})
  return server
end
