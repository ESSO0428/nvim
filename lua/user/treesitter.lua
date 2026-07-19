---@type rainbow_delimiters.config
vim.g.rainbow_delimiters = {
  strategy = {
    [""] = "rainbow-delimiters.strategy.global",
    vim = "rainbow-delimiters.strategy.local",
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-blocks",
  },
  -- NOTE: We intentionally lower semantic token priority in user/lsp.lua.
  -- rainbow-delimiters defaults to a midpoint between semantic_tokens and
  -- treesitter, which would fall below treesitter and become visually hidden.
  -- Keep rainbow highlights above treesitter explicitly.
  priority = {
    [""] = vim.hl.priorities.treesitter + 10,
  },
  highlight = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
}
vim.api.nvim_create_autocmd("User", {
  pattern = "FileOpened",
  callback = function()
    require("nvim-treesitter.install").compilers = { "clang", "gcc" }
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mysql",
  callback = function(args)
    vim.treesitter.start(args.buf, "sql")
    -- vim.bo[args.buf].syntax = 'on' -- only if additional legacy syntax is needed
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql" },
  once = true,
  callback = function()
    local ft = require "Comment.ft"
    ft.set("mysql", "-- %s")
  end,
})

-- WARNING: On Neovim 0.12.x, runtime queries may mismatch with another parser
-- candidate on runtimepath. Pin parsers for languages that hit query/parser
-- mismatches in practice.
for lang, parser_path in pairs({
  lua = vim.fn.stdpath("data") .. "/site/parser/lua.so",
  vim = vim.fn.stdpath("data") .. "/site/parser/vim.so",
}) do
  if vim.uv.fs_stat(parser_path) then
    pcall(vim.treesitter.language.add, lang, { path = parser_path })
  end
end
