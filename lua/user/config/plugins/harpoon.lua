local M = {}

local uv = vim.uv or vim.loop
local path_sep = package.config:sub(1, 1)

local function path_join(...)
  return table.concat({ ... }, path_sep)
end

local function copy_file(src, dst)
  local parent = vim.fs.dirname(dst)
  if parent and parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end

  if uv.fs_stat(dst) then
    uv.fs_unlink(dst)
  end

  local ok = pcall(uv.fs_copyfile, src, dst)
  return ok and uv.fs_stat(dst) ~= nil
end

local function sync_harpoon_storage()
  local selected_file = vim.fs.normalize(Nvim.paths.harpoon_file)
  local runtime_file = vim.fs.normalize(path_join(vim.fn.stdpath("data"), "harpoon.json"))

  if selected_file == runtime_file then
    return
  end

  local selected_exists = uv.fs_stat(selected_file) ~= nil
  local runtime_exists = uv.fs_stat(runtime_file) ~= nil

  if selected_exists then
    copy_file(selected_file, runtime_file)
  elseif runtime_exists then
    copy_file(runtime_file, selected_file)
  end

  local group = vim.api.nvim_create_augroup("user_harpoon_path_sync", { clear = true })
  local function sync_back()
    if uv.fs_stat(runtime_file) then
      copy_file(runtime_file, selected_file)
    end
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "VimLeavePre" }, {
    group = group,
    callback = sync_back,
    desc = "Sync Harpoon data back to the selected path profile",
  })
end

function M.setup(opts)
  sync_harpoon_storage()
  require("harpoon").setup(opts or {})
end

return M
