function! EscapeChars(str, ...)
  " 默認需要跳脫的字元清單
  let default_chars = ['\']
  
  " 使用提供的字元清單或默認清單
  let chars_to_escape = a:0 > 0 ? a:1 : default_chars
  
  " 將所有需要跳脫的字元建立成一個字元類別
  " 需要先對特殊字元進行跳脫，以便在正則表達式中使用
  let escaped_chars = map(copy(chars_to_escape), {_, char -> escape(char, '\/.*$^~[]')})
  
  " 將字元陣列合併成一個字元集合
  let char_class = join(escaped_chars, '')
  
  " 構建正則表達式，捕獲需要跳脫的字元並在前面插入反斜線
  " 使用 \( \) 進行分組，使用 \1 引用匹配到的字元
  let pattern = '[' . char_class . ']'
  let result = substitute(a:str, pattern, '\\\0', 'g')
  
  return result
endfunction

function! DownloadToLocal(file)
  " 去除參數左右的空白
  let file = substitute(a:file, '^\s*\|\s*$', '', 'g')

  let current_file = empty(file) || file ==# '%' ? expand('%:p') : file

  if filereadable(expand("~/.rssh_tunnel"))
    let port = readfile(expand("~/.rssh_tunnel"))[0]
    let netstat_cmd = "netstat -tuln | grep -q '127.0.0.1:" . port . "' && echo success"
    let tunnel_status = substitute(system(netstat_cmd), '\n', '', '')

    if tunnel_status ==# 'success'
      echo "Downloading this file or directory to your Windows local download folder..."

      " 準備在遠端執行的完整 bash 指令
      let awk_main_script_start = "'{"
      let awk_main_script_end = "}'"
      let scp_prepare_command = join([
        \ "ps -x | grep localhost:" . port . " | grep ssh | grep -v grep", 
        \ " | awk '{for (i=5; i<=NF; i++) printf \"%s \", \$i; print \"\"}'",
        \ " | awk " . awk_main_script_start,
        \ "port=\"\"; jump=\"\"; userhost=\"\"; ",
        \ "for (i=1;i<=NF;i++) ", 
        \ "{ ",
        \ "if (\$i==\"-p\") port=\$i\" \"\$(i+1); sub(/^-p/, \"-P\", port); ",
        \ "if (\$i==\"-J\") jump=\$i\" \"\$(i+1); ", 
        \ "if (\$i ~ /@/) userhost=\" \"\$i;",
        \ "} "
      \ ], "")

      let windows_path = "/mnt/c/Users/\$(wslvar USERNAME)/Downloads/"

      " 根據是目錄還是檔案決定加不加 -r
      let scp_dir_arg = isdirectory(current_file) ? "-r" : ""
      
      let open_download_explorer_command = "explorer.exe \$(wslpath -w '/mnt/c/Users/'\$(wslvar USERNAME)'/Downloads/') >/dev/null 2>&1"
      let full_remote_command = scp_prepare_command .
        \ " printf \"scp %s %s %s %s:%s %s >/dev/null 2>&1 && %s \"," . "\"" . scp_dir_arg  . "\", " . "port, jump, userhost, \"" . current_file . "\", \"" . windows_path . "\", " . "\"" . open_download_explorer_command . "\""
        \ . awk_main_script_end
      let full_remote_command = EscapeChars(full_remote_command, ['\', '"', '$'])

      " 最重要：用雙引號包住 echo !!
      let final_send_command = "echo \"" . full_remote_command . " | sh" . "\" | nc -w 1 127.0.0.1 " . port . " &"

      " scp and open explorer
      call system(final_send_command)
    else
      echo "Reverse SSH tunnel is not active"
    endif
  else
    echo "Tunnel config not found!"
  endif
endfunction

" 创建自定义命令，例如 :DownloadToLocal 文件名或目錄名
command! -nargs=? DownloadToLocal :call DownloadToLocal(<q-args>)

" 登錄這台 server 對應的 Windows ssh config Host 別名（給 :Rcode 用）
" 實作在 lua/user/integrated/vscode.lua：透過 reverse ssh tunnel 向 WSL 的
" vscode-remote-host-sync 查詢，寫入 ~/.ssh/host_names.d/<本機 IP>
command! -nargs=0 UpdateRegisterHostHameFromLocal lua require("user.integrated.vscode").register_host_from_local()
