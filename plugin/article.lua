if vim.g.loaded_article == 1 then
  return
end
vim.g.loaded_article = 1

-- Initialize defaults if setup hasn't been called explicitly
require("article").setup()

-- User commands
vim.api.nvim_create_user_command("ArticleNew", function(opts)
  local title = opts.args ~= "" and opts.args or nil
  if title then
    require("article").create(title)
  else
    require("article").new()
  end
end, {
  nargs = "*",
  desc = "Create a new article in directory",
})

vim.api.nvim_create_user_command("ArticleList", function()
  require("article").list()
end, { desc = "List and fuzzy find articles" })

vim.api.nvim_create_user_command("ArticleGrep", function()
  require("article").grep()
end, { desc = "Grep inside articles directory" })

vim.api.nvim_create_user_command("ArticleRun", function()
  require("article").run()
end, { desc = "Run code block under cursor" })

vim.api.nvim_create_user_command("ArticleNext", function()
  require("article").next()
end, { desc = "Run current block and jump to next" })

vim.api.nvim_create_user_command("ArticleInsert", function(opts)
  local lang = opts.args ~= "" and opts.args or nil
  require("article").insert_block(lang)
end, {
  nargs = "?",
  complete = function()
    local blocks = require("article.config").get().blocks
    local candidates = {}
    for lang, _ in pairs(blocks) do
      table.insert(candidates, lang)
    end
    table.sort(candidates)
    return candidates
  end,
  desc = "Insert a new code block",
})

vim.api.nvim_create_user_command("ArticleEdit", function()
  require("article").edit_block()
end, { desc = "Edit current block in dedicated buffer" })

vim.api.nvim_create_user_command("ArticleClear", function()
  require("article").clear_output()
end, { desc = "Clear output block under cursor" })
