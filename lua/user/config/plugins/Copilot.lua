local M = {}

function M.setup()
  require("copilot").setup {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      hide_during_completion = true,
      debounce = 15,
      trigger_on_accept = true,
      keymap = {
        -- NOTE: Let blink.cmp own <Tab> to avoid duplicate mappings.
        -- See: https://github.com/zbirenbaum/copilot.lua/issues/670
        -- accept = "<Tab>",
        accept = false,
        accept_word = false,
        accept_line = false,
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
        toggle_auto_trigger = false,
      },
    },
    panel = {
      enabled = false,
    },
    nes = {
      enabled = true,
      keymap = {
        accept_and_goto = "<Tab>",
        accept = false,
        dismiss = "<S-Tab>",
      },
    },
    filetypes = {
      -- upstream internal defaults copied locally so behavior is explicit
      markdown = true,
      yaml = true,
      help = false,
      gitcommit = false,
      gitrebase = false,
      hgcommit = false,
      svn = false,
      cvs = false,
      ["."] = false,

      ["dapui_scopes"] = false,
      ["dapui_breakpoints"] = false,
      ["dapui_stacks"] = false,
      ["dapui_watches"] = false,
      ["dap-repl"] = false,
      ["dapui_console"] = false,
    },
  }
end

return M
