local config = require("article.config")

local M = {}

---Sanitize title string for filesystem filename
---@param title string
---@return string
local function slugify(title)
  -- Trim whitespace and lowercase
  local s = vim.trim(title):lower()
  -- Replace spaces and special characters with hyphens
  s = s:gsub("[%s_/\\:]+", "-")
  -- Remove unwanted symbols but keep alphanumeric, hyphens, and unicode characters (for Japanese, etc.)
  s = s:gsub("[^%w%-%z\128-\255]", "")
  -- Collapse consecutive hyphens
  s = s:gsub("%-+", "-")
  -- Trim leading/trailing hyphens
  s = s:gsub("^%-+", ""):gsub("%-+$", "")
  return s
end

---Generate next available file path
---@param directory string
---@param date_format string
---@param extension string
---@param title? string
---@return string filepath, string final_title
local function get_next_path(directory, date_format, extension, title)
  local date = os.date(date_format)
  local clean_title = title and vim.trim(title) or ""

  if clean_title ~= "" then
    local slug = slugify(clean_title)
    local base_name = string.format("%s-%s.%s", date, slug, extension)
    local path = vim.fs.joinpath(directory, base_name)
    if not vim.uv.fs_stat(path) and vim.fn.bufnr(path) == -1 then
      return path, clean_title
    end
    -- If already exists, append sequence
    local seq = 2
    repeat
      local name = string.format("%s-%s-%02d.%s", date, slug, seq, extension)
      path = vim.fs.joinpath(directory, name)
      seq = seq + 1
    until not vim.uv.fs_stat(path) and vim.fn.bufnr(path) == -1
    return path, clean_title
  else
    local seq = 1
    local path
    repeat
      local name = string.format("%s-%02d.%s", date, seq, extension)
      path = vim.fs.joinpath(directory, name)
      seq = seq + 1
    until not vim.uv.fs_stat(path) and vim.fn.bufnr(path) == -1
    return path, "Untitled"
  end
end

---Resolve template lines
---@param template (string|fun():string)[]
---@param title string
---@return string[]
local function resolve_template(template, title)
  local lines = {}
  for _, line in ipairs(template) do
    local text = type(line) == "function" and tostring(line()) or tostring(line)
    -- Replace [Title] marker with actual title if provided
    text = text:gsub("%[Title%]", title)
    lines[#lines + 1] = text
  end
  return lines
end

---Create and open a new article file
---@param title? string
---@param opts? table
---@return string? Filepath
function M.create_article(title, opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})
  local dir = vim.fs.normalize(vim.fn.expand(config.resolve_directory(cfg.directory)))

  -- Ensure directory exists
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  local filepath, final_title = get_next_path(dir, cfg.date_format, cfg.extension, title)
  local lines = resolve_template(cfg.template, final_title)

  -- Write file atomically
  local f = io.open(filepath, "w")
  if not f then
    vim.notify("Article: Failed to write to " .. filepath, vim.log.levels.ERROR)
    return nil
  end
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()

  -- Open file in buffer
  pcall(vim.cmd.edit, filepath)

  -- Set initial cursor position
  local cursor_pos = cfg.cursor_pos or { 7, 0 }
  local total_lines = vim.api.nvim_buf_line_count(0)
  local target_row = math.min(cursor_pos[1], total_lines)
  pcall(vim.api.nvim_win_set_cursor, 0, { target_row, cursor_pos[2] or 0 })
  vim.cmd("startinsert")

  vim.notify("Article: Created " .. vim.fs.basename(filepath), vim.log.levels.INFO)
  return filepath
end

---Prompt user for title and create article
---@param opts? table
function M.prompt_create(opts)
  vim.ui.input({ prompt = "Article Title (optional): " }, function(title)
    if title ~= nil then
      M.create_article(title, opts)
    end
  end)
end

return M
