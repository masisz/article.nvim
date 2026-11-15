local M = {}

---Open the current code block in a dedicated buffer with native filetype (Emacs C-c ' style)
---@param block ArticleBlockInfo
function M.open(block)
  local origin_buf = block.bufnr
  local origin_win = vim.api.nvim_get_current_win()

  -- Map common block language identifiers to Neovim filetypes
  local ft_map = {
    bash = "sh",
    zsh = "zsh",
    pwsh = "ps1",
    python = "python",
    javascript = "javascript",
    js = "javascript",
    typescript = "typescript",
    ts = "typescript",
    ruby = "ruby",
    rb = "ruby",
    rust = "rust",
    rs = "rust",
    zig = "zig",
    cpp = "cpp",
    ["c++"] = "cpp",
    dockerfile = "dockerfile",
    yaml = "yaml",
  }
  local filetype = ft_map[block.lang] or block.lang

  -- Create a scratch buffer
  local edit_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[edit_buf].buftype = "acwrite"
  vim.bo[edit_buf].bufhidden = "wipe"
  vim.bo[edit_buf].filetype = filetype
  vim.api.nvim_buf_set_name(edit_buf, string.format("[Article: %s]", block.lang))

  -- Populate with block code
  vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, block.lines)

  -- Calculate window layout (centered floating window or vertical split)
  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(30, math.floor(vim.o.lines * 0.7))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(edit_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" Article Code Editor [%s] ", block.lang),
    title_pos = "center",
  })

  -- Synchronize changes back to origin buffer
  local function sync_back()
    if not vim.api.nvim_buf_is_valid(origin_buf) then
      return
    end
    local new_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)

    -- Re-check parser to ensure lines haven't shifted wildly
    local parser = require("article.parser")
    local current_block = parser.get_current_block(origin_buf, block.start_line)
    if current_block then
      local start_idx = current_block.code_start - 1
      local end_idx = current_block.code_end
      vim.api.nvim_buf_set_lines(origin_buf, start_idx, end_idx, false, new_lines)
    end
  end

  -- Sync on buffer write (:w)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = edit_buf,
    callback = function()
      sync_back()
      vim.bo[edit_buf].modified = false
      vim.notify("Article block saved", vim.log.levels.INFO)
    end,
  })

  -- Sync on buffer close
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = edit_buf,
    callback = function()
      sync_back()
    end,
  })

  -- Keymap inside the edit window: <Esc> or q to save and close
  local key_opts = { buffer = edit_buf, silent = true }
  vim.keymap.set("n", "q", function()
    sync_back()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, vim.tbl_extend("force", key_opts, { desc = "Close editor and sync" }))

  vim.keymap.set("n", "<C-c><C-c>", function()
    sync_back()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, vim.tbl_extend("force", key_opts, { desc = "Close editor and sync" }))
end

return M
