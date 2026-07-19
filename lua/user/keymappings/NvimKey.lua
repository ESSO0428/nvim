-- import the integrated WindowsTerminal module
local windows_terminal = require("user.integrated.WindowsTerminal")


-- Nvim.keys.normal_mode["<a-q>"] = { "<cmd>copen<cr>" }
Nvim.keys.normal_mode["<a-q>"] = { "<cmd>copen<cr>", { desc = "Open Quickfix" } }
Nvim.keys.normal_mode["<c-q>"] = { Nvim.Quickfix.toggle_quickfix_safety, { desc = "Toggle Quickfix at bottom-right" } }
Nvim.keys.normal_mode["[q"] = { "<cmd>cprev<cr>" }
Nvim.keys.normal_mode["]q"] = { "<cmd>cnext<cr>" }

local function wrap_filetree_for_dapui(fn)
  return function(...)
    if _G.Nvim and Nvim.DAPUI and type(Nvim.DAPUI.with_layout_handling_when_dapui_open) == "function" then
      return Nvim.DAPUI.with_layout_handling_when_dapui_open(fn)(...)
    end
    return fn(nil, nil, ...)
  end
end

local function filetree_reveal_core()
  vim.cmd("Neotree reveal_force_cwd")
end

local function filetree_toggle_core()
  vim.cmd("Neotree toggle reveal_force_cwd")
end

Nvim.keys.normal_mode["<c-k>"] = { wrap_filetree_for_dapui(filetree_reveal_core), { desc = "Neo-tree: reveal" } }

--[[ -- lvim core command <c-q>
vim.cmd [[
  function! QuickFixToggle()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
      copen
    else
      cclose
    endif
  endfunction
]]
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', 'zc', function()
      vim.cmd("cclose")
      vim.fn.setqflist({}, "r")
      Nvim.Quickfix.open_quickfix_safety()
    end, { buffer = true, silent = true })
  end
})

-- disable vim-move overwrite keys since it conflicts with other keybindings
vim.g.move_map_keys = 0

Nvim.keys.insert_mode["<a-j>"] = "<ESC>"

Nvim.keys.visual_block_mode["<leader>/"] = { "<Plug>(comment_toggle_linewise_visual)",
  { desc = "Comment toggle linewise (visual)" } }

Nvim.keys.normal_mode["<leader>/"] = { "<Plug>(comment_toggle_linewise_current)",
  { desc = "Comment toggle current line" } }

Nvim.keys.normal_mode["<leader>e"] = { wrap_filetree_for_dapui(filetree_toggle_core), { desc = "Neo-tree: toggle" } }

Nvim.keys.normal_mode["<leader><a-1>"] = { "<cmd>exe v:count1 . 'ToggleTerm direction=horizontal'<cr>",
  { desc = "Horizontal Terminal" } }


Nvim.keys.normal_mode['<leader>rc'] = "<cmd>e " .. vim.fn.stdpath("config") .. "/lua/config.lua<cr>"
Nvim.keys.normal_mode['<leader>rb'] = "<cmd>e $HOME/.bashrc<cr>"

-- bind the function to the <leader>rw keybinding
Nvim.keys.normal_mode['<leader>rw'] = windows_terminal.find_and_edit_terminal_settings


Nvim.keys.normal_mode['<leader>rt'] = "<cmd>ToggleTermSendCurrentLine<cr>"
Nvim.keys.visual_mode['<leader>rt'] = { ":ToggleTermSendVisualLines", { silent = false } }

Nvim.keys.normal_mode["<leader>w"] = "viw"
Nvim.keys.normal_mode["<leader>y"] = "yiw"

Nvim.keys.normal_mode['<leader>i'] = "<cmd>wincmd k<cr>"
Nvim.keys.normal_mode['<leader>k'] = "<cmd>wincmd j<cr>"
Nvim.keys.normal_mode['<leader>j'] = "<cmd>wincmd h<cr>"
Nvim.keys.normal_mode['<leader>l'] = "<cmd>wincmd l<cr>"
Nvim.keys.normal_mode['<leader>J'] = "<cmd>wincmd t<cr>"
Nvim.keys.normal_mode["<leader>L"] = "<cmd>wincmd b<cr>"
Nvim.keys.normal_mode['sJ']        = "<cmd>wincmd H<cr>"
Nvim.keys.normal_mode['sL']        = "<cmd>wincmd L<cr>"
Nvim.keys.normal_mode['sI']        = "<cmd>wincmd K<cr>"
Nvim.keys.normal_mode['sK']        = "<cmd>wincmd J<cr>"
Nvim.keys.normal_mode['sT']        = "<cmd>wincmd T<cr>"

Nvim.keys.normal_mode['<leader><cr>'] = "<cmd>nohlsearch<cr>"

-- require vim-peekaboo
Nvim.keys.normal_mode['<c-f>']         = "<cmd>Telescope current_buffer_fuzzy_find<cr>"
Nvim.keys.normal_mode['<leader><c-f>'] = "<cmd>lua require('telescope.builtin').live_grep({grep_open_files=true})<cr>"
Nvim.keys.normal_mode['<c-d>']         = "\"dyy\"dp"
Nvim.keys.normal_mode['<a-L>']         = "<Plug>(VM-Select-All)"
Nvim.keys.visual_mode['<a-L>']         = "<Plug>(VM-Visual-All)"

Nvim.keys.normal_mode['<a-up>']   = "<Plug>MoveLineUp"
Nvim.keys.normal_mode['<a-down>'] = "<Plug>MoveLineDown"

Nvim.keys.normal_mode['<c-u>'] = "<c-b>"
Nvim.keys.normal_mode['<c-o>'] = "<c-f>"


vim.keymap.set('v', '<a-up>',
  function()
    if vim.fn.mode() == "v" then return "<Plug>MoveBlockUp" else return "<Plug>SchleppUp" end
  end, { expr = true, silent = true }
)
vim.keymap.set('v', '<a-down>',
  function()
    if vim.fn.mode() == "v" then return "<Plug>MoveBlockDown" else return "<Plug>SchleppDown" end
  end, { expr = true, silent = true }
)
vim.keymap.set('v', '<a-left>',
  function()
    if vim.fn.mode() == "v" then return "<Plug>MoveBlockLeft" else return "<Plug>SchleppLeft" end
  end, { expr = true, silent = true }
)
vim.keymap.set('v', '<a-right>',
  function()
    if vim.fn.mode() == "v" then return "<Plug>MoveBlockRight" else return "<Plug>SchleppRight" end
  end, { expr = true, silent = true }
)
Nvim.keys.visual_block_mode["<A-j>"] = ":m '>+1<CR>gv-gv"
Nvim.keys.visual_block_mode["<A-k>"] = ":m '<-2<CR>gv-gv"


Nvim.keys.normal_mode["<leader>S"] = { ":SessionManager save_current_session<cr>", { silent = false } }

Nvim.keys.normal_mode["<a-'>"] = "<cmd>tab split<cr>"
Nvim.keys.normal_mode["<a-/>"] = "<cmd>tabn 1<cr>"
Nvim.keys.normal_mode["<a-,>"] = "<cmd>tabprevious<cr>"
Nvim.keys.normal_mode["<a-.>"] = "<cmd>tabnext<cr>"

Nvim.keys.normal_mode["<C-Left>"]  = "<cmd>tabmove -1<cr>"
Nvim.keys.normal_mode["<C-Right>"] = "<cmd>tabmove +1<cr>"
Nvim.keys.normal_mode["<a-\\>"]    = "<cmd>tabclose<cr>"

Nvim.keys.normal_mode["<leader>["]  = "<cmd>cprevious<cr>"
Nvim.keys.normal_mode["<leader>]"]  = "<cmd>cnext<cr>"
Nvim.keys.normal_mode["ga"]         = "<cmd>TSJToggle<cr>"
Nvim.keys.normal_mode["+"]          = "<cmd>lua require('harpoon.ui').nav_next()<cr>"
Nvim.keys.normal_mode["_"]          = "<cmd>lua require('harpoon.ui').nav_prev()<cr>"
Nvim.keys.normal_mode["="]          = "<cmd>Telescope harpoon marks<cr>"
Nvim.keys.normal_mode["mf"]         = "<cmd>lua require('harpoon.mark').add_file()<cr>"
Nvim.keys.normal_mode["mw"]         = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>"
Nvim.keys.normal_mode["sq"]         = "<Cmd>FloatIntoCurrent<CR>"
Nvim.keys.normal_mode["<leader>de"] = "<cmd>DBUIToggle<cr>"
Nvim.keys.normal_mode["<leader>dE"] = "<cmd>tab DBUI<cr>"

Nvim.keys.normal_mode["<C-j>"] = "<cmd>BufferLineCyclePrev<cr>"
Nvim.keys.normal_mode["<C-l>"] = "<cmd>BufferLineCycleNext<cr>"
Nvim.keys.normal_mode["<a-j>"] = "<cmd>BufferLineMovePrev<cr>"
Nvim.keys.normal_mode["<a-l>"] = "<cmd>BufferLineMoveNext<cr>"
Nvim.keys.normal_mode["<a-k>"] = "<c-d>"

Nvim.keys.normal_mode["<a-i>"] = "<c-u>"

Nvim.keys.normal_mode["<a-g>"]         = { ":BufferLineGroupToggle ", { silent = false } }
Nvim.keys.normal_mode["<leader><a-g>"] = { ":BufferLineGroupClose ", { silent = false } }
Nvim.keys.normal_mode["<leader><a-i>"] = "<cmd>BufferLineTogglePin<cr>"
-- Nvim.keys.normal_mode["<c-w>"]         = { "<cmd>BufferKill<cr>", { nowait = true }}
-- Nvim.keys.normal_mode["<c-w>"]         = { "<cmd>BufferLineCyclePrev<cr><cmd>confirm bd#<cr>", { nowait = true }}
Nvim.keys.normal_mode["<c-w>"]         = { "<cmd>BufferLineKill<cr>", { nowait = true } }

Nvim.keys.normal_mode["<leader><c-w>"]  = "<cmd>ForceBufferLineKill<cr>"
-- NOTE: 直接使用 bd! 強制關閉緩衝區
Nvim.keys.normal_mode["<leader>d<c-w>"] = "<cmd>bd!<cr>"

Nvim.keys.normal_mode["gy"]    = "<cmd>let @+ = expand('%:p')<cr>"
Nvim.keys.normal_mode["<a-1>"] = "<cmd>BufferLineGoToBuffer 1<cr>"
Nvim.keys.normal_mode["<a-2>"] = "<cmd>BufferLineGoToBuffer 2<cr>"
Nvim.keys.normal_mode["<a-3>"] = "<cmd>BufferLineGoToBuffer 3<cr>"
Nvim.keys.normal_mode["<a-4>"] = "<cmd>BufferLineGoToBuffer 4<cr>"
Nvim.keys.normal_mode["<a-5>"] = "<cmd>BufferLineGoTOBuffer 5<cr>"
Nvim.keys.normal_mode["<a-6>"] = "<cmd>BufferLineGoToBuffer 6<cr>"
Nvim.keys.normal_mode["<a-7>"] = "<cmd>BufferLineGoToBuffer 7<cr>"
Nvim.keys.normal_mode["<a-8>"] = "<cmd>BufferLineGoToBuffer 8<cr>"
Nvim.keys.normal_mode["<a-9>"] = "<cmd>BufferLineGoToBuffer 9<cr>"
Nvim.keys.normal_mode["<a-0>"] = "<cmd>BufferLineGoToBuffer -1<cr>"
Nvim.keys.normal_mode["<a-`>"] = "<cmd>b#<cr>"
-- -- Use which-key to add extra bindings with the leader-key prefix
-- Nvim.builtin.which_key.mappings["W"] = { "<cmd>noautocmd w<cr>", "Save without formatting" }
-- Nvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<cr>", "Projects" }

Nvim.keys.normal_mode["<A-BS>"]          = "<cmd>cd ../<cr>"
Nvim.keys.normal_mode["<leader><A-BS>"]  = "<cmd>cd %:p:h <cr>"
Nvim.keys.normal_mode["<leader>r<A-BS>"] = "<cmd>execute ':cd ' . g:WorkDirectoryPath<cr>"
Nvim.keys.normal_mode['<leader>se']      = { '<cmd>SessionManager load_session<cr>' }

Nvim.keys.normal_mode["<M-n>"]      = { "<cmd>lua require('illuminate').goto_next_reference(wrap)<cr>" }
Nvim.keys.normal_mode["<M-N>"]      = { "<cmd>lua require('illuminate').goto_prev_reference(wrap)<cr>" }
Nvim.keys.normal_mode["me"]         = { "<cmd>lua Nvim.Buffer_Manager.scratch_opener.open_scratch()<cr>" }
Nvim.keys.visual_mode["<"]          = "<gv"
Nvim.keys.visual_mode[">"]          = ">gv"
Nvim.keys.normal_mode["<leader>ta"] = { ":Limelight<cr>", { silent = false } }
Nvim.keys.normal_mode["<leader>tA"] = { ":Limelight!<cr>", { silent = false } }
Nvim.keys.visual_mode["<leader>ta"] = { "<Plug>(Limelight)", { silent = false } }
Nvim.keys.normal_mode["sgh"]        = { function() require("hoversplit").split_remain_focused() end }

-- debug
Nvim.keys.normal_mode["]d"] = { "<cmd>lua require('goto-breakpoints').next()<cr>" }
Nvim.keys.normal_mode["[d"] = { "<cmd>lua require('goto-breakpoints').prev()<cr>" }
Nvim.keys.normal_mode["]S"] = { "<cmd>lua require('goto-breakpoints').stopped()<cr>" }

Nvim.keys.normal_mode['<leader>\\'] = { "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>" }
Nvim.keys.visual_mode["<leader>dv"] = { "<cmd>lua require('dapui').eval()<cr>" }
Nvim.keys.normal_mode["gH"]         = { "<cmd>lua require('dapui').eval()<cr>" }
Nvim.keys.visual_mode["gH"]         = { "<cmd>lua require('dapui').eval()<cr>" }
Nvim.keys.normal_mode["<F5>"]       = { "<cmd>lua require('dap').continue()<cr>" }
Nvim.keys.normal_mode["<F17>"]      = { "<cmd>lua require('dap').close()<cr>" }
Nvim.keys.normal_mode["<F8>"]       = { "<cmd>lua require'dap'.step_into()<cr>" }

-- Shift + F8
Nvim.keys.normal_mode["<F20>"] = { "<cmd>lua require'dap'.step_over()<cr>" }
Nvim.keys.normal_mode["<F6>"]  = { "<cmd>lua require'dap'.step_out()<cr>" }

vim.cmd('noremap <a-p> <Nop>')
Nvim.keys.insert_mode["<a-u>"] = { "<Esc>:m .-2<cr>==gi" }
Nvim.keys.insert_mode["<a-o>"] = { "<Esc>:m .+1<cr>==gi" }


-- DiffTool
Nvim.keys.normal_mode["cv"] = { "<cmd>ConflictDiff<cr>", { desc = "Compare Conflict" } }
Nvim.keys.normal_mode["cp"] = { "<cmd>ConflictAllDiff<cr>", { desc = "Compare Conflict (All Buffer)" } }

-- Undo
Nvim.keys.normal_mode["Z"] = { "<cmd>UndotreeToggle<cr>", { desc = "Toggle undo tree" } }

-- fold
Nvim.keys.normal_mode['<leader>o'] = { "za", desc = { "Folding Code (Toggle)" } }
Nvim.keys.visual_mode['<leader>o'] = "zA<ESC>"
Nvim.keys.visual_mode['<leader>Oa'] = "zC"
Nvim.keys.visual_mode['<leader>Od'] = "zO"

-- Repl
Nvim.keys.normal_mode["'q"] = { "<cmd>RunQtConsole<cr>gg", { desc = "Run QtConsole" } }
Nvim.keys.normal_mode["\\E"] = { "<cmd>IronRepl<cr>", { desc = "Open REPL" } }
Nvim.keys.normal_mode["\\w"] = { "<cmd>IPython --existing --no-window<cr><Plug>(IPy-RunCell)", { desc = "Run Cell" } }
Nvim.keys.normal_mode["\\e"] = { "<cmd>IPython --existing --no-window<cr><Plug>(IPy-RunAll)", { desc = "Run All" } }

Nvim.keys.normal_mode["[w"] = { "strah", { desc = "Send Line Above" } }
Nvim.keys.normal_mode["]w"] = { "stR", { desc = "Send Line Below" } }
Nvim.keys.normal_mode["[r"] = { "stR", { desc = "Send Line Above" } }
Nvim.keys.normal_mode["]r"] = { "stR", { desc = "Send Line Below" } }
Nvim.keys.normal_mode["[R"] = { "stR", { desc = "Send Line Above" } }
Nvim.keys.normal_mode["]R"] = { "stR", { desc = "Send Line Below" } }
Nvim.keys.visual_mode["[w"] = { "str", { desc = "Send Selection Above" } }
Nvim.keys.visual_mode["]w"] = { "str", { desc = "Send Selection Below" } }
Nvim.keys.visual_mode["[r"] = { "str", { desc = "Send Selection Above" } }
Nvim.keys.visual_mode["]r"] = { "str", { desc = "Send Selection Below" } }
