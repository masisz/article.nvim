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

-- Verify TIOBE Top 10 additions
assert(opts.blocks.c ~= nil, "c block should exist")
assert(opts.blocks.go ~= nil, "go block should exist")
assert(opts.blocks.java ~= nil, "java block should exist")
assert(opts.blocks.csharp ~= nil, "csharp block should exist")
assert(opts.blocks.sql ~= nil, "sql block should exist")
assert(opts.blocks.r ~= nil, "r block should exist")

print("All TIOBE language definitions verified successfully!")
