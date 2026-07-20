-- References: https://github.com/nvim-lua/kickstart.nvim
-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
local plugins = {
  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true },
  { import = "plugins" },
  { import = "plugins.autocomplete" },
  { import = "plugins.language" },
  {
    "kevinhwang91/nvim-hlslens",
    event = "CmdlineEnter",
    config = function()
      require('hlslens').setup({})
    end
  },
  -- NOTE: 使用我 fork 的版本，原先的版本對於 nvim-tree 上使用 telescopte 可能造成開檔錯誤 (這裡引入 exclude filetype 排除 telescope 中運行該代碼)
  {
    "ESSO0428/im-select.nvim",
    event = { "ModeChanged", "CursorHold" },
    config = function()
      -- Check if im-select.exe exists
      local has_im_select = os.execute('which im-select.exe > /dev/null 2>&1') == 0
      if has_im_select then
        require('im_select').setup({
          -- IM will be set to `default_im_select` in `normal` mode
          -- For Windows/WSL, default: "1033", aka: English US Keyboard
          -- For macOS, default: "com.apple.keylayout.ABC", aka: US
          -- For Linux, default:
          --               "keyboard-us" for Fcitx5
          --               "1" for Fcitx
          --               "xkb:us::eng" for ibus
          -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
          default_im_select = "1033",

          -- Can be binary's name or binary's full path,
          -- e.g. 'im-select' or '/usr/local/bin/im-select'
          -- For Windows/WSL, default: "im-select.exe"
          -- For macOS, default: "im-select"
          -- For Linux, default: "fcitx5-remote" or "fcitx-remote" or "ibus"
          default_command = 'im-select.exe',

          -- Restore the default input method state when the following events are triggered
          set_default_events = { "VimEnter", "InsertLeave" },

          -- Restore the default input method state (exclude filetype)
          set_default_events_exclude_filetype = { 'TelescopePrompt' },

          -- Restore the previous used input method state when the following events
          -- are triggered, if you don't want to restore previous used im in Insert mode,
          -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
          -- as `set_previous_events = {}`
          set_previous_events = { "InsertEnter" },

          -- Show notification about how to install executable binary when binary missed
          keep_quiet_on_no_binary = false,

          -- Async run `default_command` to switch IM or not
          async_switch_im = true
        })
      end
    end
  },
  {
    "rcarriga/nvim-notify",
    lazy = true,
    event = "VeryLazy",
    config = function()
      local notify = require("notify")
      notify.setup({
        -- "fade", "slide", "fade_in_slide_out", "static"
        stages = "static",
        on_open = nil,
        on_close = nil,
        timeout = 1000,
        fps = 1,
        render = "default",
        background_colour = "Normal",
        max_width = math.floor(vim.api.nvim_win_get_width(0) / 2),
        max_height = math.floor(vim.api.nvim_win_get_height(0) / 4),
        -- minimum_width = 50,
        -- ERROR > WARN > INFO > DEBUG > TRACE
        level = "TRACE"
      })

      -- vim.notify = notify
      local banned_messages = { "No information available" }
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.notify = function(msg, ...)
        for _, banned in ipairs(banned_messages) do
          if msg == banned then
            return
          end
        end
        notify(msg, ...)
      end
    end
  },
  {
    "Eandrju/cellular-automaton.nvim",
    config = function()
      CellularAutomaton_make_it_rain = function()
        local status, err = pcall(function()
          vim.cmd("CellularAutomaton make_it_rain")
        end)
        if not status then
          print('CellularAutomaton : folding and wrapping is not supported')
        end
      end
    end,
    keys = {
      { "<leader>Tc", "<cmd>lua CellularAutomaton_make_it_rain()<cr>", desc = "CellularAutomaton Make It Rain" }
    }
  },
  {
    "kazhala/close-buffers.nvim",
    cmd = { "BDelete", "BufferLineKill", "ForceBufferLineKill" },
    config = function()
      require("user.config.plugins.bufferlinekill").setup()
    end,
  },
  {
    "ThePrimeagen/harpoon",
    event = "User FileOpened",
    config = function()
      require("harpoon").setup()
    end,
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    'stevearc/oil.nvim',
    cmd = { "Oil" },
    opts = {
      default_file_explorer = false,
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<cr>"] = { "actions.select", mode = "n" },
        ["<tab>"] = { "actions.select", mode = "n" },
        ["<a-l>"] = {
          "actions.select",
          opts = { vertical = true },
          desc = "Open the entry in a vertical split",
          mode =
          "n"
        },
        ["<a-k>"] = {
          "actions.select",
          opts = { horizontal = true },
          desc = "Open the entry in a horizontal split",
          mode =
          "n"
        },
        ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab", mode = "n" },
        ["gh"] = { "actions.preview", mode = "n" },
        ["q"] = { "actions.close", mode = "n" },
        ["`"] = { "actions.refresh", mode = "n" },
        ["<"] = { "actions.parent", mode = "n" },
        [">"] = { "actions.select", mode = "n" },
        ["go"] = { "actions.open_cwd", mode = "n" },
        ["gc"] = { "actions.cd", mode = "n" },
        ["gC"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory", mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = { "actions.open_external", mode = "n" },
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
      -- Set to false to disable all of the above keymaps
      use_default_keymaps = false,
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" }
  },
  {
    "ESSO0428/calc.vim",
    cmd = { "Calc" },
  },
  {
    "echasnovski/mini.ai",
    ft = { "python" },
    dependencies = { "ESSO0428/NotebookNavigator.nvim" },
    opts = function()
      local nn = require "notebook-navigator"

      local opts = { custom_textobjects = { h = nn.miniai_spec } }
      return opts
    end
  },
  {
    "echasnovski/mini.hipatterns",
    ft = { "python" },
    dependencies = { "ESSO0428/NotebookNavigator.nvim" },
    opts = function()
      local nn = require "notebook-navigator"

      local opts = { highlighters = { cells = nn.minihipatterns_spec } }
      return opts
    end
  },
  {
    "Shatur/neovim-session-manager",
    config = function()
      vim.api.nvim_clear_autocmds {
        group = "SessionManager",
        event = "VimEnter",
      }
      local group = vim.api.nvim_create_augroup("SessionManager", { clear = false })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VeryLazy",
        nested = true,
        callback = function()
          require("session_manager").autoload_session()
        end,
      })
    end,
    keys = {
      { "<leader>S", ":SessionManager save_current_session<cr>", desc = "SessionManager save_current_session" },
    },
  },
  {
    "AckslD/nvim-neoclip.lua",
    deprecated = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('neoclip').setup()
      vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup('NeoclipManualInsert', { clear = true }),
        pattern = '*',
        callback = function()
          if require('neoclip').stopped then
            return
          end
          if vim.v.event.regcontents == nil then
            require('neoclip.storage').insert({
              regtype = "l",
              contents = vim.fn.getreg('"', 1, true),
              filetype = vim.bo.filetype,
            }, 'yanks')
          end
        end,
      })
    end,
    keys = {
      { "<leader>sy", "<cmd>Telescope neoclip theme=get_ivy<cr>", desc = "Telescope neoclip" },
    },
  },
  { "LunarVim/bigfile.nvim" },
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following Lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    event = "User FileOpened",
    opts = function()
      local icons = require("user.config.icons")

      return {
        signs = {
          add = {
            hl = "GitSignsAdd",
            text = icons.ui.BoldLineLeft,
            numhl = "GitSignsAddNr",
            linehl = "GitSignsAddLn",
          },
          change = {
            hl = "GitSignsChange",
            text = icons.ui.BoldLineLeft,
            numhl = "GitSignsChangeNr",
            linehl = "GitSignsChangeLn",
          },
          delete = {
            hl = "GitSignsDelete",
            text = icons.ui.Triangle,
            numhl = "GitSignsDeleteNr",
            linehl = "GitSignsDeleteLn",
          },
          topdelete = {
            hl = "GitSignsDelete",
            text = icons.ui.Triangle,
            numhl = "GitSignsDeleteNr",
            linehl = "GitSignsDeleteLn",
          },
          changedelete = {
            hl = "GitSignsChange",
            text = icons.ui.BoldLineLeft,
            numhl = "GitSignsChangeNr",
            linehl = "GitSignsChangeLn",
          },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
      }
    end,
  },
  {
    "HakonHarnes/img-clip.nvim",
    -- event = "VeryLazy",
    event = "User FileOpened",
    opts = {
      -- recommended settings
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        -- required for Windows users
        use_absolute_path = true,
      },
    },
  },
  {
    -- Useful plugin to show you pending keybinds.
    "folke/which-key.nvim",
    event = "VeryLazy", -- Sets the loading event to 'VimEnter'
    config = function(_, opts)
      local wk = require "which-key"
      wk.setup(opts)
      require("user.builtin.which-key").load(Nvim.which_key)
    end,
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = true,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = {
          Up = "<Up> ",
          Down = "<Down> ",
          Left = "<Left> ",
          Right = "<Right> ",
          C = "<C-…> ",
          M = "<M-…> ",
          D = "<D-…> ",
          S = "<S-…> ",
          CR = "<CR> ",
          Esc = "<Esc> ",
          ScrollWheelDown = "<ScrollWheelDown> ",
          ScrollWheelUp = "<ScrollWheelUp> ",
          NL = "<NL> ",
          BS = "<BS> ",
          Space = "<Space> ",
          Tab = "<Tab> ",
          F1 = "<F1>",
          F2 = "<F2>",
          F3 = "<F3>",
          F4 = "<F4>",
          F5 = "<F5>",
          F6 = "<F6>",
          F7 = "<F7>",
          F8 = "<F8>",
          F9 = "<F9>",
          F10 = "<F10>",
          F11 = "<F11>",
          F12 = "<F12>",
        },
      },
      plugins = {
        marks = false, -- shows a list of your marks on ' and `
        registers = false, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        spelling = {
          enabled = false,
          suggestions = 20,
        }, -- use which-key for spelling hints
        -- the presets plugin, adds help for a bunch of default keybindings in Neovim
        -- No actual key bindings are created
        presets = {
          operators = false, -- adds help for operators like d, y, ...
          motions = false, -- adds help for motions
          text_objects = false, -- help for text objects triggered after entering an operator
          windows = false, -- default bindings on <c-w>
          nav = false, -- misc bindings to work with windows
          z = false, -- bindings for folds, spelling and others prefixed with z
          g = false, -- bindings for prefixed with g
          h = false, -- bindings for hydra with h
        },
      },
      win = {
        -- don't allow the popup to overlap with the cursor
        no_overlap = true,
        -- width = 1,
        -- height = { min = 4, max = 25 },
        -- col = 0,
        -- row = math.huge,
        border = "rounded",
        padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
        title = true,
        title_pos = "center",
        zindex = 1000,
        -- Additional vim.wo and vim.bo options
        bo = {},
        wo = {
          -- winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        },
      },
      -- triggers = "auto", -- automatically setup triggers
      triggers = { "<leader>", mode = { "n", "v" } }, -- or specify a list manually
      disable = {
        ft = { "TelescopePrompt" },
        bt = {},
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      on_config_done = nil,
      -- size can be a number or function which is passed the current terminal
      size = 20,
      open_mapping = [[<c-\>]],
      hide_numbers = true, -- hide the number column in toggleterm buffers
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
      start_in_insert = true,
      insert_mappings = false, -- whether or not the open mapping applies in insert mode
      persist_size = false,
      -- direction = 'vertical' | 'horizontal' | 'window' | 'float',
      direction = "float",
      close_on_exit = true, -- close the terminal window when the process exits
      auto_scroll = true, -- automatically scroll to the bottom on terminal output
      shell = nil, -- change the default shell
      -- This field is only relevant if direction is set to 'float'
      float_opts = {
        -- The border key is *almost* the same as 'nvim_win_open'
        -- see :h nvim_win_open for details on borders however
        -- the 'curved' border is a custom border type
        -- not natively supported but implemented in this plugin.
        -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
        border = "curved",
        -- width = <value>,
        -- height = <value>,
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      winbar = {
        enabled = false,
      },
    },
  },
  -- Comments
  {
    "numToStr/Comment.nvim",
    event = "User FileOpened",
    config = function()
      require("Comment").setup()
    end,
    keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
  },
  {
    -- Main LSP Configuration
    "neovim/nvim-lspconfig",
    event = "User FileOpened",
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { "mason-org/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { "j-hui/fidget.nvim", opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      "saghen/blink.cmp",
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      require("lspconfig.ui.windows").default_options.border = "rounded"
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("<a-o>", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

          -- map("gh", vim.lsp.buf.hover(), "documentation hover")
          -- map("gm", vim.lsp.buf.signature_help(), "documentation hover")

          -- Find references for the word under your cursor.
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map("gD", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map("<leader>v", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          -- map("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client.server_capabilities.documentSymbolProvider then
            local ok, navbuddy = pcall(require, "nvim-navbuddy")
            if ok then
              navbuddy.attach(client, event.buf)
            end
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map("<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, "[T]oggle Inlay [H]ints")
          end
        end,
      })

      -- Change diagnostic symbols in the sign column (gutter)
      local signs = { Error = "", Warn = "", Hint = "󰌶", Info = "" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = vim.deepcopy(Nvim.builtin.lsp.capabilities or vim.lsp.protocol.make_client_capabilities())
      capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local server_names = vim.deepcopy(Nvim.builtin.lsp.server_names or Nvim.builtin.lsp.ensure_installed or {})

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require("mason").setup {
        ui = {
          check_outdated_packages_on_open = true,
          width = 0.8,
          height = 0.9,
          border = "rounded",
          keymaps = {
            toggle_package_expand = "<cr>",
            install_package = ">",
            update_package = "u",
            check_package_version = "c",
            update_all_packages = "U",
            check_outdated_packages = "C",
            uninstall_package = "X",
            cancel_installation = "<C-c>",
            apply_language_filter = "<C-f>",
          },
        },

        icons = {
          package_installed = "◍",
          package_pending = "◍",
          package_uninstalled = "◍",
        },
      }
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.deepcopy(Nvim.builtin.lsp.ensure_installed or server_names)
      vim.list_extend(ensure_installed, {
        -- "stylua", -- Used to format Lua code
      })
      require("mason-tool-installer").setup { ensure_installed = ensure_installed }

      require("mason-lspconfig").setup {
        ensure_installed = ensure_installed,
        automatic_enable = false,
      }

      local configured_servers = {}
      for _, server_name in ipairs(server_names) do
        local server = vim.deepcopy((Nvim.builtin.lsp.servers or {})[server_name] or {})
        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
        vim.lsp.config(server_name, server)
        table.insert(configured_servers, server_name)
      end

      local enabled = false
      local function enable_configured_servers()
        if enabled then
          return
        end
        enabled = true

        for _, server_name in ipairs(configured_servers) do
          vim.lsp.enable(server_name)
        end

        -- NOTE: vim.lsp.enable() already replays FileType for pre-existing
        -- buffers via its own nvim.lsp.enable augroup. Replaying the generic
        -- FileType event here would re-run runtime ftplugins (for example
        -- markdown.lua), which can eagerly call vim.treesitter.start() again
        -- and surface unrelated parser errors during startup/session restore.
      end

      -- NOTE: Enabling servers during the first file-open event can race with
      -- session restore / FileType on 0.12.x. Configure first, then defer
      -- vim.lsp.enable() until the current event cycle is finished; if a
      -- session is still being sourced, wait until SessionLoadPost.
      local ok_session_utils, session_utils = pcall(require, "session_manager.utils")
      if ok_session_utils and session_utils.session_loading then
        vim.api.nvim_create_autocmd("User", {
          group = vim.api.nvim_create_augroup("user_lsp_enable_after_session", { clear = true }),
          pattern = "SessionLoadPost",
          once = true,
          callback = function()
            vim.schedule(enable_configured_servers)
          end,
        })
      else
        vim.schedule(enable_configured_servers)
      end
    end,
  },
  {
    "aznhe21/actions-preview.nvim",
    event = "LspAttach",
    config = function()
      require("actions-preview").setup {
        diff = {
          algorithm = "patience",
          ignore_whitespace = true,
        },
        telescope = vim.tbl_extend(
          "force",
          -- telescope theme: https://github.com/nvim-telescope/telescope.nvim#themes
          require("telescope.themes").get_dropdown { initial_mode = "normal" },
          -- a table for customizing content
          {
            -- a function to make a table containing the values to be displayed.
            -- fun(action: Action): { title: string, client_name: string|nil }
            make_value = nil,

            -- a function to make a function to be used in `display` of a entry.
            -- see also `:h telescope.make_entry` and `:h telescope.pickers.entry_display`.
            -- fun(values: { index: integer, action: Action, title: string, client_name: string }[]): function
            make_make_display = nil,
          }
        ),
      }
    end,
  },
  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    opts = require("user.config.plugins.nvim_lightbulb").opt,
  },
  {
    -- Autoformat
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>=",
        function()
          require("conform").format { async = true, lsp_format = "fallback" }
        end,
        mode = "",
        desc = "[F]ormat buffer",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = "never"
        else
          lsp_format_opt = "fallback"
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { "stylua" },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      -- Your setup opts here (leave empty to use defaults)
      preview_window = {
        auto_preview = true,
      },
      focus_on_open = false,
      keymaps = {
        close = { '<Esc>', 'q', '<leader>q' },
        fold = { 'h', '[f' },
        unfold = { 'l', ']f' },
        fold_toggle = { '<Tab>', '<leader>o' },
        fold_all = { 'W', '<leader>Oa', '[g' },
        unfold_all = { 'E', '<leader>Od', ']g' },
        hover_symbol = 'gh',
      }
    }
  },
  {
    "miversen33/netman.nvim",
    event = "User FileOpened",
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = { "Neotree" },
    branch = "v3.x",
    deprecated = {
      "miversen33/netman.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "s1n7ax/nvim-window-picker",
    }
  },
  {
    -- Autocompletion
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
      },
      "rafamadriz/friendly-snippets",
      {
        "saghen/blink.compat",
        version = "2.*",
        lazy = true,
        opts = {},
      },
    },
    config = function()
      local luasnip = require "luasnip"
      luasnip.config.setup {}

      pcall(require, "user.snippets")

      local ok_lua_loader, lua_loader = pcall(require, "luasnip.loaders.from_lua")
      if ok_lua_loader then
        lua_loader.lazy_load {
          paths = vim.fn.stdpath("config") .. "/LuaSnipSourceSnippets/",
        }
      end

      local ok_vscode_loader, vscode_loader = pcall(require, "luasnip.loaders.from_vscode")
      if ok_vscode_loader then
        vscode_loader.lazy_load()
        vscode_loader.lazy_load {
          paths = { vim.fn.stdpath("config") .. "/snippets" },
        }
      end

      local function get_visible_completion_bufs()
        local max_size = 100000
        local bufs = {}

        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.api.nvim_get_option_value("filetype", { buf = buf }) ~= "neo-tree" then
            local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
            if size > 0 and size < max_size then
              bufs[buf] = true
            end
          end
        end

        return vim.tbl_keys(bufs)
      end

      local function set_copilot_kind(_, items)
        local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
        local copilot_kind

        for idx, kind in ipairs(CompletionItemKind) do
          if kind == "Copilot" then
            copilot_kind = idx
            break
          end
        end

        if copilot_kind == nil then
          CompletionItemKind[#CompletionItemKind + 1] = "Copilot"
          copilot_kind = #CompletionItemKind
        end

        for _, item in ipairs(items) do
          item.kind = copilot_kind
        end

        return items
      end

      local keymap = {
        preset = "none",
        ["<M-i>"] = { "select_prev", "show" },
        ["<M-k>"] = { "select_next", "show" },
        ["<M-j>"] = {
          function(cmp)
            if cmp.is_menu_visible() then
              return cmp.cancel()
            end
            return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          end,
        },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-o>"] = { "scroll_documentation_down", "fallback" },
        ["<M-l>"] = { "accept" },
        ["<M-d>"] = { "select_next", "snippet_forward", "fallback" },
        ["<M-a>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      }

      local cmdline_keymap = {
        preset = "cmdline",
        ["<M-i>"] = { "select_prev", "show" },
        ["<M-k>"] = { "select_next", "show" },
        ["<M-j>"] = { "cancel", "fallback" },
        ["<Right>"] = false,
        ["<Left>"] = false,
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<M-l>"] = { "accept", "fallback" },
        ["<CR>"] = { "accept_and_enter", "fallback" },
      }

      require("blink.cmp").setup {
        enabled = function()
          if vim.bo.filetype == "copilot-chat" then
            return "force"
          end
          return vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
        end,
        keymap = keymap,
        appearance = {
          use_nvim_cmp_as_default = true,
          kind_icons = {
            Copilot = require("user.config.icons").git.Octoface,
          },
        },
        snippets = { preset = "luasnip" },
        completion = {
          ghost_text = { enabled = true },
          accept = {
            auto_brackets = {
              enabled = false,
            },
          },
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          menu = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
            draw = {
              columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
              components = {
                source_name = {
                  width = { max = 20 },
                  text = function(ctx)
                    if ctx.source_id == "html_css" and ctx.label_description and #ctx.label_description > 0 then
                      return "(html-css) " .. ctx.label_description
                    end
                    return "(" .. ctx.source_name .. ")"
                  end,
                  highlight = "BlinkCmpSource",
                },
              },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            treesitter_highlighting = true,
            window = {
              border = "rounded",
            },
          },
        },
        cmdline = {
          enabled = true,
          keymap = cmdline_keymap,
          completion = {
            menu = {
              auto_show = true
            },
            list = { selection = { preselect = false, } },
            ghost_text = { enabled = true },
          },
        },
        sources = {
          min_keyword_length = 1,
          default = { "lazydev", "copilot", "lsp", "snippets", "path", "buffer" },
          per_filetype = {
            ["copilot-chat"] = { "copilot_chat", "buffer", "path" },
            ["dap-repl"] = { "dap" },
            html = { inherit_defaults = true, "html_css" },
            htmldjango = { inherit_defaults = true, "html_css" },
            javascriptreact = { inherit_defaults = true, "html_css" },
            typescriptreact = { inherit_defaults = true, "html_css" },
            sql = { "copilot", "dadbod", "path", "buffer" },
            mysql = { "copilot", "dadbod", "path", "buffer" },
            plsql = { "copilot", "dadbod", "path", "buffer" },
          },
          providers = {
            lazydev = {
              name = "lazydev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
            lsp = {
              name = "LSP",
              fallbacks = {},
            },
            snippets = {
              name = "L-Snippet",
            },
            path = {
              name = "Path",
              module = "user.blink.path",
              score_offset = 3,
              opts = {
                trailing_slash = true,
                label_trailing_slash = true,
                get_cwd = function(context)
                  return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                end,
                show_hidden_files_by_default = false,
              },
            },
            buffer = {
              name = "Buffer",
              score_offset = -3,
              opts = {
                get_bufnrs = get_visible_completion_bufs,
              },
            },
            copilot = {
              name = "Copilot",
              module = "blink-cmp-copilot",
              async = true,
              score_offset = 90,
              transform_items = set_copilot_kind,
            },
            copilot_chat = {
              name = "copilot-chat",
              module = "blink-cmp-copilot-chat",
              async = true,
            },
            dap = {
              name = "dap",
              module = "blink-cmp-dap",
            },
            dadbod = {
              name = "dadbod-sql",
              module = "vim_dadbod_completion.blink",
            },
            html_css = {
              name = "html-css",
              module = "blink.compat.source",
              opts = {
                cmp_name = "html-css",
              },
            },
          },
        },
      }
    end,
  },
  {
    -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {
      transparent = true,
      terminal_colors = false, -- Configure the colors used when opening a `:terminal` in Neovim
      plugins = {
        -- 禁用 tokyonight 对 rainbow-delimiters 的内置适配
        rainbow = false,
      },
    },
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme "tokyonight-night"

      -- You can configure highlights by doing something like:
      vim.cmd.hi "Comment gui=none"
    end,
  },
  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
  {
    "nvimtools/hydra.nvim",
    -- event = "VeryLazy", -- 只有你真的用 hydra 的時候才會拖一點
    keys = {
      { "<leader>h", mode = "n", desc = "Hydra Submenus Prefix" }
    },
    config = function()
      require("user.keymappings.hydra").setup()
    end,
  },
}

-- NOTE: Lazy.nvim settings
local settings = {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
    border = "rounded",
  },
  performance = {
    rtp = { reset = false },
  },
}

require("lazy").setup(plugins, settings)
