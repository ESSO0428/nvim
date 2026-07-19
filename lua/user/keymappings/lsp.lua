-- Nvim.keys.normal_mode["gh"] = { vim.lsp.buf.hover, { desc = "LSP: documentation hover" } }
-- Nvim.keys.normal_mode["gm"] = { vim.lsp.buf.signature_help, { desc = "LSP: signature help" } }
Nvim.keys.normal_mode["gh"]            = { "<cmd>lua vim.lsp.buf.hover({ border = 'rounded' })<cr>",
  { desc = "LSP: documentation hover" } }
Nvim.keys.normal_mode["gm"]            = { "<cmd>lua require('lsp_signature').toggle_float_win()<cr>",
  { desc = "LSP: signature help" } }
Nvim.keys.normal_mode["g;"]            = { "<cmd>lua vim.lsp.buf.type_definition()<cr>",
  { desc = "LSP: Goto type definition" } }
Nvim.keys.normal_mode["gp"]            = {
  "<cmd>lua require('goto-preview').goto_preview_type_definition()<cr>",
  { desc = "LSP: Goto type definition (preview)" },
}
Nvim.keys.normal_mode['<a-o>']         = "<cmd>lua vim.lsp.buf.definition()<cr>"
Nvim.keys.normal_mode["<leader><a-o>"] = {
  "<cmd>lua require('goto-preview').goto_preview_definition()<cr>",
  { desc = "LSP: [G]oto [D]efinition (preview)" },
}

Nvim.keys.normal_mode["<leader>ui"] = { "<cmd>LspInfo<cr>", { desc = "LSP: Info" } }
Nvim.keys.normal_mode["<leader>uI"] = { "<cmd>Mason<cr>", { desc = "LSP: Mason" } }
Nvim.keys.normal_mode["<leader>ud"] = {
  "<cmd>Telescope diagnostics bufnr=0 theme=get_ivy<cr>",
  { desc = "LSP: Buffer Diagnostics" },
}
Nvim.keys.normal_mode["<leader>ue"] = { "<cmd>Telescope quickfix<cr>", { desc = "LSP: Quickfix" } }
Nvim.keys.normal_mode["<leader>ul"] = {
  "<cmd>lua vim.lsp.codelens.run()<cr>",
  { desc = "LSP: CodeLens Action" },
}
Nvim.keys.normal_mode["<leader>uq"] = {
  "<cmd>lua vim.diagnostic.setloclist()<cr>",
  { desc = "LSP: Diagnostics to Location List" },
}
Nvim.keys.normal_mode["<leader>us"] = {
  "<cmd>Telescope lsp_document_symbols<cr>",
  { desc = "LSP: Document Symbols" },
}
Nvim.keys.normal_mode["<leader>uS"] = {
  "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
  { desc = "LSP: Workspace Symbols" },
}
Nvim.keys.normal_mode['gr']         = { "<cmd>Telescope lsp_references<cr>", { desc = "lsp_references" } }
Nvim.keys.normal_mode['<leader>v']  = { "<cmd>Telescope lsp_document_symbols<cr>", { desc = "lsp_document_symbols" } }
Nvim.keys.normal_mode['<leader>V']  = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
  desc = "lsp_dynamic_workspace_symbols" }

Nvim.keys.normal_mode["<c-t>"] = { "<cmd>Outline!<cr>", { desc = "LSP: Outline Toggle" } }
Nvim.keys.normal_mode["<leader><c-t>"] = { "<cmd>OutlineFocusOutline<cr>", { desc = "LSP: Outline Focus" } }
Nvim.keys.normal_mode["<leader>I"] = { "<cmd>wincmd W<cr>", { desc = "LSP: Other Window" } }
Nvim.keys.normal_mode["<leader>K"] = { "<cmd>wincmd w<cr>", { desc = "LSP: Next Window" } }
Nvim.keys.normal_mode["gl"] = { function()
  local float = vim.diagnostic.config().float

  if float then
    local config = type(float) == "table" and float or {}
    config.scope = "line"

    vim.diagnostic.open_float(config)
  end
end, { desc = "LSP: Show line diagnostics" } }
Nvim.keys.normal_mode["<"] = { vim.diagnostic.goto_prev, { desc = "goto prev diagnostic", nowait = true } }
Nvim.keys.normal_mode[">"] = { vim.diagnostic.goto_next, { desc = "goto next diagnostic", nowait = true } }
Nvim.keys.normal_mode["<leader>u="] = {
  function()
    require("conform").format { async = true, lsp_format = "fallback" }
  end,
  { desc = "LSP: Format", nowait = true },
}
Nvim.keys.normal_mode["<leader>uf"] = {
  function()
    require("conform").format { async = true, lsp_format = "fallback" }
  end,
  { desc = "LSP: Format", nowait = true },
}
Nvim.keys.normal_mode["<leader>="] = { vim.lsp.buf.format, { desc = "Lsp Buffer Format", nowait = true } }
