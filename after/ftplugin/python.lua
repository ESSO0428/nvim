vim.opt_local.foldmarker = "#region,#endregion"

local ft = vim.bo.filetype
local marker = Nvim.builtin.FtFoldMarker[ft]
if marker and type(marker) == "string" and marker:find(",") then
  vim.opt_local.foldmarker = marker
end

if vim.b.CURRENT_REPL == nil then
  vim.b.CURRENT_REPL = "REPL:default"
  vim.keymap.set('n', '[w', ':norm strah<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']w', ':norm strih<cr>', { buffer = true, silent = true })
  -- NOTE: str is iron.nvim command to send current line to repl
  -- And then in visual mode is send selected lines
  vim.keymap.set('n', '[r', ':norm stR<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']r', ':norm stR<cr>', { buffer = true, silent = true })
  -- NOTE: stf is iron.nvim command to send current file to repl
  vim.keymap.set('n', '[R', ':norm stf<cr>', { buffer = true, silent = true })
  vim.keymap.set('n', ']R', ':norm stf<cr>', { buffer = true, silent = true })
  vim.keymap.set('v', '[w', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', ']w', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', '[r', 'str', { buffer = true, remap = true, silent = true })
  vim.keymap.set('v', ']r', 'str', { buffer = true, remap = true, silent = true })
end
