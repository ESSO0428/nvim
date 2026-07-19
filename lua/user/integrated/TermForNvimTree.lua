local M = {}

local function get_buf_size()
  local cbuf = vim.api.nvim_get_current_buf()
  local bufinfo = vim.tbl_filter(function(buf)
    return buf.bufnr == cbuf
  end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]

  if bufinfo == nil then
    return { width = vim.o.columns, height = vim.o.lines }
  end

  return { width = bufinfo.width, height = bufinfo.height }
end

local function get_dynamic_terminal_size(direction)
  local sizes = get_buf_size()
  if direction == "horizontal" then
    return math.max(12, math.floor(sizes.height * 0.35))
  elseif direction == "vertical" then
    return math.max(40, math.floor(sizes.width * 0.45))
  end
  return nil
end

local function get_node_context(state)
  local node = nil
  if state and state.tree and type(state.tree.get_node) == "function" then
    local ok, value = pcall(function()
      return state.tree:get_node()
    end)
    if ok then
      node = value
    end
  end

  if node then
    local abspath = node.link_to or node.path or node:get_id()
    local is_folder = node.type == "directory"
    local basedir = is_folder and abspath or vim.fn.fnamemodify(abspath, ":h")
    return {
      basedir = basedir,
      abspath = abspath,
      is_folder = is_folder,
    }
  end

  local abspath = vim.api.nvim_buf_get_name(0)
  if abspath == "" then
    abspath = vim.fn.getcwd()
  end
  local stat = vim.uv.fs_stat(abspath)
  local is_folder = stat and stat.type == "directory" or false
  local basedir = is_folder and abspath or vim.fn.fnamemodify(abspath, ":h")

  return {
    basedir = basedir,
    abspath = abspath,
    is_folder = is_folder,
  }
end

local function terminal_count(direction)
  if direction == "horizontal" then
    return 101
  elseif direction == "vertical" then
    return 102
  end
  return 103
end

local function toggle_terminal(opts)
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new {
    cmd = opts.cmd,
    dir = opts.basedir,
    hidden = true,
    direction = opts.direction,
    close_on_exit = opts.close_on_exit ~= false,
    count = opts.count or terminal_count(opts.direction),
    size = opts.direction ~= "float" and function()
      return get_dynamic_terminal_size(opts.direction)
    end or nil,
  }
  term:toggle()
end

local function get_terminal_opts(direction, state)
  local ctx = get_node_context(state)
  return {
    direction = direction,
    basedir = ctx.basedir,
    abspath = ctx.abspath,
    is_folder = ctx.is_folder,
    count = terminal_count(direction),
  }
end

function M.exec_toggle(opts)
  toggle_terminal(vim.tbl_extend("force", opts, {
    close_on_exit = false,
  }))
end

function M.exec_toggleFzfRg(opts)
  toggle_terminal(vim.tbl_extend("force", opts, {
    direction = opts.direction or "horizontal",
    cmd = "fzf_rg",
    close_on_exit = false,
  }))
end

function M.exec_toggleBatOrMore(opts)
  if opts.is_folder then
    print("Cannot use bat/more to open a directory.")
    return
  end

  local file_cmd
  if vim.fn.executable("bat") == 1 then
    file_cmd = "bat --paging=always --style=full --wrap=never " .. vim.fn.shellescape(opts.abspath)
  else
    file_cmd = "more " .. vim.fn.shellescape(opts.abspath)
  end

  toggle_terminal(vim.tbl_extend("force", opts, {
    direction = "float",
    cmd = file_cmd,
    close_on_exit = true,
  }))
end

function M.exec_cder(opts)
  require("telescope").extensions.cder.cder {
    dir_command = { "fd", "--type=d", ".", opts.basedir },
    previewer_command = "exa -a --color=always -T --level=3 --icons --git-ignore --long --no-permissions --no-user --no-filesize --git --ignore-glob=.git",
    theme = "get_ivy",
  }
end

function M.exec_ToDoTelescope(opts)
  vim.cmd("TodoTelescope cwd=" .. vim.fn.fnameescape(opts.basedir) .. " theme=get_ivy")
end

function _G.nvimtreeToggleTerm(term_mode, state)
  M.exec_toggle(get_terminal_opts(term_mode, state))
end

function _G.nvimtreeToggleTermFzfRg(term_mode, state)
  M.exec_toggleFzfRg(get_terminal_opts(term_mode, state))
end

function _G.nvimtreeToggleTermMore(term_mode, state)
  M.exec_toggleBatOrMore(get_terminal_opts(term_mode, state))
end

function _G.nvimtreeCder(term_mode, state)
  M.exec_cder(get_terminal_opts(term_mode, state))
end

function _G.nvimtreeToDoTelescope(term_mode, state)
  M.exec_ToDoTelescope(get_terminal_opts(term_mode, state))
end

function _G.float_term(...)
  local state = select("#", ...) > 0 and (...) or nil
  nvimtreeToggleTerm("float", state)
end

function _G.horizontal_term(...)
  local state = select("#", ...) > 0 and (...) or nil
  nvimtreeToggleTerm("horizontal", state)
end

function _G.vertical_term(...)
  local state = select("#", ...) > 0 and (...) or nil
  nvimtreeToggleTerm("vertical", state)
end

function _G.horizontal_termFzfRg(...)
  local state = select("#", ...) > 0 and (...) or nil
  nvimtreeToggleTermFzfRg("horizontal", state)
end

function _G.float_termMore(...)
  local state = select("#", ...) > 0 and (...) or nil
  nvimtreeToggleTermMore("float", state)
end

return M
