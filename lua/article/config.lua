local M = {}

---@class ArticleBlockDef
---@field cmd? string Executable command (e.g. "bash", "python3")
---@field args? string[] Arguments passed before code (e.g. { "-c" })
---@field desc? string Friendly description for selector
---@field template? string|string[] Default content when generating a block
---@field runner? fun(code: string, block: ArticleBlockInfo, callback: fun(output: string, err: string?)) Custom execution runner

---@class ArticleConfig
---@field output_lang string Language tag for the output fence (default: "output")
---@field strip_ansi boolean Strip ANSI escape color sequences from terminal outputs (default: true)
---@field timeout number Execution timeout in milliseconds (default: 15000)
---@field usurai_sync boolean Sync language catalog from usurai.nvim if present (default: true)
---@field keymaps table<string, string|false> Key mappings
---@field blocks table<string, ArticleBlockDef> Block definitions and runners

local function default_pwsh()
  if vim.fn.executable("pwsh") == 1 then
    return "pwsh"
  elseif vim.fn.executable("powershell.exe") == 1 then
    return "powershell.exe"
  end
  return "pwsh"
end

---Sync block definitions with usurai.nvim catalog if available
---@param blocks table<string, ArticleBlockDef>
local function sync_usurai_catalog(blocks)
  local ok, usurai_langs = pcall(require, "usurai.config.langs")
  if not ok or not usurai_langs.catalog then
    return
  end

  local usurai_defaults = {
    ruby = { cmd = "ruby", args = { "-e" }, desc = "Ruby script" },
    rust = { desc = "Rust snippet", template = "fn main() {\n    println!(\"Hello\");\n}" },
    go = { desc = "Go snippet", template = "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello\")\n}" },
    zig = { desc = "Zig snippet", template = "const std = @import(\"std\");\n\npub fn main() void {\n    std.debug.print(\"Hello\\n\", .{});\n}" },
    sql = { desc = "SQL query", template = "SELECT 1;" },
    shell = { cmd = "bash", args = { "-c" }, desc = "Bash / Shell script" },
    docker = {
      desc = "Dockerfile template",
      template = { "FROM alpine:latest", "RUN apk update" },
    },
  }

  for lang, pack in pairs(usurai_langs.catalog) do
    if not blocks[lang] then
      local candidate = usurai_defaults[lang] or {}
      blocks[lang] = {
        cmd = candidate.cmd,
        args = candidate.args,
        desc = candidate.desc or pack.desc,
        template = candidate.template,
      }
    end
  end
end

---@type ArticleConfig
M.defaults = {
  output_lang = "output",
  strip_ansi = true,
  timeout = 15000,
  usurai_sync = true,
  keymaps = {
    enable = true,
    run = "<leader>ax",      -- Run current code block & update output
    next = "<leader>an",     -- Run current and jump to next code block
    insert = "<leader>ab",   -- Insert a new code block (select language)
    edit = "<leader>ae",     -- Open current block in dedicated buffer (C-c ')
    clear = "<leader>ac",    -- Clear output block below cursor
  },
  blocks = {
    bash = {
      cmd = "bash",
      args = { "-c" },
      desc = "Bash shell script",
    },
    zsh = {
      cmd = "zsh",
      args = { "-c" },
      desc = "Z shell script",
    },
    sh = {
      cmd = "sh",
      args = { "-c" },
      desc = "POSIX shell script",
    },
    powershell = {
      cmd = default_pwsh(),
      args = { "-NoProfile", "-NonInteractive", "-Command" },
      desc = "PowerShell script (pwsh / powershell.exe)",
    },
    pwsh = {
      cmd = default_pwsh(),
      args = { "-NoProfile", "-NonInteractive", "-Command" },
      desc = "PowerShell Core",
    },
    python = {
      cmd = "python3",
      args = { "-c" },
      desc = "Python 3 script",
    },
    node = {
      cmd = "node",
      args = { "-e" },
      desc = "Node.js JavaScript",
    },
    dockerfile = {
      desc = "Dockerfile template",
      template = {
        "FROM alpine:latest",
        "RUN apk update && apk add --no-cache curl",
      },
    },
    yaml = {
      desc = "Docker Compose / YAML template",
      template = {
        "services:",
        "  web:",
        "    image: nginx:alpine",
        "    ports:",
        "      - '8080:80'",
      },
    },
  },
}

---@type ArticleConfig
M.options = {}

---Setup configuration with user overrides
---@param user_opts? table
---@return ArticleConfig
function M.setup(user_opts)
  local base = vim.deepcopy(M.defaults)
  M.options = vim.tbl_deep_extend("force", base, user_opts or {})
  if M.options.usurai_sync then
    sync_usurai_catalog(M.options.blocks)
  end
  return M.options
end

---Get current options
---@return ArticleConfig
function M.get()
  if vim.tbl_isempty(M.options) then
    M.options = vim.deepcopy(M.defaults)
  end
  return M.options
end

return M
