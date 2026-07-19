-- NOTE: 由於 Weissle/persistent-breakpoints.nvim 不包含 set_breakpoint 因此自行新增了如下函數
-- 或者改用我的 Fork 版本 (ESSO0428/persistent-breakpoints.nvim) 即可不定義以下函數
require('persistent-breakpoints.api').set_breakpoint = function(condition, logMessage, hitCondition)
  require('dap').set_breakpoint(condition, logMessage, hitCondition);
  require('persistent-breakpoints.api').breakpoints_changed_in_current_buffer()
end
