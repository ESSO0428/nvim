return {
  {
    "akinsho/bufferline.nvim",
    -- event = "VeryLazy", -- ★ 新增
    event = "User FileOpened",
    dependencies = {
      "ESSO0428/tabline.nvim",
      dependencies = { "fgheng/winbar.nvim", "nvim-lualine/lualine.nvim", "nvim-tree/nvim-web-devicons" },
      config = function()
        require("tabline").setup {
          enable = false,
          options = {
            show_tabs_always = true,
          },
        }
        vim.cmd [[
        set guioptions-=e " Use showtabline in gui vim
        set sessionoptions+=tabpages,globals " store tabpages and globals in session
      ]]
      end,
    },
    config = function()
      local ok_bufferline, bufferline = pcall(require, "bufferline")
      if not ok_bufferline then
        return
      end

      local builtin_bufferline = vim.deepcopy(Nvim.builtin.bufferline or {})
      local bufferline_options =
      vim.deepcopy(builtin_bufferline.options or {})

      -- 加入預設 ungrouped group。
      local ok_groups, groups = pcall(require, "bufferline.groups")

      if ok_groups
          and bufferline_options.groups
          and vim.islist(bufferline_options.groups.items) then
        local has_ungrouped =
        vim.iter(bufferline_options.groups.items):any(function(item)
          return item.name == "ungrouped"
        end)

        if not has_ungrouped then
          local ungrouped = groups.builtin.ungrouped:with({
            name = "ungrouped",
            separator = {
              style = groups.separator.pill,
            },
          })

          table.insert(
            bufferline_options.groups.items,
            ungrouped
          )
        end
      end
      local function install_bufferline_render_cache()
        local original = _G.nvim_bufferline

        if type(original) ~= "function" then
          vim.notify(
            "[bufferline] nvim_bufferline is unavailable",
            vim.log.levels.ERROR
          )
          return
        end

        local render_cache = {}
        local generation = 0

        local resizing = false
        local resize_generation = 0
        local frozen_cache = nil

        local cache_group = vim.api.nvim_create_augroup(
          "BufferlineRenderCache",
          { clear = true }
        )

        local function make_cache_key()
          return table.concat({
            generation,
            vim.api.nvim_get_current_tabpage(),
            vim.api.nvim_get_current_buf(),
          }, ":")
        end

        local function invalidate_all(redraw)
          generation = generation + 1
          render_cache = {}
          frozen_cache = nil

          if redraw then
            vim.schedule(function()
              vim.cmd.redrawtabline()
            end)
          end
        end

        vim.api.nvim_create_autocmd({
          "BufAdd",
          "BufDelete",
          "BufWipeout",
          "BufFilePost",
          "FileType",
          "ColorScheme",
          "TabNew",
          "TabClosed",
        }, {
          group = cache_group,
          callback = function()
            invalidate_all(false)
          end,
        })

        vim.api.nvim_create_autocmd("BufModifiedSet", {
          group = cache_group,
          callback = function()
            invalidate_all(true)
          end,
        })

        if bufferline_options.diagnostics then
          vim.api.nvim_create_autocmd("DiagnosticChanged", {
            group = cache_group,
            callback = function()
              invalidate_all(true)
            end,
          })
        end

        vim.api.nvim_create_autocmd("User", {
          group = cache_group,
          pattern = {
            "BufferLineHoverOver",
            "BufferLineHoverOut",
          },
          callback = function()
            invalidate_all(true)
          end,
        })

        vim.api.nvim_create_autocmd({
          "VimResized",
          "WinResized",
        }, {
          group = cache_group,
          callback = function()
            resizing = true
            resize_generation = resize_generation + 1
            local current = resize_generation

            vim.defer_fn(function()
              if current ~= resize_generation then
                return
              end

              resizing = false
              invalidate_all(true)
            end, 120)
          end,
        })

        _G.nvim_bufferline = function()
          if resizing and frozen_cache ~= nil then
            return frozen_cache
          end

          local key = make_cache_key()
          local cached = render_cache[key]

          if cached ~= nil then
            frozen_cache = cached
            return cached
          end

          local rendered = original()
          render_cache[key] = rendered
          frozen_cache = rendered

          return rendered
        end

        vim.api.nvim_create_user_command(
          "BufferlineCacheInvalidate",
          function()
            invalidate_all(true)
          end,
          {
            desc = "Invalidate and redraw bufferline render cache",
            force = true,
          }
        )
      end

      -- 避免預設 tabline 在 bufferline 載入前閃爍。
      vim.opt.showtabline = 2

      bufferline.setup({
        highlights =
        vim.deepcopy(builtin_bufferline.highlights or {}),

        options = bufferline_options,

        -- 只交給 bufferline.setup 執行一次。
        on_config_done = builtin_bufferline.on_config_done,
      })

      -- 必須在 bufferline.setup 後載入，
      -- 若這個模組會修改 bufferline/tabline 狀態。
      local ok_integrated, integrated_err =
      pcall(require, "user.integrated.bufferline.nvimTabline")

      if not ok_integrated then
        vim.notify(
          ("Failed to load bufferline integration: %s")
          :format(integrated_err),
          vim.log.levels.WARN
        )
      end

      local ok_tabline, tabline = pcall(require, "tabline")

      if ok_tabline then
        -- 若這個函式會建立 session tab 資料，保留。
        tabline.on_session_load_post()

        vim.o.tabline =
        "%!v:lua.nvim_bufferline()"
            .. " .. v:lua.require'tabline'.tabline_tabs()"
      else
        vim.o.tabline = "%!v:lua.nvim_bufferline()"
      end
      -- 一定要在整合模組與 tabline 初始化之後安裝。
      install_bufferline_render_cache()
    end
  },
  {
    "nvim-lua/popup.nvim",
    -- event = "VeryLazy", -- 很多 plugin 依賴，但不必一開始就載
    event = "User FileOpened", -- 很多 plugin 依賴，但不必一開始就載
  },
  {
    "petertriho/nvim-scrollbar",
    -- event = "BufReadPost",
    event = "User FileOpened",
    config = function()
      require("scrollbar").setup({
        show = true,
        handle = {
          text = " ",
          color = "#928374",
          hide_if_all_visible = true
        },
        marks = {
          Search = { color = "yellow" },
          Misc = { color = "purple" }
        },
      })
    end
  },
  {
    "kevinhwang91/nvim-hlslens",
    event = "CmdlineEnter",
    config = function()
      require('hlslens').setup({})
    end
  },
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = require("user.config.plugins.dressing").opt,
  },
  {
    "folke/trouble.nvim",
    -- event = "VeryLazy",
    cmd = "Trouble",
    config = function()
      require("user.trouble").setup()
    end
  },
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    config = function()
      require("user.edgy").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VimEnter",
    config = function()
      vim.g.vim_pid = vim.fn.getpid()
      local icons = require("user.config.icons")
      local Path = require("plenary.path")
      local colors = {
        bg = "#202328",
        fg = "#bbc2cf",
        yellow = "#ECBE7B",
        cyan = "#008080",
        darkblue = "#081633",
        green = "#98be65",
        orange = "#FF8800",
        violet = "#a9a1e1",
        magenta = "#c678dd",
        purple = "#c678dd",
        blue = "#51afef",
        red = "#ec5f67",
      }
      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand "%:t") ~= 1
        end,
        hide_in_width = function()
          return vim.o.columns > 100
        end,
      }

      local function read_pyvenv_prompt(dir)
        local cfg = tostring(Path:new(dir):joinpath("pyvenv.cfg"))
        local f = io.open(cfg, "r")
        if not f then
          return nil
        end
        for line in f:lines() do
          local key, value = line:match("^%s*(%w+)%s*=%s*(.+)%s*$")
          if key == "prompt" then
            f:close()
            return vim.trim(value)
          end
        end
        f:close()
        return nil
      end

      local function env_cleanup(venv)
        if string.find(venv, "/") then
          local final_venv = venv
          for w in venv:gmatch "([^/]+)" do
            final_venv = w
          end
          venv = final_venv
        end
        return venv
      end

      local function diff_source()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
          }
        end
      end

      local function list_null_ls(kind, filetype)
        local ok, sources = pcall(require, "null-ls.sources")
        if not ok then
          return {}
        end
        local items = sources.get_available(filetype, kind)
        local names = {}
        for _, source in ipairs(items) do
          table.insert(names, source.name)
        end
        return names
      end

      local components = {}
      components.diff = {
        "diff",
        source = diff_source,
        symbols = {
          added = icons.git.LineAdded .. " ",
          modified = icons.git.LineModified .. " ",
          removed = icons.git.LineRemoved .. " ",
        },
        padding = { left = 2, right = 1 },
        diff_color = {
          added = { fg = colors.green },
          modified = { fg = colors.yellow },
          removed = { fg = colors.red },
        },
      }

      components.python_env = {
        function()
          if vim.bo.filetype == "python" then
            local venv = os.getenv "CONDA_DEFAULT_ENV" or os.getenv "VIRTUAL_ENV"
            if os.getenv("VIRTUAL_ENV") and os.getenv("CONDA_DEFAULT_ENV") == "base" then
              venv = os.getenv("VIRTUAL_ENV")
            end
            if venv then
              local devicons = require("nvim-web-devicons")
              local py_icon = devicons.get_icon ".py"
              local venv_name = read_pyvenv_prompt(venv) or env_cleanup(venv)
              return string.format(" " .. (py_icon or "") .. " (%s)", venv_name)
            end
          end
          return ""
        end,
        color = { fg = colors.green },
        cond = conditions.hide_in_width,
      }

      components.diagnostics = {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = {
          error = icons.diagnostics.BoldError .. " ",
          warn = icons.diagnostics.BoldWarning .. " ",
          info = icons.diagnostics.BoldInformation .. " ",
          hint = icons.diagnostics.BoldHint .. " ",
        },
      }

      components.lsp = {
        function()
          local buf_clients = vim.lsp.get_clients { bufnr = 0 }
          if #buf_clients == 0 then
            return "LSP Inactive"
          end

          local buf_ft = vim.bo.filetype
          local buf_client_names = {}
          local copilot_active = false

          for _, client in pairs(buf_clients) do
            if client.name ~= "null-ls" and client.name ~= "copilot" then
              table.insert(buf_client_names, client.name)
            end

            if client.name == "copilot" then
              copilot_active = true
            end
          end

          local formatters = list_null_ls("FORMATTER", buf_ft)
          vim.list_extend(buf_client_names, formatters)

          local linters = list_null_ls("DIAGNOSTICS", buf_ft)
          vim.list_extend(buf_client_names, linters)

          local unique_client_names = table.concat(buf_client_names, ", ")
          local language_servers = string.format("[%s]", unique_client_names)

          if copilot_active then
            language_servers = language_servers .. "%#SLCopilot#" .. " " .. icons.git.Octoface .. "%*"
          end

          return language_servers
        end,
        color = { gui = "bold" },
        cond = conditions.hide_in_width,
      }

      local function auto_check_markdown_links_status()
        local filetype = vim.bo.filetype
        if filetype == "markdown" or filetype == "markdown" then
          if vim.b.auto_check_markdown_links or vim.b.auto_check_markdown_links == nil then
            return " Auto Check Link: true"
          else
            return " Auto Check Link: false"
          end
        end
        return ""
      end

      local function narrow_status()
        if vim.b.narrow_mode == true then
          return " Narrowing: true"
        end
        return ""
      end

      require("lualine").setup {
        options = {
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { { "mode" } },
          lualine_b = {},
          lualine_c = {
            components.diff,
            components.python_env,
            components.diagnostics,
            { "b:CURRENT_REPL" },
            { "b:jupyter_kernel" },
            { auto_check_markdown_links_status },
            { narrow_status },
          },
          lualine_x = {
            { 'vim.api.nvim_call_function("getcwd", {0})' },
            { "encoding" },
            { "fileformat" },
            { "filetype", icon_only = false },
            components.lsp,
            {
              "pid",
              fmt = function()
                return "pid:" .. vim.g.vim_pid
              end,
            },
          },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
