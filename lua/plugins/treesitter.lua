return {
  {
    -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" }, -- ★ 新增
    -- event = "User FileOpened",
    lazy = false,
    branch = "main",
    version = false,
    build = ":TSUpdate",
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = {
      -- Follow LazyVim's single install path here. Combining nvim-treesitter's
      -- auto_install with our own ensure_installed bootstrap can race and leave
      -- <lang>-tmp directories behind, which is exactly what broke json
      -- highlighting until a restart.
      ensure_installed = {
        "bash", "c", "comment", "css", "diff", "html", "javascript", "json", "lua", "luadoc", "markdown",
        "markdown_inline", "python", "query", "scss", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
        -- "regex"
      },
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      ts.setup(opts)

      local group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true })
      local function start_for_buffer(bufnr)
        if not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        local filetype = vim.bo[bufnr].filetype
        if filetype == "" then
          return
        end

        local lang = vim.treesitter.language.get_lang(filetype)
        if not lang then
          return
        end

        local installed = ts.get_installed("parsers")
        if not vim.tbl_contains(installed, lang) then
          return
        end

        local ok_add = pcall(vim.treesitter.language.add, lang)
        if not ok_add then
          return
        end

        pcall(vim.treesitter.start, bufnr, lang)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          start_for_buffer(args.buf)
        end,
      })

      local installed = ts.get_installed("parsers")
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, opts.ensure_installed or {})

      if #missing > 0 then
        if vim.fn.executable("tree-sitter") ~= 1 then
          vim.schedule(function()
            vim.notify_once(
              "nvim-treesitter (main) needs tree-sitter CLI in $PATH; skipping parser auto-install for: "
                .. table.concat(missing, ", "),
              vim.log.levels.WARN
            )
          end)
        else
          ts.install(missing, { summary = true }):await(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local name = vim.api.nvim_buf_get_name(buf)
              local buftype = vim.bo[buf].buftype
              if name ~= "" and (buftype == "" or buftype == "help") then
                start_for_buffer(buf)
              end
            end
          end)
        end
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        local buftype = vim.bo[buf].buftype
        if name ~= "" and (buftype == "" or buftype == "help") then
          start_for_buffer(buf)
        end
      end
    end,
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "User FileOpened",
  },
  {
    "nvim-treesitter/playground",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
  },
  -- WARNING: 使用此套件時請謹慎，因為它可能會導致在 nvim-tree 中結合使用 telescope 時出現開啟文件的錯誤。
  -- 當前的暫時解決方案是在 Neovim 配置文件中添加名為 handle_telescope_nvimtree_interaction (nvimtree.lua) 的函數，
  -- 並在 BufWinLeave 事件中觸發該函數。
  -- 這個解決方案主要處理了 NvimTreePicker 啟用前會先離開 NvimTree 的機制：
  -- 在啟用 window-picker 功能前，會先離開 filetype 為 NvimTree 和 buftype 為 nofile 的 buffer window，
  -- 在離開該窗口時，此函數將關閉所有疑似由 nvim-treesitter-context 插件創建的浮動窗口 (沒處理好的話會在 window-picker 前被讀取)，
  -- 這些窗口包含 filenam == '', filetype == '' 和 buftype == 'nofile 的屬性，可能會干擾文件正常的打開過程。
  -- NOTE: 這裡先固定 commit 後續 nvim 大改再考慮更新
  {
    "nvim-treesitter/nvim-treesitter-context",
    -- event = { "BufReadPost", "BufNewFile" },
    event = "User FileOpened",
    config = function()
      vim.keymap.set('n', '[a', function() require("treesitter-context").go_to_context() end,
        { silent = true, nowait = true })
      require("treesitter-context").setup {
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20, -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      }
    end
  },
}
