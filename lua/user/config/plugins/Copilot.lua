require("copilot").setup {
  suggestion = {
    enabled = false,
    auto_trigger = false,
    hide_during_completion = true,
  },
  panel = {
    enabled = false,
  },
  filetypes = {
    ["dapui_scopes"] = false,
    ["dapui_breakpoints"] = false,
    ["dapui_stacks"] = false,
    ["dapui_watches"] = false,
    ["dap-repl"] = false,
    ["dapui_console"] = false,
  },
}
