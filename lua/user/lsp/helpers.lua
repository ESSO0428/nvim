local M = {}

function M.get_json_schemas()
  local ok, schemastore = pcall(require, "schemastore")
  if ok and schemastore.json and type(schemastore.json.schemas) == "function" then
    return schemastore.json.schemas()
  end

  return {}
end

function M.get_yaml_schemas()
  local ok, schemastore = pcall(require, "schemastore")
  if ok and schemastore.yaml and type(schemastore.yaml.schemas) == "function" then
    return schemastore.yaml.schemas()
  end

  return {}
end

function M.get_root(bufnr, markers)
  return vim.fs.root(bufnr, markers)
end

function M.buffer_dir(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == nil or fname == "" then
    return vim.uv.cwd()
  end

  return vim.fs.dirname(fname)
end

function M.find_git_ancestor_or_root(bufnr, markers)
  return M.get_root(bufnr, { ".git" }) or M.get_root(bufnr, markers)
end

function M.project_root_markers()
  return {
    ".git",
    "_darcs",
    ".hg",
    ".bzr",
    ".svn",
    "Makefile",
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "Cargo.toml",
    "go.mod",
    "composer.json",
    "pom.xml",
    "mix.exs",
    "mkdocs.yml",
    "mkdocs.yaml",
  }
end

function M.project_root_or_buffer_dir(bufnr, extra_markers)
  local markers = M.project_root_markers()
  if extra_markers and #extra_markers > 0 then
    vim.list_extend(markers, extra_markers)
  end

  return M.get_root(bufnr, markers) or M.buffer_dir(bufnr)
end

function M.marksman_root_dir(bufnr, on_dir)
  on_dir(M.project_root_or_buffer_dir(bufnr))
end

function M.python_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  }

  local root = vim.fs.root(fname, markers)
  local excluded_paths = {
    vim.uv.os_homedir(),
    "/",
    "/tmp",
  }

  local function is_excluded(dir)
    if not dir then
      return false
    end

    dir = vim.fs.normalize(dir)
    for _, excluded in ipairs(excluded_paths) do
      if dir == vim.fs.normalize(excluded) then
        return true
      end
    end

    return false
  end

  if root and not is_excluded(root) then
    on_dir(root)
    return
  end

  on_dir(nil)
end

function M.php_root_dir(bufnr, on_dir)
  on_dir(M.find_git_ancestor_or_root(bufnr, { "composer.json", "index.php", "requirements.txt" }))
end

function M.filtered_typescript_definition(_, result, ctx)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end

  local client = ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id) or nil
  local offset_encoding = client and client.offset_encoding or "utf-16"
  local nodejs_pattern1 = "node_modules/@types/.*/index.d.ts"
  local nodejs_pattern2 = "node_modules/%%40types/.*/index.d.ts"

  if vim.islist(result) then
    if #result == 1 then
      vim.lsp.util.jump_to_location(result[1], offset_encoding)
      return nil
    end

    local filtered_result = {}
    for _, value in pairs(result) do
      local uri = value.targetUri or value.uri
      if not (string.match(uri, nodejs_pattern1) or string.match(uri, nodejs_pattern2)) then
        table.insert(filtered_result, value)
      end
    end

    if #filtered_result == 1 then
      vim.lsp.util.jump_to_location(filtered_result[1], offset_encoding)
    elseif #filtered_result > 1 then
      local items = vim.lsp.util.locations_to_items(filtered_result, offset_encoding)
      vim.fn.setqflist({}, " ", { items = items })
      vim.cmd("copen")
    end

    return nil
  end

  vim.lsp.util.jump_to_location(result, offset_encoding)
  return nil
end

function M.get_inlay_hint_settings()
  return {
    includeInlayParameterNameHints = "all",
    includeInlayParameterNameHintsWhenArgumentMatchesName = true,
    includeInlayFunctionParameterTypeHints = true,
    includeInlayVariableTypeHints = true,
    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
    includeInlayPropertyDeclarationTypeHints = true,
    includeInlayFunctionLikeReturnTypeHints = true,
    includeInlayEnumMemberValueHints = true,
  }
end

return M
