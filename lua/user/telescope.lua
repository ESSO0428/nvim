Nvim.keys.normal_mode["<leader>s/"] = { "<cmd>Telescope search_history<cr>", { desc = "[S]earch [/] History" } }
Nvim.keys.normal_mode["<leader>s`"] = { "<cmd>Telescope marks<cr>", { desc = "[S]earch Marks" } }
Nvim.keys.normal_mode["<leader>s'"] = {
  "<cmd>execute 'Telescope find_files default_text=' . expand('<cfile>')<cr>",
  { desc = "[S]earch File Under Cursor" },
}
Nvim.keys.normal_mode["<leader>sc"] = { "<cmd>Telescope command_history<cr>", { desc = "[S]earch [C]ommand History" } }
Nvim.keys.normal_mode["<leader>sh"] = { "<cmd>Telescope help_tags<cr>", { desc = "[S]earch [H]elp" } }
Nvim.keys.normal_mode["<leader>sH"] = { "<cmd>Telescope highlights<cr>", { desc = "[S]earch [H]ighlights" } }
Nvim.keys.normal_mode["<leader>sF"] = { "<cmd>Telescope file_browser<cr>", { desc = "[S]earch [F]ile Browser" } }
Nvim.keys.normal_mode["<leader>sG"] = { "<cmd>Telescope live_grep_args<cr>", { desc = "[S]earch Live [G]rep Args" } }
Nvim.keys.normal_mode["<leader>sk"] = { "<cmd>Telescope keymaps<cr>", { desc = "[S]earch [K]eymaps" } }
Nvim.keys.normal_mode["<leader>sj"] = { "<cmd>Telescope jumplist<cr>", { desc = "[S]earch [J]umplist" } }
Nvim.keys.normal_mode["<leader>sl"] = { "<cmd>Telescope tagstack<cr>", { desc = "[S]earch Tagstack" } }
Nvim.keys.normal_mode["<leader>sM"] = { "<cmd>Telescope man_pages<cr>", { desc = "[S]earch [M]an Pages" } }
Nvim.keys.normal_mode["<leader>sn"] = { "<cmd>Telescope notify<cr>", { desc = "[S]earch [N]otify" } }
Nvim.keys.normal_mode["<leader>sf"] = { "<cmd>Telescope find_files<cr>", { desc = "[S]earch [F]iles" } }
Nvim.keys.normal_mode["<leader>sg"] = { "<cmd>Telescope live_grep<cr>", { desc = "[S]earch by [G]rep" } }
Nvim.keys.normal_mode["<leader>sa"] = {
  function()
    require("swenv.api").pick_venv()
  end,
  { desc = "[S]earch Select Python Env" },
}
Nvim.keys.normal_mode["<leader>sb"] = {
  function()
    require("telescope").extensions.dap.list_breakpoints()
  end,
  { desc = "[S]earch [B]reakpoints" },
}
Nvim.keys.normal_mode["<leader>sd"] = { "<cmd>CderOpen<cr>", { desc = "[S]earch Change [D]irectory" } }
Nvim.keys.normal_mode["<leader>sm"] = {
  function()
    require("telescope").extensions.media_files.media_files()
  end,
  { desc = "[S]earch [M]edia" },
}
Nvim.keys.normal_mode["<leader>sp"] = {
  function()
    require("telescope.builtin").colorscheme({ enable_preview = true })
  end,
  { desc = "[S]earch [P]alette" },
}
Nvim.keys.normal_mode["<leader>sR"] = { "<cmd>Telescope registers<cr>", { desc = "[S]earch [R]egisters" } }
Nvim.keys.normal_mode["<leader>uw"] = { "<cmd>Telescope diagnostics<cr>", { desc = "[S]earch [D]iagnostics" } }
Nvim.keys.normal_mode["<leader>ur"] = { "<cmd>Telescope resume<cr>", { desc = "[S]earch [R]esume" } }
Nvim.keys.normal_mode["<leader>so"] = { "<cmd>Telescope oldfiles<cr>", { desc = '[S]earch Recent Files ("." for repeat)' } }
Nvim.keys.normal_mode["<leader>sr"] = {
  "<cmd>Telescope file_browser path=%:p:h initial_mode=normal grouped=true<cr>",
  { desc = "[S]earch File Browser Here" },
}
Nvim.keys.normal_mode["<leader>ss"] = { "<cmd>Telescope buffers<cr>", { desc = "[ ] Find existing buffers" } }
Nvim.keys.normal_mode["<c-f>"] = {
  function()
    require("telescope.builtin").current_buffer_fuzzy_find()
  end,
  { desc = "[/] Fuzzily search in current buffer" },
}
Nvim.keys.normal_mode["<leader><c-f>"] = {
  function()
    require("telescope.builtin").live_grep {
      grep_open_files = true,
      prompt_title = "Live Grep in Open Files",
    }
  end,
  { desc = "[S]earch [/] in Open Files" },
}
