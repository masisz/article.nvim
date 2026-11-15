-- Test usurai catalog sync
local config = require("article.config")

-- 1. Sync enabled with usurai present
vim.opt.rtp:append("/Users/miso/devs/public-git/usurai.nvim")

local opts_synced = config.setup({ usurai_sync = true })
assert(opts_synced.blocks.shell ~= nil, "shell block should be synced from usurai")
assert(opts_synced.blocks.docker ~= nil, "docker block should be synced from usurai")
assert(opts_synced.blocks.godot ~= nil, "godot block should be synced from usurai")

-- 2. Sync disabled
local opts_isolated = config.setup({
  usurai_sync = false,
  blocks = {
    custom_only = { desc = "isolated" },
  },
})
assert(opts_isolated.blocks.godot == nil, "godot block should NOT be synced when usurai_sync is false")
assert(opts_isolated.blocks.custom_only ~= nil, "custom block should exist")

print("usurai sync spec passed successfully!")
