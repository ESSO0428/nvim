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

function M.find_git_ancestor_or_root(bufnr, markers)
  return M.get_root(bufnr, { ".git" }) or M.get_root(bufnr, markers)
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

M.utils_exclude = {
  ".git",
  ".jj",
  ".github",
  ".gitlab",

  ".direnv",
  ".venv",
  "venv",
  ".env",
  "env",

  "node_modules",

  "__pycache__",
  ".pytest_cache",
  ".mypy_cache",
  ".ruff_cache",
  ".tox",
  ".nox",
  ".ipynb_checkpoints",

  "build",
  "dist",
  "target",

  "logs",
  "tmp",
  "temp",

  "data",
  "datasets",
  "outputs",
  "results",
  "checkpoints",
  "weights",
  "images",
  "imgs",
  "crops",
  "features",

  "artifacts",
  "cache",
  ".cache",
}

-- cache，只計算一次
local lsp_exclude_cache = {}

local function gitignore_to_lsp_pattern(line)
  line = vim.trim(line)

  if line == "" or line:match("^#") or line:match("^!") then
    return nil
  end

  line = line:gsub("/$", "")

  -- 已經明確指定 recursive glob
  -- **/outputs/ -> **/outputs
  if line:match("^%*%*/") then
    return line
  end

  -- root-relative
  -- /outputs/   -> outputs
  -- /*outputs/  -> *outputs
  if line:sub(1, 1) == "/" then
    return line:sub(2)
  end

  -- pattern 本身已有路徑
  -- foo/bar/ -> foo/bar
  if line:find("/", 1, true) then
    return line
  end

  -- 沒有 slash 才代表任意深度
  -- outputs/ -> **/outputs
  -- *.pth    -> **/*.pth
  return "**/" .. line
end

local function get_git_root()
  local result = vim.system({
    "git",
    "-C",
    vim.fn.getcwd(),
    "rev-parse",
    "--show-toplevel",
  }, { text = true }):wait()

  if result.code ~= 0 then
    return nil
  end

  return vim.trim(result.stdout)
end

function M.get_lsp_exclude()
  local root = get_git_root()
  local cache_key = root or "__global__"

  if lsp_exclude_cache[cache_key] then
    return lsp_exclude_cache[cache_key]
  end

  local excludes = vim.tbl_map(function(path)
    return "**/" .. path
  end, M.utils_exclude)

  if root then
    local gitignore = root .. "/.gitignore"

    if vim.fn.filereadable(gitignore) == 1 then
      for _, line in ipairs(vim.fn.readfile(gitignore)) do
        local pattern = gitignore_to_lsp_pattern(line)

        if pattern then
          table.insert(excludes, pattern)
        end
      end
    end
  end

  lsp_exclude_cache[cache_key] = vim.fn.uniq(vim.fn.sort(excludes))
  return lsp_exclude_cache[cache_key]
end

-- 哪些 LSP / language species 使用 glob-style exclude
local lsp_species_exclude = {
  python = true,
}

function M.lsp_register_species_exclude(species)
  return lsp_species_exclude[species]
      and M.get_lsp_exclude()
      or M.utils_exclude
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
