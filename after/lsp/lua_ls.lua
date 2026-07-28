return {
  capabilities = Nvim.builtin.lsp.get_capabilities(),
  settings = {
    Lua = {
      telemetry = { enable = false },
      runtime = {
        version = "LuaJIT",
        special = {
          reload = "require",
        },
      },
      diagnostics = {
        globals = { "vim", "Nvim", "lvim", "reload" },
      },
      workspace = {
        checkThirdParty = false,
        maxPreload = 5000,
        preloadFileSize = 10000,
      },
      completion = {
        callSnippet = "Replace",
      },
      hint = {
        enable = true,
      },
    },
  },
}
