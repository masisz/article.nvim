local config = require("article.config")
local opts = config.setup()

-- Verify sh is removed
assert(opts.blocks.sh == nil, "sh should be removed")

-- Verify node is split into javascript and typescript
assert(opts.blocks.javascript ~= nil, "javascript block should exist")
assert(opts.blocks.typescript ~= nil, "typescript block should exist")

-- Verify Rust, Zig, Ruby, C++ are added
assert(opts.blocks.rust ~= nil, "rust block should exist")
assert(opts.blocks.zig ~= nil, "zig block should exist")
assert(opts.blocks.ruby ~= nil, "ruby block should exist")
assert(opts.blocks.cpp ~= nil, "cpp block should exist")

print("All language definitions verified successfully!")
