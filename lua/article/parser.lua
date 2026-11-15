local M = {}

---@class ArticleOutputBlock
---@field start_line number 1-indexed line of opening ```output
---@field end_line number 1-indexed line of closing ```

---@class ArticleBlockInfo
---@field bufnr number
---@field lang string
---@field start_line number 1-indexed opening fence line
---@field end_line number 1-indexed closing fence line
---@field code_start number 1-indexed first code line
---@field code_end number 1-indexed last code line
---@field code string
---@field lines string[]
---@field output_block? ArticleOutputBlock

---Find code block under cursor or at specific line
---@param bufnr? number
---@param cursor_line? number 1-indexed
---@param output_lang? string
---@return ArticleBlockInfo?
function M.get_current_block(bufnr, cursor_line, output_lang)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cursor_line = cursor_line or vim.api.nvim_win_get_cursor(0)[1]
  output_lang = output_lang or require("article.config").get().output_lang

  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  if total_lines == 0 then
    return nil
  end

  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- First, collect all fenced blocks
  local blocks = {}
  local current_open = nil

  for idx, line in ipairs(all_lines) do
    local fence_lang = line:match("^%s*```+([%w_%-]+)")
    local fence_close = line:match("^%s*```+%s*$")

    if not current_open and fence_lang then
      current_open = {
        lang = fence_lang:lower(),
        start_line = idx,
      }
    elseif current_open and fence_close then
      local block = {
        bufnr = bufnr,
        lang = current_open.lang,
        start_line = current_open.start_line,
        end_line = idx,
        code_start = current_open.start_line + 1,
        code_end = idx - 1,
      }
      table.insert(blocks, block)
      current_open = nil
    end
  end

  -- Find the block that encloses or is closest to cursor_line
  -- Ignore blocks that are themselves output blocks (```output)
  local target_block = nil
  for _, b in ipairs(blocks) do
    if b.lang ~= output_lang:lower() then
      if cursor_line >= b.start_line and cursor_line <= b.end_line then
        target_block = b
        break
      end
    end
  end

  -- If cursor is directly on or just above/below an output block associated with a block,
  -- allow finding the parent block
  if not target_block then
    for i, b in ipairs(blocks) do
      if b.lang ~= output_lang:lower() then
        -- Check if cursor is on the immediate output block following this block
        local next_b = blocks[i + 1]
        if next_b and next_b.lang == output_lang:lower() and next_b.start_line == b.end_line + 1 then
          if cursor_line >= next_b.start_line and cursor_line <= next_b.end_line then
            target_block = b
            break
          end
        end
      end
    end
  end

  if not target_block then
    return nil
  end

  -- Extract code lines
  local code_lines = {}
  if target_block.code_start <= target_block.code_end then
    for l = target_block.code_start, target_block.code_end do
      table.insert(code_lines, all_lines[l] or "")
    end
  end
  target_block.lines = code_lines
  target_block.code = table.concat(code_lines, "\n")

  -- Check if there is an immediately following output block
  local check_line = target_block.end_line + 1
  -- Skip blank lines if any
  while check_line <= total_lines and all_lines[check_line]:match("^%s*$") do
    check_line = check_line + 1
  end

  if check_line <= total_lines then
    local out_lang = all_lines[check_line]:match("^%s*```+([%w_%-]+)")
    if out_lang and out_lang:lower() == output_lang:lower() then
      local out_start = check_line
      local out_end = nil
      for l = out_start + 1, total_lines do
        if all_lines[l]:match("^%s*```+%s*$") then
          out_end = l
          break
        end
      end
      if out_end then
        target_block.output_block = {
          start_line = out_start,
          end_line = out_end,
        }
      end
    end
  end

  return target_block
end

---Find the next code block after a given line
---@param bufnr? number
---@param after_line? number 1-indexed
---@param output_lang? string
---@return ArticleBlockInfo?
function M.get_next_block(bufnr, after_line, output_lang)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  after_line = after_line or vim.api.nvim_win_get_cursor(0)[1]
  output_lang = output_lang or require("article.config").get().output_lang

  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  for line = after_line + 1, total_lines do
    local block = M.get_current_block(bufnr, line, output_lang)
    if block and block.start_line > after_line then
      return block
    end
  end
  return nil
end

return M
