return {
  capabilities = Nvim.builtin.lsp.get_capabilities(),
  settings = {
    css = {
      lint = { unknownAtRules = "ignore" },
    },
    scss = {
      lint = { unknownAtRules = "ignore" },
    },
    less = {
      lint = { unknownAtRules = "ignore" },
    },
  },
}
