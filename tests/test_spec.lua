local parser = require("article.parser")
local renderer = require("article.renderer")
local executor = require("article.executor")

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("Assertion failed: %s != %s. %s", vim.inspect(a), vim.inspect(b), msg or ""))
  end
end

-- 1. Test ANSI Stripping
local dirty = "\27[31mError:\27[0m Failed at step 1\r\n"
local clean = executor.strip_ansi(dirty)
assert_eq(clean, "Error: Failed at step 1\n", "ANSI stripping failed")

-- 2. Test Parser & Renderer on buffer
local bufnr = vim.api.nvim_create_buf(false, true)
local sample_lines = {
  "# Testing article.nvim",
  "",
  "```bash",
  "echo 'Hello from article.nvim'",
  "```",
  "",
  "Some text in between",
  "",
  "```python",
  "print(2 + 3)",
  "```",
}
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sample_lines)

-- Test parser on first block
local b1 = parser.get_current_block(bufnr, 3)
assert(b1 ~= nil, "Failed to find block 1")
assert_eq(b1.lang, "bash", "Block 1 lang mismatch")
assert_eq(b1.code, "echo 'Hello from article.nvim'", "Block 1 code mismatch")

-- Test renderer inserting output
renderer.render_output(b1, "Hello from article.nvim")

local updated_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
assert_eq(updated_lines[6], "```output", "Output block not inserted")
assert_eq(updated_lines[7], "Hello from article.nvim", "Output content mismatch")
assert_eq(updated_lines[8], "```", "Output block end not found")

-- Re-parse block with output block attached
local b1_with_out = parser.get_current_block(bufnr, 3)
assert(b1_with_out.output_block ~= nil, "Output block not recognized")

-- Test re-rendering (updating)
renderer.render_output(b1_with_out, "Updated output")
local updated_lines2 = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
assert_eq(updated_lines2[7], "Updated output", "Output block replacement failed")

-- Test get_next_block
local b2 = parser.get_next_block(bufnr, 3)
assert(b2 ~= nil, "Failed to get next block")
assert_eq(b2.lang, "python", "Next block lang mismatch")

print("All tests passed successfully!")
