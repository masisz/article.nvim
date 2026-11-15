local M = {}

---Strip ANSI color and terminal control escape sequences
---@param str string
---@return string
function M.strip_ansi(str)
  if not str then
    return ""
  end
  -- Strip standard CSI sequences (e.g. \x1b[32m, \x1b[0m)
  local clean = str:gsub("\27%[[0-9;?]*[a-zA-Z]", "")
  -- Strip OSC sequences (e.g. \x1b]0;title\x07)
  clean = clean:gsub("\27%][^\a\27]*[\a\27\\]", "")
  -- Strip carriage returns (\r)
  clean = clean:gsub("\r", "")
  return clean
end

---Execute code using configured block definition
---@param block ArticleBlockInfo
---@param callback fun(result: { success: boolean, output: string, exit_code?: number })
function M.execute(block, callback)
  local config = require("article.config").get()
  local block_def = config.blocks[block.lang]

  if not block_def then
    callback({
      success = false,
      output = string.format("No runner configured for language '%s'", block.lang),
    })
    return
  end

  -- 1. Custom runner defined by user
  if block_def.runner then
    block_def.runner(block.code, block, function(output, err)
      if err then
        callback({ success = false, output = err })
      else
        local text = config.strip_ansi and M.strip_ansi(output) or output
        callback({ success = true, output = text })
      end
    end)
    return
  end

  -- 2. Command-based execution
  if not block_def.cmd or vim.fn.executable(block_def.cmd) ~= 1 then
    callback({
      success = false,
      output = string.format("Executable '%s' not found for language '%s'", block_def.cmd or "", block.lang),
    })
    return
  end

  local cmd_args = {}
  table.insert(cmd_args, block_def.cmd)
  if block_def.args then
    for _, arg in ipairs(block_def.args) do
      table.insert(cmd_args, arg)
    end
  end
  table.insert(cmd_args, block.code)

  -- Execute via vim.system (Neovim 0.10+) or fallback
  if vim.system then
    local cwd = vim.fn.expand("%:p:h")
    if cwd == "" or not vim.fn.isdirectory(cwd) then
      cwd = vim.fn.getcwd()
    end

    vim.system(
      cmd_args,
      {
        cwd = cwd,
        text = true,
        timeout = config.timeout,
      },
      function(obj)
        vim.schedule(function()
          local combined = ""
          if obj.stdout and #obj.stdout > 0 then
            combined = combined .. obj.stdout
          end
          if obj.stderr and #obj.stderr > 0 then
            if #combined > 0 and combined:sub(-1) ~= "\n" then
              combined = combined .. "\n"
            end
            combined = combined .. obj.stderr
          end

          if #combined == 0 and obj.code == 0 then
            combined = "(Process completed with no output)"
          end

          local text = config.strip_ansi and M.strip_ansi(combined) or combined
          callback({
            success = (obj.code == 0),
            output = text,
            exit_code = obj.code,
          })
        end)
      end
    )
  else
    -- Fallback for older Neovim versions using jobstart
    local stdout_chunks = {}
    local stderr_chunks = {}
    local job_id = vim.fn.jobstart(cmd_args, {
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_chunks, line)
          end
        end
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_chunks, line)
          end
        end
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          local out = table.concat(stdout_chunks, "\n")
          local err = table.concat(stderr_chunks, "\n")
          local combined = out
          if #err > 0 then
            combined = (#combined > 0 and (combined .. "\n") or "") .. err
          end
          if #combined == 0 and code == 0 then
            combined = "(Process completed with no output)"
          end
          local text = config.strip_ansi and M.strip_ansi(combined) or combined
          callback({
            success = (code == 0),
            output = text,
            exit_code = code,
          })
        end)
      end,
    })

    if job_id <= 0 then
      callback({
        success = false,
        output = string.format("Failed to start job for command '%s'", block_def.cmd),
      })
    end
  end
end

return M
