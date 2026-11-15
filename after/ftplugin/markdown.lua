vim.opt_local.foldenable = true
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- 覆寫 $VIMRUNTIME/ftplugin/markdown.vim 的 4 空格（markdown_recommended_style）
-- 放在 ftplugin 而非 syntax：Snacks.scratch 等以 treesitter 高亮的 buffer 不會載入 syntax 檔
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2

if vim.bo.buftype == "nofile" then
  vim.opt_local.concealcursor = "nc"
end
