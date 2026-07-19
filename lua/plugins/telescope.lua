return {
  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  {
    -- Fuzzy Finder (files, lsp, etc)
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable "make" == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { "nvim-tree/nvim-web-devicons" },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`

      local actions = require "telescope.actions"
      local action_layout = require "telescope.actions.layout"
      local custom_layout_config = {
        scroll_speed = 1,
        width = 0.95,
        height = 0.65,
        prompt_position = "top",
        -- preview_width   = 0.50
        horizontal = {
          scroll_speed = 1,
          width = 0.95,
          height = 0.65,
          mirror = false,
        },
        vertical = {
          scroll_speed = 1,
          width = 0.95,
          height = 0.95,
          preview_height = 0.50,
          mirror = true,
        },
      }
      require("telescope").setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          layout_strategy = "horizontal",
          sorting_strategy = "ascending",
          layout_config = custom_layout_config,
          mappings = {
            -- i = { ['<c-enter>'] = 'to_fuzzy_refine' },
            n = {
              ["q"] = {
                actions.close,
                type = "action",
                opts = { nowait = true, silent = true },
              },
              ["k"] = actions.move_selection_next,
              ["i"] = actions.move_selection_previous,
              ["<ScrollWheelUp>"] = actions.move_selection_previous,
              ["<ScrollWheelDown>"] = actions.move_selection_next,
              ["<LeftMouse>"] = function()
                vim.defer_fn(function()
                  vim.api.nvim_input "<cr>"
                end, 100)
              end,
              ["<C-q>"] = function(...)
                actions.smart_send_to_qflist(...)
                actions.open_qflist(...)
              end,
              ["<c-k>"] = function(...) end,
              ["<C-j>"] = function(...)
                actions.toggle_selection(...)
                actions.move_selection_better(...)
              end,
              ["<C-l>"] = function(...)
                actions.toggle_selection(...)
                actions.move_selection_worse(...)
              end,
              ["<a-t>"] = actions.select_tab,
              ["<a-m>"] = actions.select_tab,
              ["<a-l>"] = actions.select_vertical,
              ["<a-k>"] = actions.select_horizontal,
              ["<a-d>"] = action_layout.toggle_preview,
              ["<c-p>"] = action_layout.cycle_layout_next,
              ["<c-u>"] = actions.preview_scrolling_up,
              ["<c-o>"] = actions.preview_scrolling_down,
            },
            i = {
              ["<c-v>"] = function()
                local paste = vim.fn["PasteWithoutTrailingNewline"]
                local text = paste "i"
                vim.api.nvim_put({ text }, "c", true, true)
              end,
              -- ['<cr>'] = function()
              --   vim.api.nvim_input('<Esc>')
              --   vim.defer_fn(function()
              --     vim.api.nvim_input('<cr>')
              --   end, 100)
              -- end,
              ["<ScrollWheelUp>"] = actions.move_selection_previous,
              ["<ScrollWheelDown>"] = actions.move_selection_next,
              ["<LeftMouse>"] = function()
                vim.defer_fn(function()
                  vim.api.nvim_input "<cr>"
                end, 100)
              end,
              ["<C-q>"] = function(...)
                actions.smart_send_to_qflist(...)
                actions.open_qflist(...)
              end,
              ["<c-k>"] = function(...) end,
              ["<C-j>"] = function(...)
                actions.toggle_selection(...)
                actions.move_selection_better(...)
              end,
              ["<C-l>"] = function(...)
                actions.toggle_selection(...)
                actions.move_selection_worse(...)
              end,
              ["<a-t>"] = actions.select_tab,
              ["<a-m>"] = actions.select_tab,
              ["<a-l>"] = actions.select_vertical,
              ["<a-k>"] = actions.select_horizontal,
              ["<a-d>"] = action_layout.toggle_preview,
              ["<c-p>"] = action_layout.cycle_layout_next,
              ["<c-u>"] = actions.preview_scrolling_up,
              ["<c-o>"] = actions.preview_scrolling_down,
            },
          },
        },
        pickers = {
          buffers = {
            initial_mode = "normal",
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")

    end,
  },
  {
    "ESSO0428/telescope-tabs",
    config = function()
      require("telescope-tabs").setup {
        entry_formatter = function(tab_id, buffer_ids, file_names, file_paths, is_current)
          if vim.g.Tabline_session_data == nil then
            return
          end
          local TablineData = vim.fn.json_decode(vim.g.Tabline_session_data)
          -- need require "user.tabpage" in config.lua
          local status_ok, tabpage_id = pcall(find_tabpage_index, tab_id)
          if not status_ok then
            print(table.concat(
              {
                "telescope-tabs Error : need require \"user.tabpage\" with function find_tabpage_index in config.lua",
                "telescope-tabs Error : or Not found correctly tab_id in nvim tab list"
              },
              "\n")
            )
            return
          end

          local tab_name = TablineData[tabpage_id].name
          -- require("tabby.feature.tab_name").get(tab_id)
          -- return string.format("%d: %s%s", tab_id, tab_id, is_current and " <" or "")

          -- Get the focused window's buffer ID for the current tab
          local focused_win = vim.fn.tabpagewinnr(tabpage_id)

          -- Iterate over file_names and add '<' if the corresponding buffer exists
          file_names[focused_win] = file_names[focused_win] .. " #"

          local entry_string = table.concat(file_names, ', ')
          return string.format('%d [%s]: %s%s', tabpage_id, tab_name, entry_string, is_current and ' <' or '')
        end,
        entry_ordinal = function(tab_id, buffer_ids, file_names, file_paths, is_current)
          -- return table.concat(file_names, ' ')
          if vim.g.Tabline_session_data == nil then
            return
          end
          local TablineData = vim.fn.json_decode(vim.g.Tabline_session_data)
          -- need require "user.tabpage" in config.lua
          local status_ok, tabpage_id = pcall(find_tabpage_index, tab_id)
          if not status_ok then
            return
          end

          -- return TablineData[tab_id].name
          local entry_string = table.concat(file_names, ', ')
          return string.format('%d %s %s', tabpage_id, TablineData[tabpage_id].name, entry_string)
          -- require("tabby.feature.tab_name").get(tab_id)
        end,
        close_tab_shortcut_i = '<C-d>', -- if you're in insert mode
        close_tab_shortcut_n = 'dd', -- if you're in normal mode
      }
    end,
    keys = {
      { "<leader>su", "<cmd>Telescope telescope-tabs list_tabs<cr>", desc = "[S]earch [T]abs" },
    },
  },
  {
    "LinArcX/telescope-command-palette.nvim",
    event = "VeryLazy",
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    event = "VeryLazy",
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      pcall(require("telescope").load_extension, "file_browser")
    end
  },
  {
    "nvim-telescope/telescope-media-files.nvim",
    event = "VeryLazy",
  },
  {
    "Zane-/cder.nvim",
    event = "VeryLazy",
    -- build = 'cargo install exa'
    build = 'cargo install --list | grep -q "exa v" || cargo install exa'
  },
  -- {
  --   "zane-/howdoi.nvim",
  --   cmd = { "Howdoi" },
  --   build = 'pip install howdoi'
  -- },
}
