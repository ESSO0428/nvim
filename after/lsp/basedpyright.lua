local helpers = require("user.lsp.helpers")

return {
  single_file_support = true,
  filetypes = { "python" },
  root_dir = helpers.python_root_dir,
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        reportMissingTypeStubs = false,
        typeCheckingMode = "basic",
        enableTypeIgnoreComments = true,
      },
    },
  },
}
