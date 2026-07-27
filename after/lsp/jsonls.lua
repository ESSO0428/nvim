local helpers = require("user.lsp.helpers")

return {
  settings = {
    json = {
      schemas = helpers.get_json_schemas(),
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
      vim.lsp.buf.format {
        bufnr = bufnr,
        filter = function(attached)
          return attached.id == client.id
        end,
      }
    end, {
      desc = "Format current JSON buffer with jsonls",
      force = true,
    })
  end,
}
