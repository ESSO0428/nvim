local M = {}

local function apply_neo_tree_transparency()
  vim.cmd "hi NeoTreeNormal ctermbg=none guibg=none"
  vim.cmd "hi NeoTreeNormalNC ctermbg=none guibg=none"
end

M.setup = function()
  local group = vim.api.nvim_create_augroup("UserTransparency", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = "neo-tree",
    callback = function()
      apply_neo_tree_transparency()
    end,
  })
end

M.setup()

return M
