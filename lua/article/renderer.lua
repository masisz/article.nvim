local M = {}

---Split multiline string into array of lines
---@param text string
---@return string[]
local function split_lines(text)
  local lines = {}
  -- normalize line endings
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  -- remove the extra trailing line added by loop if empty
  if #lines > 1 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end
  return lines
end

---Render or update output block for a code block
---@param block ArticleBlockInfo
---@param output string
---@return { start_line: number, end_line: number }
function M.render_output(block, output)
  local config = require("article.config").get()
  local bufnr = block.bufnr
  local output_lang = config.output_lang

  local out_lines = split_lines(output)
  local replacement = {
    "```" .. output_lang,
  }
  for _, l in ipairs(out_lines) do
    table.insert(replacement, l)
  end
  table.insert(replacement, "```")

  if block.output_block then
    -- Replace existing output block
    local start_idx = block.output_block.start_line - 1
    local end_idx = block.output_block.end_line
    vim.api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, replacement)
    local new_end = start_idx + #replacement
    return { start_line = start_idx + 1, end_line = new_end }
  else
    -- Insert right after code block end
    local insert_idx = block.end_line
    vim.api.nvim_buf_set_lines(bufnr, insert_idx, insert_idx, false, replacement)
    local new_end = insert_idx + #replacement
    return { start_line = insert_idx + 1, end_line = new_end }
  end
end

---Remove output block if present
---@param block ArticleBlockInfo
---@return boolean was_cleared
function M.clear_output(block)
  if not block.output_block then
    return false
  end
  local bufnr = block.bufnr
  local start_idx = block.output_block.start_line - 1
  local end_idx = block.output_block.end_line
  vim.api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, {})
  block.output_block = nil
  return true
end

return M
