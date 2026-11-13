local M = {}
M.host = vim.g.host

function M.encodeHostname(jsonHost)
  local hexHostname = ""
  for i = 1, #jsonHost do
    local byte = string.byte(jsonHost, i)
    hexHostname = hexHostname .. string.format("%02x", byte)
  end
  return hexHostname
end

function M.is_match_exclude_hostname(hostname)
  local is_match_exclude_hostname_bool = vim.fn.index(
    { "YourVscodeReomoteServerName", "" }
    , hostname) ~= -1 and 1 or -1
  return is_match_exclude_hostname_bool
end

--- Quote an argument for PowerShell (single quotes, `'` doubled) when needed
local function ps_quote(arg)
  if arg:find("[%s'`\"$&|;(){}<>,@#]") then
    return "'" .. arg:gsub("'", "''") .. "'"
  end
  return arg
end

--- Collect `file:line:col` targets.
--- nil / "" -> all listed file buffers (current buffer first, with cursor position)
--- "%"      -> current buffer
--- other    -> given file, with the current cursor position
---@param file string|nil
---@return string[]
local function collect_targets(file)
  local location = vim.api.nvim_win_get_cursor(0)
  local function with_pos(name)
    return name .. ":" .. location[1] .. ":" .. location[2] + 1
  end

  local targets = {}
  if file == "" or file == nil then
    local current = vim.api.nvim_get_current_buf()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buffer)
      -- skip unnamed / special buffers (terminal, scratch, help...)
      if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].buflisted
          and vim.bo[buffer].buftype == "" and name ~= "" then
        if buffer == current then
          table.insert(targets, 1, with_pos(name))
        else
          table.insert(targets, name)
        end
      end
    end
  elseif file == "%" then
    local name = vim.fn.expand("%:p")
    if name ~= "" then
      table.insert(targets, with_pos(name))
    end
  else
    table.insert(targets, with_pos(file))
  end
  return targets
end

function _G.code(file)
  local targets = collect_targets(file)

  local cwd = vim.fn.getcwd()
  if not cwd:find("/$") then
    cwd = cwd .. "/"
  end

  -- shellescape(…, true) also escapes `!`, `%`, `#` for :!
  local args = { "code", "-g", vim.fn.shellescape(cwd, true) }
  for _, target in ipairs(targets) do
    table.insert(args, vim.fn.shellescape(target, true))
  end
  vim.cmd("!" .. table.concat(args, " "))
end

-- 與 `vscode remote ssh` 集成
-- 取得如範例的指令: `code --remote ssh-remote+LabServerDP`
-- 通過讀取 `~/.ssh/host_names` 文件，來取得對上述 `hostname`
-- 如果 `~/.ssh/host_names` 文件`不存在`或`格式有誤`則使用預設的 `vim.g.host`
-- 或是最後一次使用的 hostname，這些 name 將後將寫入 `vim.g.host`
-- ---
-- 特別注意 `vim.g.host` 若使用範例的 `YourVscodeReomoteServerName` 會被視為排除對象
-- ---
-- 找不到 `hostname` 或是 `hostname` 為排除對象，則會報錯提醒如何更新 `hostname`
---@param file string | nil
function _G.rcode(file)
  local host = GetServerHostName(M.host)
  M.host = host

  local targets = collect_targets(file)
  local cwd = vim.fn.getcwd()
  if cwd:find("/$") then
    cwd = cwd:sub(1, -2)
  end

  local str
  if M.is_match_exclude_hostname(M.host) == 1 then
    str = "Failed : Not found usefull hostname\n" ..
        "Use left command to Update hostname from Windows PC sshconfig to current Server :UpdateRegisterHostHameFromLocal\n"
        ..
        "P.S. : Check local open reverse ssh port to current remote server"
  else
    -- 将主机名转换为 JSON 格式，再转换为十六进制编码
    local jsonHost = '{"hostName":"' .. M.host .. '"}'
    local hexHost = M.encodeHostname(jsonHost)
    local quoted = {}
    for _, target in ipairs(targets) do
      table.insert(quoted, ps_quote(target))
    end
    str = "code --remote ssh-remote+" .. hexHost .. " `\n" .. ps_quote(cwd)
    str = str .. "; `\n" ..
        str ..
        " `\n" .. "-g `\n" .. table.concat(quoted, " `\n")
  end

  -- 將指令字串寫入檔案
  local logFile = vim.fn.expand("~/.NeovimVscode.log")
  local f, err = io.open(logFile, "w")
  if not f then
    vim.notify("rcode: cannot write " .. logFile .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  f:write(str)
  f:close()

  -- 使用tabnew命令打開新標籤頁顯示檔案
  vim.cmd("tabnew " .. vim.fn.fnameescape(logFile))
end

return M
