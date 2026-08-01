require "user.core.autocmds"
require("user.core.lunar").setup()
require "config"
require "user.builtin.keymappings".load(Nvim.keys)
