local M = {}

M.pending_installs = {}

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

local function get_ts()
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    return nil
  end

  return ts
end

function M.set_compilers()
  local ok, install = pcall(require, "nvim-treesitter.install")
  if ok then
    install.compilers = { "clang", "gcc" }
  end
end

function M.treesitter_cli_works()
  if vim.fn.executable("tree-sitter") ~= 1 then
    return false, "tree-sitter CLI is not in $PATH"
  end

  local result = vim.system({ "tree-sitter", "--version" }, { text = true }):wait()
  if result.code ~= 0 then
    local detail = (result.stderr ~= "" and result.stderr)
      or (result.stdout ~= "" and result.stdout)
      or "tree-sitter --version failed"
    return false, detail:gsub("%s+$", "")
  end

  return true
end

function M.get_lang(bufnr, lang)
  if lang then
    return lang
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  if filetype == "" then
    return nil
  end

  return vim.treesitter.language.get_lang(filetype)
end

function M.get_known_parsers()
  if M._known_parsers then
    return M._known_parsers
  end

  local ts = get_ts()
  if not ts or type(ts.get_available) ~= "function" then
    M._known_parsers = {}
    return M._known_parsers
  end

  local known = {}
  for _, parser in ipairs(ts.get_available()) do
    known[parser] = true
  end

  M._known_parsers = known
  return known
end

function M.parser_is_known(lang)
  return lang ~= nil and M.get_known_parsers()[lang] == true
end

function M.parser_is_installed(lang)
  if not lang then
    return false
  end

  local ts = get_ts()
  if not ts or type(ts.get_installed) ~= "function" then
    return false
  end

  return vim.tbl_contains(ts.get_installed("parsers"), lang)
end

local function should_keep_regex_syntax(bufnr, opts, lang)
  local highlight = opts and opts.highlight or {}
  local keep = highlight.additional_vim_regex_highlighting or {}
  local filetype = vim.bo[bufnr].filetype

  return vim.tbl_contains(keep, filetype) or vim.tbl_contains(keep, lang)
end

local function should_enable_indent(bufnr, opts, lang)
  local indent = opts and opts.indent or {}
  if not indent.enable then
    return false
  end

  local filetype = vim.bo[bufnr].filetype
  local disabled = indent.disable or {}
  return not (vim.tbl_contains(disabled, filetype) or vim.tbl_contains(disabled, lang))
end

function M.start(bufnr, opts, lang)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  lang = M.get_lang(bufnr, lang)
  if not lang then
    return false
  end

  if not M.parser_is_installed(lang) then
    return false, lang
  end

  local ok_add = pcall(vim.treesitter.language.add, lang)
  if not ok_add then
    return false, lang
  end

  pcall(vim.treesitter.start, bufnr, lang)

  if should_keep_regex_syntax(bufnr, opts or {}, lang) then
    vim.bo[bufnr].syntax = "ON"
  end

  if should_enable_indent(bufnr, opts or {}, lang) then
    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end

  return true, lang
end

function M.stop(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  pcall(vim.treesitter.stop, bufnr)
end

function M.set_highlight_enabled(bufnr, enabled, opts, lang)
  if enabled then
    return M.start(bufnr, opts, lang)
  end

  M.stop(bufnr)
  return true, lang
end

function M.install_parsers(languages, opts, on_done)
  local ts = get_ts()
  if not ts or type(ts.install) ~= "function" then
    return false
  end

  local targets = vim.tbl_filter(function(lang)
    return M.parser_is_known(lang)
      and not M.pending_installs[lang]
      and not M.parser_is_installed(lang)
  end, languages or {})

  if #targets == 0 then
    return false
  end

  local cli_ok, cli_err = M.treesitter_cli_works()
  if not cli_ok then
    vim.schedule(function()
      vim.notify_once(
        "nvim-treesitter (main) skipped parser install: "
          .. cli_err
          .. " | target parsers: "
          .. table.concat(targets, ", "),
        vim.log.levels.WARN
      )
    end)
    return false
  end

  for _, lang in ipairs(targets) do
    M.pending_installs[lang] = true
  end

  ts.install(targets, { summary = true }):await(function()
    for _, lang in ipairs(targets) do
      M.pending_installs[lang] = nil
    end

    if on_done then
      on_done(targets)
    end
  end)

  return true
end

function M.ensure_parser_for_buffer(bufnr, opts, on_done)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = M.get_lang(bufnr)
  if not lang or M.pending_installs[lang] or not M.parser_is_known(lang) or M.parser_is_installed(lang) then
    return false
  end

  return M.install_parsers({ lang }, opts, function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      M.start(bufnr, opts, lang)
    end
    if on_done then
      on_done(lang)
    end
  end)
end

function M.setup_plugin(opts)
  opts = vim.deepcopy(opts or {})
  local ts = get_ts()
  if ts and type(ts.setup) == "function" then
    ts.setup({ install_dir = opts.install_dir })
  end

  local group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      local started, lang = M.start(args.buf, opts)
      if opts.auto_install and not started and lang then
        M.ensure_parser_for_buffer(args.buf, opts)
      end
    end,
  })

  local baseline = vim.tbl_filter(function(lang)
    return M.parser_is_known(lang) and not M.parser_is_installed(lang)
  end, opts.ensure_installed or {})

  M.install_parsers(baseline, opts, function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      local buftype = vim.bo[buf].buftype
      if name ~= "" and (buftype == "" or buftype == "help") then
        M.start(buf, opts)
      end
    end
  end)

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    local buftype = vim.bo[buf].buftype
    if name ~= "" and (buftype == "" or buftype == "help") then
      local started, lang = M.start(buf, opts)
      if opts.auto_install and not started and lang then
        M.ensure_parser_for_buffer(buf, opts)
      end
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "FileOpened",
  callback = function()
    M.set_compilers()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "mysql",
  callback = function(args)
    M.start(args.buf, { highlight = { additional_vim_regex_highlighting = {} }, indent = { enable = false } }, "sql")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql" },
  once = true,
  callback = function()
    local ft = require("Comment.ft")
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

return M
