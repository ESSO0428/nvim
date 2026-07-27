-- Derived from user-level LunarVim LSP config (`lua/user/lsp.lua` and `after/ftplugin/*.lua`).
-- These entries intentionally override the generated upstream template map.

return {
  htmldjango = { "tailwindcss", "html" },
  javascript = { "tailwindcss", "ts_ls" },
  javascriptreact = { "tailwindcss", "ts_ls" },
  php = { "tailwindcss", "intelephense" },
  python = { "basedpyright", "ruff" },
  typescript = { "tailwindcss", "ts_ls" },
  typescriptreact = { "tailwindcss", "ts_ls" },
  vue = { "tailwindcss", "vue_ls" },
  ["yaml.docker-compose"] = { "yamlls" },
  ["yaml.gitlab"] = { "yamlls" },
}
