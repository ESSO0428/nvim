return {
  { "nvimtools/none-ls.nvim", lazy = true },
  { "Tastyep/structlog.nvim", lazy = true },
  -- Telescope
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
  -- Install blink.cmp and shared completion dependencies
  { "rafamadriz/friendly-snippets", lazy = true },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup {}
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter", "saghen/blink.cmp" },
  },

  {
    -- Lazy loaded by Comment.nvim pre_hook
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },

  -- Debugging
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
    },
  },

  -- Debugger user interface
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local icons = require("user.config.icons")

      Nvim.DAPUI = Nvim.DAPUI or {}
      if Nvim.DAPUI.auto_open == nil then
        Nvim.DAPUI.auto_open = true
      end

      Nvim.DAPUI.toggle_auto_open = function()
        Nvim.DAPUI.auto_open = not Nvim.DAPUI.auto_open
        vim.notify("DAP UI auto-open: " .. (Nvim.DAPUI.auto_open and "ON" or "OFF"))
      end

      vim.fn.sign_define("DapBreakpoint", {
        text = icons.ui.Bug,
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = icons.ui.Bug,
        texthl = "SignColumn",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = icons.ui.Bug,
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapLogPoint", {
        text = "L",
        texthl = "DiagnosticSignWarning",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapStopped", {
        text = icons.ui.BoldArrowRight,
        texthl = "DiagnosticSignWarn",
        linehl = "Visual",
        numhl = "DiagnosticSignWarn",
      })

      dapui.setup({
        icons = { expanded = "", collapsed = "", circular = "" },
        mappings = {
          -- Use a table to apply multiple mappings
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        -- Use this to override mappings for specific elements
        element_mappings = {},
        expand_lines = true,
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.33 },
              { id = "breakpoints", size = 0.17 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 0.25,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.45 },
              { id = "console", size = 0.55 },
            },
            size = 0.27,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          -- Display controls in this element
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "",
            terminate = "",
          },
        },
        floating = {
          max_height = 0.9,
          max_width = 0.5, -- Floats will be treated as percentage of your screen.
          border = "rounded",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        windows = { indent = 1 },
        render = {
          max_type_length = nil, -- Can be integer or nil.
          max_value_lines = 100, -- Can be integer or nil.
        },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        if Nvim.DAPUI.auto_open then
          Nvim.DAPUI.open_with_layout({ reset = true })
        end
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        Nvim.DAPUI.close_with_layout()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        Nvim.DAPUI.close_with_layout()
      end
    end,
  },

  -- SchemaStore
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },

  {
    "RRethy/vim-illuminate",
    event = "User FileOpened",
  },
}
