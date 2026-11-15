local config = require("article.config")

local M = {}

---Scan directory for article files and extract metadata (title, modified time)
---@param dir string
---@param extension string
---@return { path: string, filename: string, title: string, mtime: number }[]
function M.scan_articles(dir, extension)
  local files = {}
  local fs = vim.uv.fs_scandir(dir)
  if not fs then
    return files
  end

  local ext_pattern = "%." .. extension .. "$"

  while true do
    local name, type = vim.uv.fs_scandir_next(fs)
    if not name then
      break
    end
    if type == "file" and name:match(ext_pattern) then
      local path = vim.fs.joinpath(dir, name)
      local stat = vim.uv.fs_stat(path)
      local mtime = 0
      if stat and stat.mtime then
        mtime = stat.mtime.sec + (stat.mtime.nsec or 0) * 1e-9
      end

      -- Extract title from first heading
      local title = name
      local f = io.open(path, "r")
      if f then
        for line in f:lines() do
          local heading = line:match("^#%s+(.+)")
          if heading then
            title = vim.trim(heading)
            break
          end
        end
        f:close()
      end

      table.insert(files, {
        path = path,
        filename = name,
        title = title,
        mtime = mtime,
      })
    end
  end

  -- Sort by newest first, then filename descending
  table.sort(files, function(a, b)
    if a.mtime ~= b.mtime then
      return a.mtime > b.mtime
    end
    return a.filename > b.filename
  end)

  return files
end

---Open article picker with fuzzy search
---@param opts? table
function M.open(opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})
  local dir = vim.fs.normalize(vim.fn.expand(cfg.directory))

  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Article: Directory not found: " .. dir, vim.log.levels.WARN)
    return
  end

  -- 1. Try Snacks.picker if available (integrated with usurai.nvim)
  if _G.Snacks and Snacks.picker then
    local articles = M.scan_articles(dir, cfg.extension)
    if #articles == 0 then
      vim.notify("Article: No articles found in " .. dir, vim.log.levels.INFO)
      return
    end

    local items = {}
    for _, art in ipairs(articles) do
      table.insert(items, {
        text = string.format("%s  │  %s", art.filename, art.title),
        file = art.path,
        title = art.title,
      })
    end

    Snacks.picker.pick({
      source = "articles",
      title = "Articles (" .. dir .. ")",
      items = items,
      format = function(item)
        return {
          { item.file and vim.fs.basename(item.file) or "", "Directory" },
          { "  │  ", "Comment" },
          { item.title or "", "Normal" },
        }
      end,
      preview = "file",
      confirm = function(picker, item)
        picker:close()
        if item and item.file then
          vim.cmd.edit(item.file)
        end
      end,
    })
    return
  end

  -- 2. Try Telescope if available
  local has_tele, tele_builtin = pcall(require, "telescope.builtin")
  if has_tele then
    tele_builtin.find_files({
      prompt_title = "Articles (" .. dir .. ")",
      cwd = dir,
    })
    return
  end

  -- 3. Fallback to native vim.ui.select
  local articles = M.scan_articles(dir, cfg.extension)
  if #articles == 0 then
    vim.notify("Article: No articles found in " .. dir, vim.log.levels.INFO)
    return
  end

  vim.ui.select(articles, {
    prompt = "Select Article to Open:",
    format_item = function(item)
      return string.format("%-32s  │  %s", item.filename, item.title)
    end,
  }, function(choice)
    if choice then
      vim.cmd.edit(choice.path)
    end
  end)
end

---Grep inside article directory
---@param opts? table
function M.grep(opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})
  local dir = vim.fs.normalize(vim.fn.expand(cfg.directory))

  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Article: Directory not found: " .. dir, vim.log.levels.WARN)
    return
  end

  if _G.Snacks and Snacks.picker then
    Snacks.picker.grep({
      cwd = dir,
      title = "Grep Articles (" .. dir .. ")",
    })
    return
  end

  local has_tele, tele_builtin = pcall(require, "telescope.builtin")
  if has_tele then
    tele_builtin.live_grep({
      prompt_title = "Grep Articles (" .. dir .. ")",
      cwd = dir,
    })
    return
  end

  vim.notify("Article: Snacks.picker or Telescope required for live grep", vim.log.levels.WARN)
end

return M
