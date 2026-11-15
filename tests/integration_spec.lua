local article = require("article")

local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(bufnr)

local sample = {
  "# Testing Article Run",
  "",
  "```bash",
  "echo 'Step 1: System Check'",
  "```",
}
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sample)
vim.api.nvim_win_set_cursor(0, { 3, 0 })

local completed = false
article.run(bufnr, function(success)
  completed = true
  assert(success == true, "Execution should succeed")
end)

vim.wait(3000, function()
  return completed
end, 50)

assert(completed, "Execution did not finish within timeout")

local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
local found_output = false
for _, line in ipairs(lines) do
  if line:find("Step 1: System Check") then
    found_output = true
    break
  end
end
assert(found_output, "Output fence not rendered with output content")

print("Integration test passed successfully!")
