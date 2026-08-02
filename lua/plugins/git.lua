return {
  -- { "tpope/vim-fugitive" },
  {
    "ESSO0428/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Gstatus" },
  },
  {
    "rbong/vim-flog",
    dependencies = {
      "ESSO0428/vim-fugitive",
    },
    cmd = { "Flog", "Floggit", "Flogsplit" },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    config = function()
      require("user.config.plugins.DiffView").setup()
    end,
  },
}
