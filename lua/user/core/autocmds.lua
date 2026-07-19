local _file_opened_group = vim.api.nvim_create_augroup("_file_opened", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufNewFile" }, {
  group = _file_opened_group,
  nested = true,
  callback = function(args)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
    if not (vim.fn.expand "%" == "" or buftype == "nofile") then
      vim.api.nvim_del_augroup_by_name "_file_opened"
      vim.api.nvim_exec_autocmds("User", { pattern = "FileOpened" })

      -- 注意：這行需要根據你的 LSP 配置修改
      -- 如果你用的是標準 lspconfig，通常不需要這行，
      -- 但若要手動觸發某個模組，請將其替換為你的加載函數
      -- require("your_lsp_config").setup()
    end
  end,
})
