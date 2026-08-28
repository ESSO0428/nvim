require("bigfile").setup {
  filesize = 1,
  pattern = { "*" },
  features = {
    "indent_blankline",
    "illuminate",
    "lsp",
    "treesitter",
    "syntax",
    "matchparen",
    "vimopts",
    "filetype",
    {
      name = "mymatchparen",
      opts = {
        defer = false,
      },
      disable = function()
        vim.cmd "set nowrap"
        vim.cmd "set nofoldenable"
        vim.cmd "setlocal nospell"
        vim.cmd "setlocal cursorline"

        local ok_rainbow, rainbow = pcall(require, "rainbow-delimiters")
        if ok_rainbow then
          rainbow.disable(0)
        end

        local ok_session_utils, session_utils = pcall(require, "session_manager.utils")
        local is_session_loading = ok_session_utils and session_utils.session_loading
        if is_session_loading then
          return
        end

        if vim.g.vim_pid == nil then
          vim.g.vim_pid = vim.fn.getpid()
        end

        local pid_info = vim.g.vim_pid and ("(CURRENT PID: " .. vim.g.vim_pid .. ")") or ""
        local bufnr = vim.api.nvim_get_current_buf()
        local fileName = vim.api.nvim_buf_get_name(bufnr)
        local choice = vim.fn.input(table.concat({
          table.concat({ pid_info, "File is large file, Do you want to continue loading?" }, " "),
          "[n]ot open",
          "[s]ecurity session save and open",
          "[y]es directly open",
          "[v]iew with external viewer",
          "choice(s/y/v/n): ",
        }, "\n"))

        if choice == "s" then
          vim.cmd "b#"
          vim.cmd("bd " .. bufnr)
          vim.defer_fn(function()
            vim.cmd "SessionManager save_current_session"
            vim.cmd("e " .. vim.fn.fnameescape(fileName))
          end, 50)
        elseif choice == "y" then
          -- Continue with default settings.
        elseif choice == "v" then
          vim.cmd "b#"
          vim.cmd("bd " .. bufnr)
          Nvim.FileTool.file_viewer.open_bigfile_viewer(fileName)
        else
          vim.cmd "b#"
          vim.cmd("bd " .. bufnr)
        end
      end,
    },
  },
}
