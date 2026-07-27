local helpers = require("user.lsp.helpers")

return {
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
