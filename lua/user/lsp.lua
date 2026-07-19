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
}

Nvim.builtin.lsp.server_names = vim.deepcopy(Nvim.builtin.lsp.ensure_installed)
Nvim.builtin.lsp.servers = {}

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

local helpers = require("user.lsp.helpers")

Nvim.builtin.lsp.servers.html = {
  filetypes = { "html", "htmldjango" },
}

Nvim.builtin.lsp.servers.cssls = {
  filetypes = { "css", "scss", "less" },
  settings = {
    css = {
      validate = true,
      lint = { unknownAtRules = "ignore" },
    },
    scss = {
      validate = true,
      lint = { unknownAtRules = "ignore" },
    },
    less = {
      validate = true,
      lint = { unknownAtRules = "ignore" },
    },
  },
}

Nvim.builtin.lsp.servers.ts_ls = {
  filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  settings = {
    typescript = {
      inlayHints = helpers.get_inlay_hint_settings(),
    },
    javascript = {
      inlayHints = helpers.get_inlay_hint_settings(),
    },
  },
  handlers = {
    ["textDocument/definition"] = helpers.filtered_typescript_definition,
  },
}

Nvim.builtin.lsp.servers.yamlls = {
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  settings = {
    yaml = {
      hover = true,
      completion = true,
      validate = true,
      schemaStore = {
        enable = true,
        url = "https://www.schemastore.org/api/json/catalog.json",
      },
      schemas = helpers.get_yaml_schemas(),
    },
  },
}

Nvim.builtin.lsp.servers.tailwindcss = {
  filetypes = {
    "html",
    "htmldjango",
    "css",
    "scss",
    "less",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "php",
  },
}
