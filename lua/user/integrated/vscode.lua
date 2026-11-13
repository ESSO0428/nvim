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

--- Can `code` on this machine open the files in the user's VS Code?
---@return boolean ok, string reason
function M.can_run_code_locally()
  -- VS Code 整合終端機（含 Remote-SSH）：code 會送回目前視窗
  -- 需確認 socket 還在，tmux 會保留 VS Code 關掉後已失效的變數
  local ipc = vim.env.VSCODE_IPC_HOOK_CLI
  if ipc and ipc ~= "" and (vim.uv or vim.loop).fs_stat(ipc) then
    return true, "vscode-terminal"
  end
  -- WSL，且 code 是 Windows VS Code 的 shim（interop 正常）
  if vim.fn.has("wsl") == 1 and vim.fn.exepath("code"):find("^/mnt/") then
    return true, "wsl"
  end
  return false, "remote"
end

-- :Code 自動判斷：能在本機直接跑 code 就跑，否則走 :Rcode（遠端 server → Windows VS Code Remote-SSH）
function _G.code(file)
  if M.can_run_code_locally() then
    return M.code_local(file)
  end
  return _G.rcode(file)
end

function M.code_local(file)
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

-- ------------------------------------------------------------------
-- Reverse ssh tunnel
-- port 由 Nvim.vscode_remote.tunnel_port() 查（~/.ssh/rssh_tunnel.d/<本機 IP>，或舊的 ~/.rssh_tunnel）
-- WSL 端是 `ncat -l --keep-open <port> -e /bin/sh`（reverse-ssh-tunnel-manager）
-- sh 的輸出會沿同一條連線傳回來，所以可以「送指令到 WSL 並拿回結果」
-- ------------------------------------------------------------------
local function sh_quote(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

---@return string|nil port, string|nil err
function M.tunnel_port()
  local port, source = Nvim.vscode_remote.tunnel_port()
  if not source then
    return nil, "找不到 tunnel port（請先在 WSL 執行 reverse-ssh-tunnel-manager）"
  end
  if not port then
    return nil, source .. " 沒有 port（tunnel 已關閉？）"
  end
  if vim.fn.executable("nc") == 0 then
    return nil, "這台 server 沒有 nc"
  end
  return port
end

--- Run a shell command on the WSL side through the tunnel; cb(stdout) runs on the main loop
---@param remote_cmd string
---@param cb fun(out: string)
---@return boolean started, string|nil err
function M.tunnel_exec(remote_cmd, cb)
  local port, err = M.tunnel_port()
  if not port then
    return false, err
  end
  -- keep stdin open until the WSL side answers and closes; the echo loop ends via SIGPIPE once nc exits
  local script = [[(printf '%s\nexit\n' "$1"; i=0; while [ $i -lt 40 ]; do sleep 0.2; echo; i=$((i+1)); done) | nc -w 10 127.0.0.1 "$2"]]
  vim.system({ "sh", "-c", script, "sh", remote_cmd, port }, { text = true, timeout = 20000 },
    vim.schedule_wrap(function(res)
      cb(res.stdout or "")
    end))
  return true
end

-- 與 `vscode remote ssh` 集成
-- 取得如範例的指令: `code --remote ssh-remote+LabServerDP`
-- hostname 由 GetServerHostName() 查 ~/.ssh/host_names.d/<本機 IP>（或舊的 ~/.ssh/host_names）
-- ---
-- 有 reverse ssh tunnel 時，直接請 WSL 呼叫 powershell.exe 在 Windows 開啟 VS Code；
-- 沒有 tunnel 或執行失敗時，照舊把指令寫入 ~/.NeovimVscode.log 並開啟，讓你複製到 PowerShell。
-- 設 `vim.g.rcode_via_tunnel = false` 可停用自動執行。
-- ---
-- 特別注意 `vim.g.host` 若使用範例的 `YourVscodeReomoteServerName` 會被視為排除對象
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

  local function show_log(str)
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

  if M.is_match_exclude_hostname(M.host) == 1 then
    return show_log("Failed : Not found usefull hostname\n" ..
      "Use left command to Update hostname from Windows PC sshconfig to current Server :UpdateRegisterHostHameFromLocal\n"
      ..
      "P.S. : Check local open reverse ssh port to current remote server")
  end

  -- 将主机名转换为 JSON 格式，再转换为十六进制编码
  local jsonHost = '{"hostName":"' .. M.host .. '"}'
  local hexHost = M.encodeHostname(jsonHost)
  local remote = "code --remote ssh-remote+" .. hexHost
  local quoted = {}
  for _, target in ipairs(targets) do
    table.insert(quoted, ps_quote(target))
  end

  -- copy/paste form (multi-line with PowerShell backtick continuation)
  local open_dir = remote .. " `\n" .. ps_quote(cwd)
  local str = open_dir
  if #quoted > 0 then
    str = open_dir .. "; `\n" .. open_dir .. " `\n" .. "-g `\n" .. table.concat(quoted, " `\n")
  end

  if vim.g.rcode_via_tunnel == false then
    return show_log(str)
  end

  -- one-line form for `powershell.exe -Command`
  local ps = remote .. " " .. ps_quote(cwd)
  if #quoted > 0 then
    ps = ps .. "; " .. remote .. " " .. ps_quote(cwd) .. " -g " .. table.concat(quoted, " ")
  end
  -- cd /mnt/c: powershell.exe refuses a Linux cwd (UNC path warning)
  local wsl_cmd = "cd /mnt/c 2>/dev/null; powershell.exe -NoProfile -NonInteractive -Command "
      .. sh_quote(ps) .. " >/dev/null 2>&1; echo RCODE_EXIT=$?"

  local started = M.tunnel_exec(wsl_cmd, function(out)
    local exit_code = out:match("RCODE_EXIT=(%d+)")
    if exit_code == "0" then
      vim.notify("Rcode: 已在 Windows 開啟 VS Code（" .. M.host .. "）")
    else
      vim.notify("Rcode: 無法透過 tunnel 執行 PowerShell（"
        .. (exit_code and ("exit " .. exit_code) or "tunnel 沒有回應")
        .. "），改為顯示指令，請手動貼到 PowerShell", vim.log.levels.WARN)
      show_log(str)
    end
  end)
  if started then
    vim.notify("Rcode: 透過 tunnel 在 Windows 開啟 VS Code 中…")
  else
    show_log(str)
  end
end

-- 登錄這台 server 對應的 Windows ssh config Host 別名（:UpdateRegisterHostHameFromLocal）
-- 透過 tunnel 請 WSL 執行 `vscode-remote-host-sync --lookup <本機 IP...>`，答案沿同一條連線傳回，
-- 再寫入本機 ~/.ssh/host_names.d/<IP>。不需要從 Windows ssh 回來，所以跳板機也能用。
M.remote_sync_cmd = '"$HOME/bin/vscode-remote-host-sync"'

function M.register_host_from_local()
  local vr = Nvim.vscode_remote
  local function err(msg)
    vim.notify("UpdateRegisterHostHameFromLocal: " .. msg, vim.log.levels.ERROR)
  end

  local current, current_ip = vr.lookup_host()
  if current then
    local choice = vim.fn.confirm(
      ("目前登錄：%s（%s）\n要從 Windows ssh config 重新取得嗎？"):format(current, current_ip), "&Yes\n&No", 2)
    if choice ~= 1 then return end
  end

  local ips = vr.local_ipv4s()
  if #ips == 0 then
    return err("取不到本機 IP")
  end

  local remote_cmd = M.remote_sync_cmd .. " --lookup " .. table.concat(ips, " ") .. " 2>&1"
  local started, tunnel_err = M.tunnel_exec(remote_cmd, function(out)
    local ip, host
    for line in out:gmatch("[^\r\n]+") do
      local a, b = line:match("^(%d+%.%d+%.%d+%.%d+)%s+([%w._-]+)%s*$")
      if a and vim.tbl_contains(ips, a) then
        ip, host = a, b
        break
      end
    end
    if not host then
      local detail = vim.trim(out) ~= "" and ("\nWSL 回應：" .. vim.trim(out)) or ""
      return err("Windows ssh config 裡沒有 HostName 等於 " .. table.concat(ips, " / ") .. " 的 Host，"
        .. "或 tunnel 沒有回應（WSL 需有 ~/bin/vscode-remote-host-sync）。"
        .. "也可以在 WSL 手動執行：vscode-remote-host-sync <Host>" .. detail)
    end

    local dir = vr.host_names_dir
    vim.fn.mkdir(dir, "p")
    local target = dir .. "/" .. ip
    local tmp = ("%s.tmp.%d"):format(target, vim.fn.getpid())
    if vim.fn.writefile({ host }, tmp) ~= 0 then
      return err("無法寫入 " .. tmp)
    end
    local ok, rename_err = (vim.uv or vim.loop).fs_rename(tmp, target)
    if not ok then
      os.remove(tmp)
      return err("無法寫入 " .. target .. "：" .. tostring(rename_err))
    end
    vim.g.host, M.host = host, host
    vim.notify(("UpdateRegisterHostHameFromLocal: 已登錄 %s → %s"):format(ip, host))
  end)
  if not started then
    return err(tunnel_err)
  end
  vim.notify("UpdateRegisterHostHameFromLocal: 透過 tunnel 查詢中（" .. table.concat(ips, ", ") .. "）…")
end

return M
