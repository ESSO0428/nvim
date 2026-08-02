-- FlowMkdn is now a pure local integration layer.
-- Nvim.MarkDownTool defaults live in `lua/user/builtin/utils.lua`.

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('flow_mkdn_markdown_keymap', { clear = true }),
  callback = function()
    vim.keymap.set('n', '<leader>uv', ':MarkdownHeadersClosest<cr>', { silent = true, buffer = true })
    vim.keymap.set('n', '<a-o>', function()
      Nvim.MarkDownTool.open_link('cfile')
    end, { silent = true, buffer = true })
    vim.keymap.set('n', 'gS', function()
      return Nvim.MarkDownTool.toggle_checkbox()
    end, { silent = true, buffer = true, desc = 'Toggle markdown checkbox' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'Avante*', 'copilot-chat' },
  group = vim.api.nvim_create_augroup('flow_mkdn_ai_chat_keymap', { clear = true }),
  callback = function()
    vim.keymap.set('n', '<a-o>', function()
      Nvim.MarkDownTool.open_link('cfile')
    end, { buffer = true, desc = 'Open file under cursor (cfile) in picked window' })
    vim.keymap.set('v', '<a-o>', ":<C-u>call v:lua.Nvim.MarkDownTool.open_link('visual')<cr>",
      { silent = true, buffer = true, desc = 'Open file under cursor (visual) in picked window' })
    vim.keymap.set('n', 'gh', function()
      Nvim.MarkDownTool.open_link('float')
    end, { buffer = true, desc = 'Open file under cursor (cfile) in float window' })
    vim.keymap.set('v', 'gh', ":<C-u>call v:lua.Nvim.MarkDownTool.open_link('float_visual')<cr>",
      { silent = true, buffer = true, desc = 'Open file under cursor (visual) in float window' })
    vim.keymap.set('n', 'g;', function()
      Nvim.MarkDownTool.open_link('cline')
    end, { buffer = true, desc = 'Open file under cursor (cline) in picked window' })
    vim.keymap.set('n', 'gp', function()
      Nvim.MarkDownTool.open_link('float_cline')
    end, { buffer = true, desc = 'Open file under cursor (cline) in float window' })
  end,
})

vim.api.nvim_create_user_command('Date', 'silent! r! date +"\\%A, \\%B, \\%d, \\%Y"', { nargs = '*' })

return {}
