return {
  single_file_support = true,
  filetypes = { "python" },
  init_options = {
    settings = {
      args = {},
    },
  },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.hoverProvider = false
    client.server_capabilities.renameProvider = false
  end,
}
