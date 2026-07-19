-- setup lunar colorscheme
require("user.core.lunar").setup()

-- Match the old LunarVim Limelight dim color and provide a cterm fallback.
vim.g.limelight_conceal_guifg = "#545763"
vim.g.limelight_conceal_ctermfg = 59

local function set_if_command_exists(cmd, value)
  pcall(vim.cmd, cmd .. " " .. value)
end

set_if_command_exists("GuiWindowOpacity", "0.9")

local transparent_highlights = {
  "Normal",
  "NormalNC",
  "LineNr",
  "Folded",
  "NonText",
  "SpecialKey",
  "VertSplit",
  "SignColumn",
  "EndOfBuffer",
  "TablineFill", -- this might be preference
}

for _, hl in ipairs(transparent_highlights) do
  vim.cmd.highlight(hl .. " guibg=NONE ctermbg=NONE")
end

-- transparent window
vim.cmd "hi Normal ctermbg=none guibg=none"
vim.cmd "hi SignColumn ctermbg=none guibg=none"
vim.cmd "hi WinBarNC cterm=bold guifg=NvimLightGrey4 guibg=none"
vim.cmd "exec 'hi FoldColumn guibg=none guifg=' . synIDattr(synIDtrans(hlID('Folded')), 'fg', 'gui')"
vim.cmd "hi NormalNC ctermbg=none guibg=none"
vim.cmd "hi MsgArea ctermbg=none guibg=none"
vim.cmd "hi TelescopeNormal ctermbg=none guibg=none"
vim.cmd "hi NormalFloat ctermbg=none guibg=none"
vim.cmd "hi FloatBorder ctermbg=none guibg=none guifg=#3d59a1"
vim.cmd "hi Float ctermbg=none guibg=none"
vim.cmd "hi NvimFloat ctermbg=none guibg=none"
vim.cmd "hi WhichKeyFloat ctermbg=none guibg=none"
vim.cmd "hi WhichKeyNormal guibg=none"
vim.cmd "hi NvimTreeNormal ctermbg=none guibg=none"
vim.cmd "hi NvimTreeNormalNC ctermbg=none guibg=none"
-- vim.cmd("hi WinSeparator cterm=bold gui=bold guifg=#000000")
vim.cmd "hi NvimTreeWinSeparator ctermbg=none guibg=none"
vim.cmd "hi Navbuddy ctermbg=none guibg=none"
vim.cmd "hi WindowPickerStatusLine ctermfg=15 guifg=#ededed guibg=#e35e4f"
vim.cmd "hi WindowPickerStatusLineNC ctermfg=15 ctermbg=4 gui=bold guifg=#ededed guibg=#4493c8"
vim.cmd "hi WindowPickerWinBar ctermfg=15 guifg=#ededed guibg=#e35e4f"
vim.cmd "hi WindowPickerWinBarNC ctermfg=15 ctermbg=4 gui=bold guifg=#ededed guibg=#4493c8"
vim.cmd "hi TroubleNormal guibg=none"
vim.cmd "hi BlinkCmpDoc guibg=none"
vim.cmd "hi BlinkCmpMenu guibg=none"
vim.cmd "hi BlinkCmpLabel guibg=none"

-- Utils
vim.cmd "hi @include.python guifg=#c586c0"
vim.cmd "hi pythonInclude guifg=#c586c0"
vim.cmd "hi @keyword.import guifg=#c586c0"
vim.cmd "hi Keyword cterm=italic gui=italic guifg=#9d7cd8"
vim.cmd "hi @Keyword cterm=italic gui=italic guifg=#9d7cd8"
vim.cmd "hi @keyword.import guifg=#c586c0"
vim.cmd "hi link @keyword.operator Keyword"
vim.cmd "hi @variable guifg=#9cdcfe"
vim.cmd "hi @conditional.python guifg=#c586c0"
vim.cmd "hi @exception.python guifg=#c586c0"
vim.cmd "hi @lsp.type.decorator.python guifg=none"
vim.cmd "hi @lsp.type.class.python guifg=#4ec9b0"
vim.cmd "hi link @lsp.type.namespace.python @type.python"
vim.cmd "hi link @lsp.mod.readonly.python Special"
vim.cmd "hi @method.call.python guifg=#daccaa"
vim.cmd "hi @function.method.call.python guifg=#daccaa"
vim.cmd "hi link @lsp.type.function.python @method.call.python"
vim.cmd "hi link @lsp.type.method.python @method.call.python"
vim.cmd "hi link @lsp.type.parameter.python @parameter.python"
vim.cmd "hi @function.python guifg=#daccaa"
vim.cmd "hi @function.call.python guifg=#daccaa"
vim.cmd "hi @field.python guifg=#d19a66"
vim.cmd "hi @boolean.python guifg=#3794FF"
vim.cmd "hi link @constant.builtin.python @boolean.python"
vim.cmd "hi @operator guifg=#ffffff"
vim.cmd "hi @text.reference guifg=#3794ff"
vim.cmd "hi! link @markup.quote Special"
vim.cmd "hi! link @markup.raw.markdown_inline Special"
vim.cmd "hi! link @markup.quote.markdown Special"
vim.cmd "hi! link @markup.raw.block.markdown Special"
vim.cmd "hi CodeBlock guibg=none"
vim.cmd "hi link markdownCodeBlock CodeBlock"
vim.cmd "hi link @markup.raw.block.markdown Special"
vim.cmd "hi link @spell.markdown Normal"
vim.cmd "hi @markup.strong cterm=bold gui=bold guifg=#daccaa"
vim.cmd "hi @punctuation.special.markdown guifg=#9d7cd8"
vim.cmd "hi link @text.title.2 Title"
vim.cmd "hi link @text.title.2.marker Title"
vim.cmd "hi link markdownH2Delimiter Title"
vim.cmd "hi link @text.title.3 Title"
vim.cmd "hi link @text.title.3.marker Title"
vim.cmd "hi link markdownH3Delimiter Title"
vim.cmd "hi link @text.title.4 Title"
vim.cmd "hi link @text.title.4.marker Title"
vim.cmd "hi link markdownH4Delimiter Title"
vim.cmd "hi link @text.title.5 Title"
vim.cmd "hi link @text.title.5.marker Title"
vim.cmd "hi link markdownH5Delimiter Title"
vim.cmd "hi link @text.title.4 Title"
vim.cmd "hi link @text.title.4.marker Title"
vim.cmd "hi link markdownH4Delimiter Title"
vim.cmd "hi @number.python guifg=#b5cea8"
vim.cmd "hi @float.python guifg=#b5cea8"
vim.cmd "hi @string.python guifg=#ce9178"
vim.cmd "hi @parameter.python guifg=#68b2c8"
vim.cmd "hi @field.python guifg=#4ec9b0"
vim.cmd "hi @type.python guifg=#4ec9b0"
vim.cmd "hi @constant.python guifg=#4fceff"
vim.cmd "hi link @string.documentation.python String"
vim.cmd "hi LspInlayHint guifg=#a59669 guibg=#2d2d2d"
vim.cmd "hi TailwindConceal guifg=#38BDF8"

vim.cmd "hi lualine_a_normal guifg=#16161e guibg=#7aa2f7"
vim.cmd "hi lualine_b_normal guifg=#7aa2f7 guibg=#3b4261"
vim.cmd "hi lualine_c_normal guifg=#a9b1d6 guibg=#16161e"
vim.cmd "hi TreesitterContext guibg=#16161e"

local function set_lualine_highlights()
  local statusline_hl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
  local cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })

  vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
  vim.api.nvim_set_hl(0, "CmpItemKindTabnine", { fg = "#CA42F0" })
  vim.api.nvim_set_hl(0, "CmpItemKindCrate", { fg = "#F64D00" })
  vim.api.nvim_set_hl(0, "CmpItemKindEmoji", { fg = "#FDE030" })
  vim.api.nvim_set_hl(0, "SLCopilot", { fg = "#6CC644", bg = statusline_hl.bg })
  vim.api.nvim_set_hl(0, "SLGitIcon", { fg = "#E8AB53", bg = cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "SLBranchName", { fg = normal_hl.fg, bg = cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "SLSeparator", { fg = cursorline_hl.fg, bg = statusline_hl.bg })
end

vim.cmd "hi DapUIBreakpointsCurrentLine gui=bold guifg=#a9ff68"
vim.cmd "hi DapUIBreakpointsDisabledLine guifg=#424242"
vim.cmd "hi DapUIBreakpointsInfo guifg=#a9ff68"
vim.cmd "hi DapUIBreakpointsLine guifg=#00f1f5"
vim.cmd "hi DapUIBreakpointsPath guifg=#00f1f5"
vim.cmd "hi DapUICurrentFrameName gui=bold guifg=#a9ff68"
vim.cmd "hi DapUIDecoration guifg=#00f1f5"
vim.cmd "hi DapUIEndofBuffer guifg=#4f5258"
vim.cmd "hi DapUIFloatBorder guifg=#00f1f5"
vim.cmd "hi DapUIFrameName guifg=#e0e2ea"
vim.cmd "hi DapUILineNumber guifg=#00f1f5"
vim.cmd "hi DapUIModifiedValue gui=bold guifg=#00f1f5"
vim.cmd "hi DapUINormal guifg=#e0e2ea"
vim.cmd "hi DapUINormalNC guifg=#e0e2ea"
vim.cmd "hi DapUIPlayPause guifg=#a9ff68"
vim.cmd "hi DapUIPlayPauseNC guifg=#a9ff68"
vim.cmd "hi DapUIRestart guifg=#a9ff68"
vim.cmd "hi DapUIRestartNC guifg=#a9ff68"
vim.cmd "hi DapUIScope guifg=#00f1f5"
vim.cmd "hi DapUISource guifg=#d484ff"
vim.cmd "hi DapUIStepBack guifg=#00f1f5"
vim.cmd "hi DapUIStepBackNC guifg=#00f1f5"
vim.cmd "hi DapUIStepInto guifg=#00f1f5"
vim.cmd "hi DapUIStepIntoNC guifg=#00f1f5"
vim.cmd "hi DapUIStepOut guifg=#00f1f5"
vim.cmd "hi DapUIStepOutNC guifg=#00f1f5"
vim.cmd "hi DapUIStepOver guifg=#00f1f5"
vim.cmd "hi DapUIStepOverNC guifg=#00f1f5"
vim.cmd "hi DapUIStop guifg=#f70067"
vim.cmd "hi DapUIStopNC guifg=#f70067"
vim.cmd "hi DapUIStoppedThread guifg=#00f1f5"
vim.cmd "hi DapUIThread guifg=#a9ff68"
vim.cmd "hi DapUIType guifg=#d484ff"
vim.cmd "hi DapUIUnavailable guifg=#424242"
vim.cmd "hi DapUIUnavailableNC guifg=#424242"
vim.cmd "hi DapUIValue guifg=#e0e2ea"
vim.cmd "hi DapUIVariable guifg=#e0e2ea"
vim.cmd "hi DapUIWatchesEmpty guifg=#f70067"
vim.cmd "hi DapUIWatchesError guifg=#f70067"
vim.cmd "hi DapUIWatchesValue guifg=#a9ff68"
vim.cmd "hi DapUIWinSelect gui=bold guifg=#00f1f5"

vim.api.nvim_create_augroup("UserLualineColors", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = "UserLualineColors",
  callback = function()
    pcall(set_lualine_highlights)
  end,
})

pcall(set_lualine_highlights)
pcall(set_dapui_highlights)

vim.cmd "hi Folded guifg=#7aa2f7 guibg=#3b4261"
vim.cmd "hi NormalNC ctermbg=none guibg=none"
vim.cmd "hi BufferLineBufferSelected guifg=#3ab6f0"
vim.cmd "hi BufferLineTabSelected guifg=#3ab6f0"
vim.cmd "hi BufferLineNumbersSelected cterm=bold,italic gui=bold,italic guifg=#3ab6f0"
vim.cmd "hi LineNr guifg=#71839b"
vim.cmd "hi CursorLineNr cterm=bold gui=bold guifg=#dbc074"

-- Left panel
-- "DiffChange:DiffAddAsDelete",
-- "DiffText:DiffDeleteText",
vim.cmd "hi DiffAddAsDelete gui=none guifg=none guibg=#5F3D4D"
vim.cmd "hi DiffDeleteText gui=none guifg=none guibg=#5A1D1D"

-- Right panel
-- "DiffChange:DiffAdd",
-- "DiffText:DiffAddText",
vim.cmd "hi DiffAddText gui=none guifg=none guibg=#2C6468"

-- transparent window
-- NOTE: Neovim 0.11+ (commit: e049c6e) stacks highlight groups (e.g. TabLineFill + Normal),
-- which can override 'guibg=none' with an unintended background color (e.g. black).
-- This forces TabLineFill to stay transparent, and PanelHeading to keep solid bg.
vim.cmd "hi TabLineFill guibg=none"
vim.cmd "hi PanelHeading guibg=#000000 gui=nocombine"

vim.cmd "hi BufferLineBufferSelected guifg=#3ab6f0"

vim.cmd "hi BufferLineTabSelected guifg=#3ab6f0"
vim.cmd "hi BufferLineNumbersSelected cterm=bold,italic gui=bold,italic guifg=#3ab6f0"
vim.cmd "hi LineNr guifg=#71839b"
vim.cmd "hi CursorLineNr cterm=bold gui=bold guifg=#dbc074"
vim.cmd "hi IlluminatedWord guibg=none"
vim.cmd "hi illuminatedCurWord guibg=none"
vim.cmd "hi IlluminatedWordWrite guibg=none"
vim.cmd "hi IlluminatedWordRead guibg=none"
vim.cmd "hi IlluminatedWordText guibg=none"
vim.cmd "hi DiagnosticUnderlineError guifg=#c0caf5"

vim.cmd "hi IndentBlanklineContextChar guifg=#A184FE gui=nocombine" -- #737aa2

vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

-- Utils
vim.cmd "hi Todo cterm=bold gui=bold guifg=#71839b guibg=none"
vim.cmd "au BufEnter *.md setlocal syntax=markdown"

vim.cmd "hi Whitespace guifg=#504945"

-- Utils
vim.cmd "hi Comment guifg=#71839b"

-- Reference : https://github.com/sindrets/diffview.nvim/issues/241
vim.cmd "hi DiffAdd gui=none guifg=none guibg=#2C6468"
vim.cmd "hi DiffChange gui=none guifg=none guibg=#272D43"
vim.cmd "hi DiffText gui=none guifg=none guibg=#4A5B80"
vim.cmd "hi DiffDelete gui=none guifg=none guibg=#5F3D4D"
vim.cmd "hi DiffviewDiffAddAsDelete gui=none guifg=none guibg=#5F3D4D"
vim.cmd "hi DiffviewDiffDelete gui=none guifg=#3B4252 guibg=none"

-- Left panel
-- "DiffChange:DiffAddAsDelete",
-- "DiffText:DiffDeleteText",
vim.cmd "hi DiffAddAsDelete gui=none guifg=none guibg=#5F3D4D"
vim.cmd "hi DiffDeleteText gui=none guifg=none guibg=#5A1D1D"

-- Right panel
-- "DiffChange:DiffAdd",
-- "DiffText:DiffAddText",
vim.cmd "hi DiffAddText gui=none guifg=none guibg=#2C6468"

-- Stolen from Akinsho
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  command = "silent! lua vim.highlight.on_yank{higroup='IncSearch', timeout=200}",
})
