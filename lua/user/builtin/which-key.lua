Nvim.which_key = {}
Nvim.which_key = Nvim.which_key or {}

local M = {}

function M.load(keymaps)
  local wk = require "which-key"
  wk.add(keymaps)
end

return M
