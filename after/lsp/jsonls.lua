local helpers = require("user.lsp.helpers")

local dap_launch_schema_url = "https://codeberg.org/mfussenegger/dapconfig-schema/raw/branch/master/dapconfig-schema.json"

local function has_launch_json_schema(schemas)
  for _, schema in ipairs(schemas) do
    if schema.url == dap_launch_schema_url then
      return true
    end

    for _, file_match in ipairs(schema.fileMatch or {}) do
      if file_match == "launch.json"
          or file_match == ".vscode/launch.json"
          or file_match == "**/.vscode/launch.json" then
        return true
      end
    end
  end

  return false
end

local function get_json_schemas()
  local schemas = helpers.get_json_schemas()

  if not has_launch_json_schema(schemas) then
    table.insert(schemas, {
      name = "nvim-dap launch.json",
      description = "nvim-dap / VSCode launch.json schema",
      fileMatch = {
        ".vscode/launch.json",
        "**/.vscode/launch.json",
      },
      url = dap_launch_schema_url,
    })
  end

  return schemas
end

return {
  settings = {
    json = {
      schemas = get_json_schemas(),
      validate = { enable = true },
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
