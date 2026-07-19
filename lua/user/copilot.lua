local M = {}

local did_setup = false

local function wrap_with_dapui(fn)
  if _G.Nvim and Nvim.DAPUI and type(Nvim.DAPUI.with_layout_handling_when_dapui_open) == "function" then
    return Nvim.DAPUI.with_layout_handling_when_dapui_open(fn)
  end
  return function(...)
    return fn(...)
  end
end

local function get_select_prompt_selection(select, source)
  local open_select_promt_mode = select.open_select_promt_mode
  local content = select.buffer(source)

  local visual_modes = { v = true, V = true, ["\x16"] = true }
  if visual_modes[open_select_promt_mode] then
    content = select.visual(source) or content
  end
  select.open_select_promt_mode = nil
  return content
end

local function read_copilot_prompt(file)
  local config_dir = vim.fn.stdpath("config")
  local prompt_directory = config_dir .. "/docs/CopilotChatPrompts"
  local prompt_file = prompt_directory .. "/" .. file
  local f = io.open(prompt_file, "r")
  if not f then
    return ""
  end
  local content = f:read("*all") or ""
  f:close()
  return content
end

function M.no_context_chat()
  local chat = require("CopilotChat")
  local is_focused = chat.chat:focused()
  if is_focused then
    chat.open({ selection = false })
    vim.cmd("doautocmd BufLeave")
  else
    chat.open({ selection = false })
  end
end

function M.quickchat(ask)
  local function core(_, _, ask_inner)
    local chat = require("CopilotChat")
    local is_focused = chat.chat:focused()
    local config = { selection = false }
    if not is_focused then
      config.sticky = { "#buffer" }
    end
    if ask_inner == true then
      local ok, input = pcall(vim.fn.input, "Quick Chat: ")
      if ok and input ~= "" then
        chat.ask(input, config)
      end
    else
      chat.open(config)
    end
  end

  wrap_with_dapui(core)(ask)
end

function M.quickchat_visual(ask)
  local function core(_, _, ask_inner)
    if ask_inner == true then
      local ok, input = pcall(vim.fn.input, "Quick Chat: ")
      if ok and input ~= "" then
        require("CopilotChat").ask(input, { selection = require("CopilotChat.select").visual })
      end
    else
      require("CopilotChat").open({ selection = require("CopilotChat.select").visual })
    end
  end

  wrap_with_dapui(core)(ask)
end

function M.prompt_action()
  local select = require("CopilotChat.select")
  select.open_select_promt_mode = vim.fn.mode()
  local function core()
    require("CopilotChat").select_prompt()
  end

  wrap_with_dapui(core)()
end

function M.inline()
  require("CopilotChat").ask("", {
    selection = require("CopilotChat.select").buffer,
    window = {
      layout = "float",
      relative = "cursor",
      width = 1,
      height = 0.4,
      row = 1,
    },
  })
end

function M.inline_visual()
  require("CopilotChat").ask("", {
    selection = require("CopilotChat.select").visual,
    window = {
      layout = "float",
      relative = "cursor",
      width = 1,
      height = 0.4,
      row = 1,
    },
  })
end

function M.setup()
  if did_setup then
    return
  end
  did_setup = true

  local utils = require("CopilotChat.utils")
  local select = require("CopilotChat.select")
  local buffer = select.buffer
  select.open_select_promt_mode = nil

  select.diagnostics = function(source)
    local bufnr = source.bufnr
    local winnr = source.winnr or 0
    local select_buffer = buffer(source)
    if not select_buffer then
      return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(winnr)

    local diagnostics = vim.diagnostic.get(bufnr, { lnum = cursor[1] - 1 })
    if #diagnostics == 0 then
      return nil
    end

    local messages = {}
    for _, diagnostic in ipairs(diagnostics) do
      table.insert(messages, diagnostic.message)
    end

    local result = table.concat(messages, ". "):gsub("^%s*(.-)%s*$", "%1"):gsub("\n", " ")
    local file_name = vim.api.nvim_buf_get_name(bufnr)

    return {
      content = file_name .. ":" .. cursor[1] .. ". " .. result,
      filename = vim.fn.fnamemodify(file_name, ":p:."),
      filetype = vim.bo[bufnr].filetype,
      start_line = cursor[1],
      end_line = cursor[1],
      bufnr = bufnr,
    }
  end

  local user = vim.env.USER or "User"
  user = user:sub(1, 1):upper() .. user:sub(2)

  local question_header = "  " .. user .. " "
  local answer_header = "  Copilot "

  require("CopilotChat").setup {
    model = "claude-sonnet-4.5",
    sticky = nil,
    temperature = 0.1,
    headless = false,
    callback = nil,

    window = {
      layout = "vertical",
      width = 0.5,
      height = 0.5,
      relative = "editor",
      border = "single",
      row = nil,
      col = nil,
      title = "Copilot Chat",
      footer = nil,
      zindex = 1,
      blend = 0,
    },

    show_help = true,
    show_folds = true,
    auto_fold = false,
    highlight_selection = true,
    highlight_headers = true,
    auto_follow_cursor = true,
    auto_insert_mode = false,
    insert_at_end = false,
    clear_chat_on_new_prompt = false,

    debug = false,
    log_level = "info",
    proxy = nil,
    allow_insecure = false,

    selection = "visual",
    chat_autocomplete = false,
    history_path = vim.fn.stdpath("data") .. "/copilotchat_history",

    headers = {
      user = question_header,
      assistant = answer_header,
      tool = "Tool ",
    },
    separator = "---",

    prompts = {
      Explain = {
        prompt = read_copilot_prompt("Explain.md"),
        sticky = "/COPILOT_EXPLAIN",
      },
      Ask = {
        prompt = read_copilot_prompt("Ask.md"),
        sticky = "/COPILOT_EXPLAIN",
      },
      Review = {
        prompt = read_copilot_prompt("Review.md"),
        sticky = "/COPILOT_REVIEW",
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      ReviewClear = {
        prompt = read_copilot_prompt("ReviewClear.md"),
        sticky = "/COPILOT_REVIEW",
        callback = function(response, source)
          local ns = vim.api.nvim_create_namespace("copilot_review")
          local diagnostics = {}

          for line in response:gmatch("[^\r\n]+") do
            if line:find("^line=") then
              local start_line
              local end_line
              local message
              local single_match, message_match = line:match("^line=(%d+): (.*)$")
              if not single_match then
                local start_match, end_match, m_message_match = line:match("^line=(%d+)-(%d+): (.*)$")
                if start_match and end_match then
                  start_line = tonumber(start_match)
                  end_line = tonumber(end_match)
                  message = m_message_match
                end
              else
                start_line = tonumber(single_match)
                end_line = start_line
                message = message_match
              end

              if start_line and end_line then
                table.insert(diagnostics, {
                  lnum = start_line - 1,
                  end_lnum = end_line - 1,
                  col = 0,
                  message = message,
                  severity = vim.diagnostic.severity.WARN,
                  source = "Copilot Review",
                })
              end
            end
          end
          vim.diagnostic.set(ns, source.bufnr, diagnostics)
        end,
      },
      Fix = {
        prompt = read_copilot_prompt("Fix.md"),
      },
      Optimize = {
        prompt = read_copilot_prompt("Optimize.md"),
      },
      OneLineComment = {
        prompt = read_copilot_prompt("OneLineComment.md"),
      },
      OneParagraphComment = {
        prompt = read_copilot_prompt("OneParagraphComment.md"),
      },
      Docs = {
        prompt = read_copilot_prompt("Docs.md"),
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      Tests = {
        prompt = read_copilot_prompt("Tests.md"),
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      CodeGraph = {
        prompt = read_copilot_prompt("CodeGraph.md"),
        sticky = "/COPILOT_EXPLAIN",
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      MermaidUml = {
        prompt = read_copilot_prompt("MermaidUml.md"),
        sticky = "/COPILOT_EXPLAIN",
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      MermaidSequence = {
        prompt = read_copilot_prompt("MermaidSequence.md"),
        sticky = "/COPILOT_EXPLAIN",
        selection = function(source)
          return get_select_prompt_selection(select, source)
        end,
      },
      FixDiagnostic = {
        prompt = read_copilot_prompt("FixDiagnostic.md"),
        selection = select.diagnostics,
      },
      Commit = {
        prompt = read_copilot_prompt("Commit.md"),
        sticky = "#gitdiff:unstaged",
      },
      CommitStaged = {
        prompt = read_copilot_prompt("CommitStaged.md"),
        sticky = "#gitdiff:staged",
      },
    },

    mappings = {
      complete = {
        insert = "<Tab>",
      },
      close = {
        normal = "q",
        insert = "<C-c>",
      },
      reset = {
        normal = "<C-l>",
        insert = "<C-l>",
      },
      submit_prompt = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      toggle_sticky = {
        normal = "grr",
      },
      clear_stickies = {
        normal = "grx",
      },
      accept_diff = {
        normal = "<C-y>",
        insert = "<C-y>",
      },
      jump_to_diff = {
        normal = "gD",
      },
      quickfix_answers = {
        normal = "gqa",
      },
      quickfix_diffs = {
        normal = "gqd",
      },
      yank_diff = {
        normal = "gy",
        register = '"',
      },
      show_diff = {
        normal = "gd",
        full_diff = false,
      },
      show_info = {
        normal = "gc",
      },
      show_help = {
        normal = "g?",
      },
    },
  }

  local copilot_functions = require("CopilotChat.config.functions")
  copilot_functions.gitdiff = {
    group = "copilot",
    uri = "git://diff/{target}",
    description = "Retrieves git diff information. Requires git to be installed.",

    schema = {
      type = "object",
      required = { "target" },
      properties = {
        target = {
          type = "string",
          description = "Target to diff against.",
          enum = { "unstaged", "staged", "<sha>" },
          default = "unstaged",
        },
      },
    },

    resolve = function(input, source)
      local file_path = vim.api.nvim_buf_get_name(source.bufnr)
      local file_dir
      if file_path ~= "" then
        file_dir = vim.fn.fnamemodify(file_path, ":h")
        if vim.fn.isdirectory(file_dir) == 0 then
          file_dir = source.cwd()
        end
      else
        file_dir = source.cwd()
      end

      local cmd = { "git", "-C", file_dir, "diff", "--no-color", "--no-ext-diff" }
      local cmd_stat = { "git", "-C", file_dir, "diff", "--stat", "--no-color", "--no-ext-diff" }

      if input.target == "staged" then
        table.insert(cmd, "--staged")
        table.insert(cmd_stat, "--staged")
      elseif input.target == "unstaged" then
        table.insert(cmd, "--")
        table.insert(cmd_stat, "--")
      else
        table.insert(cmd, input.target)
        table.insert(cmd_stat, input.target)
      end

      local cmd_out = utils.system(cmd)
      local out = cmd_out
      if #cmd_out.stdout > 30000 then
        out = utils.system(cmd_stat)
      end
      return {
        {
          uri = "git://diff/" .. input.target,
          mimetype = "text/plain",
          data = out.stdout,
        },
      }
    end,
  }

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "copilot-*",
    callback = function()
      vim.opt_local.number = true
    end,
  })
end

return M
