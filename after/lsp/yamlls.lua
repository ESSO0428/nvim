local helpers = require("user.lsp.helpers")

return {
  capabilities = Nvim.builtin.lsp.get_capabilities(),
  settings = {
    redhat = {
      telemetry = { enabled = false },
    },
    yaml = {
      format = { enable = true },
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
