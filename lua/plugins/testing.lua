return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      "nvim-neotest/nvim-nio"
    },
    cmd = { "Neotest", "NeotestFile", "NeotestNearest", "NeotestSuite", "NeotestSummary", "NeotestJump" }
  },
}
