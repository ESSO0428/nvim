-- Claude Code prompt：把 @.../.claude|.agents/skills/<name>/... 縮成 /<name>
local function claude_skill_shorten()
  local view = vim.fn.winsaveview()
  -- 用 # 當分隔符，避免路徑裡的 / 要跳脫；\v 下 @ 是特殊字元所以寫 \@
  vim.cmd([=[keeppatterns silent! %s#\v\@\S*/\.(claude|agents)/skills/([^/[:space:]]+)(/\S*)?#/\2#ge]=])
  vim.fn.winrestview(view)
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("ClaudePromptSkills", { clear = true }),
  pattern = "*/claude-*/claude-prompt-*.md",
  callback = function(args)
    vim.keymap.set("n", "<leader>=", claude_skill_shorten, {
      buffer = args.buf,
      desc = "Claude: @skill path → /skill-name",
    })
  end,
})
