local M = {}

local config = require("article.config")
local parser = require("article.parser")
local executor = require("article.executor")
local renderer = require("article.renderer")
local creator = require("article.creator")
local editor = require("article.editor")

---Setup plugin options and global keymaps
---@param opts? table
function M.setup(opts)
  local cfg = config.setup(opts)

  if cfg.keymaps.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("ArticlePluginKeys", { clear = true }),
      pattern = { "markdown", "pandoc" },
      callback = function(ev)
        local km = cfg.keymaps
        local function map(lhs, fn, desc)
          if lhs and lhs ~= false then
            vim.keymap.set("n", lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
          end
        end

        map(km.run, M.run, "Article: Run code block")
        map(km.next, M.next, "Article: Run & jump to next block")
        map(km.insert, M.insert_block, "Article: Insert code block")
        map(km.edit, M.edit_block, "Article: Edit block in dedicated buffer")
        map(km.clear, M.clear_output, "Article: Clear output block")
      end,
    })
  end
end

---Run current code block and update output fence
---@param bufnr? number
---@param on_complete? fun(success: boolean)
function M.run(bufnr, on_complete)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local block = parser.get_current_block(bufnr)

  if not block then
    vim.notify("Article: No code block under cursor", vim.log.levels.WARN)
    if on_complete then
      on_complete(false)
    end
    return
  end

  vim.notify(string.format("Article: Running [%s]...", block.lang), vim.log.levels.INFO)

  executor.execute(block, function(result)
    -- Re-fetch block to avoid stale line references
    local fresh_block = parser.get_current_block(bufnr, block.start_line)
    if fresh_block then
      renderer.render_output(fresh_block, result.output)
      if result.success then
        vim.notify(string.format("Article: [%s] completed", block.lang), vim.log.levels.INFO)
      else
        vim.notify(string.format("Article: [%s] finished with errors", block.lang), vim.log.levels.WARN)
      end
    end
    if on_complete then
      on_complete(result.success)
    end
  end)
end

---Run current block and advance cursor to the next block
function M.next()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]

  M.run(bufnr, function()
    local next_b = parser.get_next_block(bufnr, cur_line)
    if next_b then
      vim.api.nvim_win_set_cursor(0, { next_b.code_start, 0 })
      vim.notify("Article: Moved to next step", vim.log.levels.INFO)
    else
      vim.notify("Article: Reached the last step", vim.log.levels.INFO)
    end
  end)
end

---Open current block in a dedicated buffer (Emacs C-c ' style)
function M.edit_block()
  local block = parser.get_current_block()
  if not block then
    vim.notify("Article: No code block under cursor", vim.log.levels.WARN)
    return
  end
  editor.open(block)
end

---Insert a new code block
---@param lang? string
function M.insert_block(lang)
  if lang and #lang > 0 then
    creator.insert(lang)
  else
    creator.prompt_insert()
  end
end

---Clear output block below current code block
function M.clear_output()
  local block = parser.get_current_block()
  if not block then
    vim.notify("Article: No code block under cursor", vim.log.levels.WARN)
    return
  end

  if renderer.clear_output(block) then
    vim.notify("Article: Output cleared", vim.log.levels.INFO)
  else
    vim.notify("Article: No output block found", vim.log.levels.INFO)
  end
end

return M
