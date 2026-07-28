local helpers = require("user.lsp.helpers")

return {
  capabilities = Nvim.builtin.lsp.get_capabilities(),
  single_file_support = true,
  filetypes = { "php" },
  root_dir = helpers.php_root_dir,
}
