local helpers = require("user.lsp.helpers")

return {
  capabilities = Nvim.builtin.lsp.get_capabilities(),
  root_dir = helpers.marksman_root_dir,
  root_markers = { ".git" },
  single_file_support = true,
}
