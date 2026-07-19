-- WindowsTerminal.lua
local M = {}

-- 定义一个函数来查找 Windows Terminal 的 settings.json 文件路径并打开它
function M.find_and_edit_terminal_settings()
  -- 使用 `io.popen` 调用 `where wt.exe` 获取路径
  local wt_path_handle = io.popen "where wt.exe 2>nul"
  if not wt_path_handle then
    print "Failed to execute command to find wt.exe."
    return
  end

  local wt_path = wt_path_handle:read("*a"):gsub("\\", "/"):gsub("\n", "")
  wt_path_handle:close()

  -- 如果没有找到 wt.exe，wt_path 会是空的
  if wt_path == "" then
    print "wt.exe not found."
    return
  end

  -- 提取用户目录
  local user_dir = wt_path:match "C:/Users/([^/]+)/"

  if user_dir then
    -- 构建 Microsoft.WindowsTerminalPreview 目录的位置
    local base_dir = string.format("C:/Users/%s/AppData/Local/Packages/", user_dir)
    local command = 'Get-ChildItem -Path "'
        .. base_dir
        .. '" -Filter "Microsoft.WindowsTerminal*" -Directory | Select-Object -ExpandProperty FullName'

    local terminal_dirs_handle = io.popen('pwsh -Command "' .. command .. '"')

    if not terminal_dirs_handle then
      print "Failed to locate the Windows Terminal directory."
      return
    end

    local results = {}
    for line in terminal_dirs_handle:lines() do
      table.insert(results, line)
    end
    terminal_dirs_handle:close()

    if results == "" then
      print "Microsoft.WindowsTerminal* directory not found."
      return
    end

    local input_message = ""
    local input_message_table = {}
    for i, dir in ipairs(results) do
      table.insert(input_message_table, string.format("%d. %s\\LocalState\\settings.json", i, dir))
    end
    input_message = table.concat(input_message_table, "\n")

    -- 构建 settings.json 文件的完整路径
    local choice = 0
    if #results == 1 then
      choice = 1
    else
      choice = tonumber(vim.fn.input("Select want to open settings.json:\n" .. input_message .. "\nInput number: "))
      if not choice or choice < 1 or choice > #results then
        print "\nInvalid Number"
        return
      end
    end
    local selected_dir = results[choice]
    local settings_path = selected_dir .. "/LocalState/settings.json"

    -- 检查文件是否存在
    local file = io.open(settings_path, "r")
    if file then
      file:close()
      -- 编辑找到的 settings.json 文件
      vim.cmd("e " .. settings_path)
    else
      print "settings.json not found."
    end
  else
    print "Could not determine user directory."
  end
end

return M
