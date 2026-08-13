return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-python",
    },
    cmd = { "Neotest", "NeotestFile", "NeotestNearest", "NeotestSuite", "NeotestSummary", "NeotestJump" },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = {
              justMyCode = false,
              console = "integratedTerminal"
            },
            -- args = { "--log-level", "DEBUG" },
            args = { "-vv", "-s" },
            runner = "pytest"
          }),
        }
      })
    end
  },
}
