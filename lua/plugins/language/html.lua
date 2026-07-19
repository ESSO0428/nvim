return {
  {
    "aca/emmet-ls",
    ft = { "html", "htmldjango", "css", "javascriptreact", "typescriptreact", "svelte", "vue" },
    config = function()
      local capabilities = vim.deepcopy(Nvim.builtin.lsp.capabilities or vim.lsp.protocol.make_client_capabilities())
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
        },
      }
      capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

      vim.lsp.config("emmet_ls", {
        cmd = { "emmet-ls", "--stdio" },
        filetypes = {
          "html",
          "htmldjango",
          "css",
          "javascript",
          "typescript",
          "eruby",
          "typescriptreact",
          "javascriptreact",
          "svelte",
          "vue",
        },
        root_dir = function(bufnr, on_dir)
          local root = vim.fs.root(bufnr, { ".git", "package.json", "tailwind.config.js", "postcss.config.js" })
          on_dir(root or vim.uv.cwd())
        end,
        settings = {},
        capabilities = capabilities,
      })
      vim.lsp.enable("emmet_ls")
    end
  },
}
