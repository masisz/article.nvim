local M = {}

---Format items for vim.ui.select
---@return { lang: string, desc: string }[]
local function get_available_languages()
  local config = require("article.config").get()
  local list = {}

  for lang, def in pairs(config.blocks) do
    table.insert(list, {
      lang = lang,
      desc = def.desc or (def.cmd and ("Run with " .. def.cmd) or "Template block"),
    })
  end

  -- Sort alphabetically, but keep bash/zsh/sh/powershell/python towards the top
  local priority = { bash = 1, zsh = 2, powershell = 3, pwsh = 4, sh = 5, python = 6, dockerfile = 7, yaml = 8 }
  table.sort(list, function(a, b)
    local pa = priority[a.lang] or 99
    local pb = priority[b.lang] or 99
    if pa ~= pb then
      return pa < pb
    end
    return a.lang < b.lang
  end)

  return list
end

---Insert a code block of the given language at cursor position
---@param lang string
---@param bufnr? number
function M.insert(lang, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] -- 1-indexed

  local config = require("article.config").get()
  local block_def = config.blocks[lang] or {}

  local lines = { "```" .. lang }
  local cursor_offset = 1 -- line inside the block to place cursor

  if block_def.template then
    if type(block_def.template) == "table" then
      for _, l in ipairs(block_def.template) do
        table.insert(lines, l)
      end
    elseif type(block_def.template) == "string" then
      for l in block_def.template:gmatch("(.-)\n") do
        table.insert(lines, l)
      end
    end
  else
    table.insert(lines, "")
  end
  table.insert(lines, "```")

  -- Insert lines after current line
  vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)

  -- Place cursor inside the block
  vim.api.nvim_win_set_cursor(0, { row + cursor_offset + 1, 0 })
  vim.cmd("startinsert")
end

---Interactive prompt to select a language and insert code block
---@param bufnr? number
function M.prompt_insert(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local items = get_available_languages()

  -- Add an option for arbitrary language input
  table.insert(items, { lang = "[Custom...]", desc = "Enter another language manually" })

  vim.ui.select(items, {
    prompt = "Select Code Block Language:",
    format_item = function(item)
      return string.format("%-14s %s", item.lang, item.desc and ("- " .. item.desc) or "")
    end,
  }, function(choice)
    if not choice then
      return
    end

    if choice.lang == "[Custom...]" then
      vim.ui.input({ prompt = "Language name: " }, function(custom_lang)
        if custom_lang and #custom_lang > 0 then
          M.insert(vim.trim(custom_lang:lower()), bufnr)
        end
      end)
    else
      M.insert(choice.lang, bufnr)
    end
  end)
end

return M
