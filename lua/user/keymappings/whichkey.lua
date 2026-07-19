local function dap_edit_breakpoint()
  local function get_input_with_default(prompt, default)
    local input = vim.fn.input(prompt, default or ''):gsub("^%s*(.-)%s*$", "%1")
    return input ~= "" and input or nil
  end

  local breakpoint_condition = function()
    local condition_input = get_input_with_default('Breakpoint condition: ')
    local hitCondition_input = get_input_with_default('Hit condition: ')
    local logMessage_input = get_input_with_default('Log point message: ')
    require('persistent-breakpoints.api').set_breakpoint(
      condition_input,
      hitCondition_input,
      -- NOTE: Exclude LogMessage since it's incompatible with regular breakpoints
      logMessage_input
    )
  end
  -- Get all breakpoints
  local breakpoints = require('dap.breakpoints').get()

  -- Check if breakpoints is empty or nil, if so return
  if breakpoints == nil or vim.tbl_isempty(breakpoints) then
    breakpoint_condition()
    return
  end

  -- Get current line and current buffer
  local current_line = vim.fn.line('.')
  local current_buffer = vim.fn.bufnr()

  -- If there are breakpoints in the current buffer
  if breakpoints[current_buffer] then
    -- Traverse all breakpoints in the current buffer
    for _, bp in pairs(breakpoints[current_buffer]) do
      if bp.line then
        local bp_line = bp.line

        -- If the current line corresponds to the line of the breakpoint
        if bp_line == current_line then
          -- Check if there is condition, hitCondition or logMessage
          local condition_exists = bp.condition ~= nil and bp.condition:gsub("^%s*(.-)%s*$", "%1") ~= ""
          local hitCondition_exists = bp.hitCondition ~= nil and bp.hitCondition:gsub("^%s*(.-)%s*$", "%1") ~= ""
          local logMessage_exists = bp.logMessage ~= nil and bp.logMessage:gsub("^%s*(.-)%s*$", "%1") ~= ""

          -- If none exists, return
          if not (condition_exists or hitCondition_exists or logMessage_exists) then
            breakpoint_condition()
            return
          end

          -- Set input default value
          local condition_input = get_input_with_default('Breakpoint condition: ', bp.condition)
          local hitCondition_input = get_input_with_default('Hit condition: ', bp.hitCondition)
          local logMessage_input = get_input_with_default('Log point message: ', bp.logMessage)
          -- Set breakpoint
          require('persistent-breakpoints.api').set_breakpoint(
            condition_input,
            hitCondition_input,
            logMessage_input
          )
          return
        end
      end
    end
  end
  -- If no matching breakpoint, create a new one
  breakpoint_condition()
end

vim.api.nvim_create_user_command('DAPEditBreakpoint', dap_edit_breakpoint, {})


local function lazygit_toggle()
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new {
    cmd = "lazygit",
    hidden = true,
    direction = "float",
    float_opts = {
      border = "none",
      width = 100000,
      height = 100000,
      zindex = 200,
    },
    on_open = function(_)
      vim.cmd "startinsert!"
    end,
    on_close = function(_) end,
    count = 99,
  }
  lazygit:toggle()
end

local function telescope_ivy_opts(extra)
  local themes = require("telescope.themes")
  local base = themes.get_ivy {
    sorting_strategy = "ascending",
    layout_strategy = "bottom_pane",
    prompt_prefix = ">> ",
  }
  return vim.tbl_deep_extend("force", base, extra or {})
end

local function find_lazy_pack_files()
  local builtin = require("telescope.builtin")
  local lazy_root = require("lazy.core.config").options.root
  local runtime_root = vim.fn.stdpath("data")
  builtin.find_files(telescope_ivy_opts {
    prompt_title = "~ Lazy pack files ~",
    cwd = runtime_root,
    search_dirs = { lazy_root },
  })
end

local function grep_lazy_pack_files()
  local builtin = require("telescope.builtin")
  local lazy_root = require("lazy.core.config").options.root
  local runtime_root = vim.fn.stdpath("data")
  builtin.live_grep(telescope_ivy_opts {
    prompt_title = "~ search Lazy pack ~",
    cwd = runtime_root,
    search_dirs = { lazy_root },
  })
end

local function find_config_files()
  local builtin = require("telescope.builtin")
  local config_root = vim.fn.stdpath("config")
  local runtime_root = vim.fn.stdpath("data")
  builtin.find_files(telescope_ivy_opts {
    prompt_title = "~ Nvim config files ~",
    cwd = runtime_root,
    search_dirs = { config_root },
  })
end

local function grep_config_files()
  local builtin = require("telescope.builtin")
  local config_root = vim.fn.stdpath("config")
  local runtime_root = vim.fn.stdpath("data")
  builtin.live_grep(telescope_ivy_opts {
    prompt_title = "~ search Nvim config ~",
    cwd = runtime_root,
    search_dirs = { config_root },
  })
end

Nvim.which_key = {
  { "<leader>d", group = "Debug" },
  { "<leader>g", group = "Git" },
  { "<leader>r", group = "[R]ename / Run" },
  { "<leader>b", group = "Buffers" },
  { "<leader>s", group = "Search" },
  { "<leader>p", group = "Plugins" },
  { "<leader>T", group = "Treesitter" },
  { "<leader>t", group = "Trouble" },
  { "<leader>u", group = "LSP" },
  { "<leader>U", group = "Config / Lazy" },
  { "<leader>w", group = "Workspace" },

  { "<leader>q", "<cmd>confirm q<CR>", desc = "Quit" },
  { "<leader>sq", function() Nvim.select_current_nvim_jupyter_kernel_in_current_buffer() end,
    desc = "Check Jupyter Kernel" },
  { "<leader>E", "<cmd>Neotree toggle remote<cr>", desc = "Neotree Remote" },

  { "<leader>UF", find_lazy_pack_files, desc = "Find Lazy pack files" },
  { "<leader>UG", grep_lazy_pack_files, desc = "Grep Lazy pack files" },
  { "<leader>Uf", find_config_files, desc = "Find LunarVim files" },
  { "<leader>Ug", grep_config_files, desc = "Grep LunarVim files" },

  { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Jump" },
  { "<leader>bf", "<cmd>Telescope buffers previewer=false<cr>", desc = "Find" },
  { "<leader>bb", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous" },
  { "<leader>bn", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
  { "<leader>bW", "<cmd>noautocmd w<cr>", desc = "Save without formatting (noautocmd)" },
  { "<leader>be", "<cmd>BufferLinePickClose<cr>", desc = "Pick which buffer to close" },
  { "<leader>bi", "<cmd>BufferLinePickClose<cr>", desc = "Pick which buffer to close" },
  { "<leader>bh", "<cmd>BufferLineCloseLeft<cr>", desc = "Close all to the left" },
  { "<leader>bl", "<cmd>BufferLineCloseRight<cr>", desc = "Close all to the right" },
  { "<leader>bD", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
  { "<leader>bL", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by language" },
  { "<leader>bk", "<cmd>BufferLineSortByRelativeDirectory<cr>", desc = "Sort by relative directory" },
  { "<leader>bc", "<cmd>BDelete hidden<cr>", desc = "close hidden buffer (not in windws)" },


  { "<leader>ta", ":Limelight<cr>", desc = "Limelight" },
  { "<leader>tA", ":Limelight!<cr>", desc = "Limelight All" },
  { "<leader>td", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Trouble Buffer Diagnostics" },
  { "<leader>tf", "<cmd>Trouble lsp_definitions<cr>", desc = "Trouble Definitions" },
  { "<leader>tl", "<cmd>Trouble loclist<cr>", desc = "Trouble Location List" },
  { "<leader>tq", "<cmd>Trouble quickfix<cr>", desc = "Trouble Quickfix" },
  { "<leader>tr", "<cmd>Trouble lsp_references<cr>", desc = "Trouble References" },
  { "<leader>tw", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble Workspace Diagnostics" },

  {
    mode = { "n", "v" },
    { "<leader>ua", "<cmd>lua require('actions-preview').code_actions()<cr>", desc = "Code Action" },
  },
  { "<leader>ur", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },
  { "<leader>uA", "<cmd>lua require('inlayhint-filler').fill()<cr>", desc = "Inlayhint Filler" },
  { "<leader>uh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
    desc = "Toggle Inlay Hints" },
  { "<leader>ut", "<cmd>TSContextToggle<cr>", desc = "Toggle Treesitter Context" },
  { "<leader>uo", "<cmd>Neogen<cr>", desc = "Document Generate" },
  { "<leader>uka", function() require("user.copilot").quickchat(true) end, desc = "CopilotChat Quick Chat" },
  { "<leader>uka", function() require("user.copilot").quickchat_visual(true) end, mode = "v",
    desc = "CopilotChat Quick Chat" },
  { "<leader>uki", function() require("user.copilot").quickchat(false) end, desc = "CopilotChat Quick Chat Panel" },
  { "<leader>uki", function() require("user.copilot").quickchat_visual(false) end, mode = "v",
    desc = "CopilotChat Quick Chat Panel" },
  { "<leader>ukk", function() require("user.copilot").prompt_action() end, desc = "CopilotChat Prompt Action" },
  { "<leader>ukk", function() require("user.copilot").prompt_action() end, mode = "v", desc = "CopilotChat Prompt Action" },
  { "<leader>ukw", function() require("user.copilot").no_context_chat() end, desc = "CopilotChat No Context Chat" },
  { "<leader>ud", "<cmd>Telescope diagnostics bufnr=0 theme=get_ivy<cr>", desc = "Buffer Diagnostics" },
  { "<leader>uw", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
  { "<leader>uf", "<cmd>lua require('conform').format { async = true, lsp_format = 'fallback' }<cr>", desc = "Format" },
  { "<leader>ui", "<cmd>LspInfo<cr>", desc = "Info" },
  { "<leader>uI", "<cmd>Mason<cr>", desc = "Mason Info" },
  { "<leader>ul", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action" },
  { "<leader>uq", "<cmd>lua vim.diagnostic.setloclist()<cr>", desc = "Quickfix" },
  { "<leader>us", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
  { "<leader>uS",
    "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
    desc = "Workspace Symbols",
  },
  { "<leader>ue", "<cmd>Telescope quickfix<cr>", desc = "Telescope Quickfix" },

  { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
  { "<leader>s.", function()
    local builtin = require("telescope.builtin")
    local opts = { previewer = true }

    local ok = pcall(builtin.git_files, opts)
    if not ok then
      builtin.find_files(opts)
    end
  end, desc = "Project Files" },
  { "<leader>sa", function() require("swenv.api").pick_venv() end, desc = "Select Python Env" },
  { "<leader>sb", function() require("telescope").extensions.dap.list_breakpoints() end, desc = "Breakpoints" },
  { "<leader>sd", "<cmd>CderOpen<cr>", desc = "Change Directory" },
  { "<leader>sm", function() require("telescope").extensions.media_files.media_files() end, desc = "Media" },
  { "<leader>sF", "<cmd>Telescope file_browser<cr>", desc = "File Browser" },
  { "<leader>sG", "<cmd>Telescope live_grep_args<cr>", desc = "Live Grep Args" },
  { "<leader>si", "<cmd>lua telescope_interestingwords_selected(false)<cr>", desc = "Search Interesting Words" },
  { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
  { "<leader>so", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
  { "<leader>sr", "<cmd>Telescope file_browser path=%:p:h initial_mode=normal grouped=true<cr>",
    desc = "File Browser Here" },
  { "<leader>ss", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  { "<leader>su", "<cmd>Telescope telescope-tabs list_tabs<cr>", desc = "Tabs" },
  { "<leader>sw", "<cmd>ListTabWindows<cr>", desc = "List Windows" },
  { "<leader>sy", "<cmd>Telescope neoclip theme=get_ivy<cr>", desc = "Yank History" },
  { "<leader>s`", "<cmd>Telescope marks<cr>", desc = "Marks" },
  { "<leader>s'", "<cmd>execute 'Telescope find_files default_text=' . expand('<cfile>')<cr>", desc = "File Under Cursor" },
  { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Commands History" },
  { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Find File" },
  { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
  { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Find highlight groups" },
  { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
  { "<leader>so", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
  { "<leader>sR", "<cmd>Telescope registers<cr>", desc = "Registers" },
  { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Text" },
  { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
  { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
  -- { "<leader>sl", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
  -- { "<leader>sp", "<cmd>lua require('telescope.builtin').colorscheme({enable_preview = true})<cr>", desc = "Colorscheme with Preview", }

  { "<leader>d;", function() require("telescope").extensions.dap.commands() end, desc = "DAP Commands" },
  {
    "<leader>dL",
    function()
      if Nvim.DAPUI and type(Nvim.DAPUI.toggle_auto_open) == "function" then
        Nvim.DAPUI.toggle_auto_open()
      else
        vim.notify("DAP UI is not initialized yet", vim.log.levels.WARN)
      end
    end,
    desc = "Toggle UI Auto-Open"
  },
  { "<leader>d`", function() require("dap").restart() end, desc = "DAP Restart" },
  {
    "<leader>dU",
    function()
      if Nvim.DAPUI and type(Nvim.DAPUI.toggle_with_layout) == "function" then
        Nvim.DAPUI.toggle_with_layout({ reset = true })
      else
        require("dapui").toggle({ reset = true })
      end
    end,
    desc = "DAP UI Toggle"
  },
  { "<leader>d\\", "<cmd>lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>" },
  { "<leader>dfW", ":diffoff!<cr>", desc = "Diff Off All" },
  { "<leader>dlc", function()
    require("persistent-breakpoints.api").set_breakpoint(
      vim.fn.input("Breakpoint condition: "),
      vim.fn.input("Hit condition: "),
      nil
    )
  end, desc = "Conditional Breakpoint" },
  { "<leader>dle", "<cmd>DAPEditBreakpoint<cr>", desc = "Edit Breakpoint" },
  { "<leader>dll", function()
    require("persistent-breakpoints.api").set_breakpoint(
      vim.fn.input("Breakpoint condition: "),
      vim.fn.input("Hit condition: "),
      vim.fn.input("Log point message: ")
    )
  end, desc = "Conditional Logpoint" },
  { "<leader>d\\", function() require("persistent-breakpoints.api").clear_all_breakpoints() end,
    desc = "Clear All Breakpoints" },
  { "<leader>dfe", ":windo set noscrollbind<cr>", desc = "Disable Scrollbind In All Windows" },
  { "<leader>dfs", ":set scrollbind!<cr>", desc = "Toggle Scrollbind" },
  { "<leader>dft", ":diffthis<cr>", desc = "Diff This" },
  { "<leader>dfw", ":diffoff<cr>", desc = "Diff Off" },

  { "<leader>gD", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview History (Current File)" },
  { "<leader>gI", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Line Blame" },
  { "<leader>gm", "<cmd>Flogsplit<cr>", desc = "Flogsplit" },
  { "<leader>gv", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview History" },
  { "<leader>gj", "<cmd>Floggit blame<cr>", desc = "Floggit blame" },
  { "<leader>gg", lazygit_toggle, desc = "Lazygit" },
  { "<leader>gi", "<cmd>lua require 'gitsigns'.nav_hunk('prev', {navigation_message = false})<cr>", desc = "Prev Hunk" },
  { "<leader>gk", "<cmd>lua require 'gitsigns'.nav_hunk('next', {navigation_message = false})<cr>", desc = "Next Hunk" },
  { "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<cr>", desc = "Blame" },
  { "<leader>gL", "<cmd>lua require 'gitsigns'.blame_line({full=true})<cr>", desc = "Blame Line (full)" },
  { "<leader>gp", "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", desc = "Preview Hunk" },
  {
    mode = { "n", "v" },
    { "<leader>gr", "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", desc = "Reset Hunk" },
    { "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", desc = "Stage Hunk" },
  },
  { "<leader>gR", "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", desc = "Reset Buffer" },
  { "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", desc = "Undo Stage Hunk" },
  { "<leader>go", "<cmd>Telescope git_status<cr>", desc = "Open changed file" },
  { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
  { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit" },
  { "<leader>gC", "<cmd>Telescope git_bcommits<cr>", desc = "Checkout commit(for current file)" },
  { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>", desc = "Git Diff" },

  { "<leader>pi", "<cmd>Lazy install<cr>", desc = "Install" },
  { "<leader>ps", "<cmd>Lazy sync<cr>", desc = "Sync" },
  { "<leader>pS", "<cmd>Lazy clear<cr>", desc = "Status" },
  { "<leader>pc", "<cmd>Lazy clean<cr>", desc = "Clean" },
  { "<leader>pu", "<cmd>Lazy update<cr>", desc = "Update" },
  { "<leader>pp", "<cmd>Lazy profile<cr>", desc = "Profile" },
  { "<leader>pl", "<cmd>Lazy log<cr>", desc = "Log" },
  { "<leader>pd", "<cmd>Lazy debug<cr>", desc = "Debug" },

  { '<leader>Oa', '<cmd>lua require("ufo").closeAllFolds()<cr>', desc = "Folding Code (Close All)" },
  { '<leader>Od', '<cmd>lua require("ufo").openAllFolds()<cr>', desc = "Folding Code (Open All)" },
  { "<leader>Ox", "zx", desc = "Update All Folds" },

  { "<leader>t'", "<cmd>tab split<CR>", desc = "Tab Split" },
  { "<leader>t\\", "<cmd>tabclose<CR>", desc = "Tab Close" },

  { "<leader>Ti", ":TSConfigInfo<cr>", desc = "Info" },

  { "<leader>Tw", "<cmd>TodoTrouble<cr>", desc = "Todo Trouble" },
  { "<leader>Td", "<cmd>Trouble todo filter.buf=0<cr>", desc = "Todo Trouble (Current Buffer)" },
}
