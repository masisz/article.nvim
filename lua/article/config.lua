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

---Wrap code in a boilerplate main function if not already present
---@param lang string
---@param code string
---@return string
function M.auto_wrap_main(lang, code)
  if lang == "c" then
    if not code:match("main%s*%(") then
      return string.format(
        "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdbool.h>\n#include <math.h>\n\nint main(void) {\n%s\n    return 0;\n}\n",
        code
      )
    end
  elseif lang == "cpp" then
    if not code:match("main%s*%(") then
      return string.format(
        "#include <iostream>\n#include <vector>\n#include <string>\n#include <algorithm>\n#include <memory>\n#include <cmath>\n\nint main() {\n%s\n    return 0;\n}\n",
        code
      )
    end
  elseif lang == "rust" then
    if not code:match("fn%s+main%s*%(") then
      return string.format("fn main() {\n%s\n}\n", code)
    end
  elseif lang == "go" then
    if not code:match("func%s+main%s*%(") then
      return string.format(
        "package main\n\nimport (\n    \"fmt\"\n    \"os\"\n    \"strings\"\n)\n\nfunc main() {\n%s\n}\n",
        code
      )
    end
  elseif lang == "java" then
    if not code:match("void%s+main%s*%(") then
      return string.format(
        "public class Main {\n    public static void main(String[] args) {\n%s\n    }\n}\n",
        code
      )
    end
  end
  return code
end

---Helper to compile and execute temporary source files for Rust, Zig, C++
---@param ext string File extension without dot (e.g. "rs", "zig", "cpp")
---@param build_run_fn fun(src: string, bin: string): string[] Command returning array
---@param code string
---@param callback fun(output: string, err: string?)
local function run_temp_compiled(ext, build_run_fn, code, callback)
  local tmp_src = vim.fn.tempname() .. "." .. ext
  local tmp_bin = vim.fn.tempname()

  local f = io.open(tmp_src, "w")
  if not f then
    callback("", "Failed to create temporary file: " .. tmp_src)
    return
  end
  f:write(code)
  f:close()

  local cmd = build_run_fn(tmp_src, tmp_bin)
  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      local out = (obj.stdout or "") .. (obj.stderr or "")
      pcall(os.remove, tmp_src)
      pcall(os.remove, tmp_bin)
      callback(out, obj.code ~= 0 and ("Execution failed (exit code " .. obj.code .. ")") or nil)
    end)
  end)
end

---Sync block definitions with usurai.nvim catalog if available
---@param blocks table<string, ArticleBlockDef>
local function sync_usurai_catalog(blocks)
  local ok, usurai_langs = pcall(require, "usurai.config.langs")
  if not ok or not usurai_langs.catalog then
    return
  end

  for lang, pack in pairs(usurai_langs.catalog) do
    if not blocks[lang] then
      blocks[lang] = {
        desc = pack.desc,
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
    pwsh = {
      cmd = default_pwsh(),
      args = { "-NoProfile", "-NonInteractive", "-Command" },
      desc = "PowerShell (pwsh)",
    },
    python = {
      cmd = "python3",
      args = { "-c" },
      desc = "Python 3 script",
      template = 'print("Hello from Python")',
    },
    javascript = {
      cmd = vim.fn.executable("bun") == 1 and "bun" or "node",
      args = { "-e" },
      desc = "JavaScript (Node.js / Bun)",
      template = 'console.log("Hello from JavaScript");',
    },
    typescript = {
      desc = "TypeScript (tsx / bun / ts-node)",
      template = {
        "const message: string = 'Hello from TypeScript';",
        "console.log(message);",
      },
      runner = function(code, _, callback)
        local cmd = nil
        if vim.fn.executable("tsx") == 1 then
          cmd = { "tsx", "-e", code }
        elseif vim.fn.executable("bun") == 1 then
          cmd = { "bun", "-e", code }
        elseif vim.fn.executable("deno") == 1 then
          cmd = { "deno", "eval", code }
        elseif vim.fn.executable("ts-node") == 1 then
          cmd = { "ts-node", "-e", code }
        end

        if not cmd then
          callback("", "No TypeScript runner found (install tsx, bun, deno, or ts-node)")
          return
        end

        vim.system(cmd, { text = true }, function(obj)
          local out = (obj.stdout or "") .. (obj.stderr or "")
          callback(out, obj.code ~= 0 and ("TypeScript execution failed (exit code " .. obj.code .. ")") or nil)
        end)
      end,
    },
    ruby = {
      cmd = "ruby",
      args = { "-e" },
      desc = "Ruby script",
      template = 'puts "Hello from Ruby #{RUBY_VERSION}"',
    },
    rust = {
      desc = "Rust (compiled via rustc, auto-wraps main)",
      template = 'println!("Hello from Rust!");',
      runner = function(code, _, callback)
        if vim.fn.executable("rustc") ~= 1 then
          callback("", "Executable 'rustc' not found in PATH")
          return
        end
        local full_code = auto_wrap_main("rust", code)
        run_temp_compiled("rs", function(src, bin)
          return { "bash", "-c", string.format("rustc %q -o %q && %q", src, bin, bin) }
        end, full_code, callback)
      end,
    },
    zig = {
      desc = "Zig (run via zig run)",
      template = {
        'const std = @import("std");',
        "",
        "pub fn main() void {",
        '    std.debug.print("Hello from Zig!\\n", .{});',
        "}",
      },
      runner = function(code, _, callback)
        if vim.fn.executable("zig") ~= 1 then
          callback("", "Executable 'zig' not found in PATH")
          return
        end
        run_temp_compiled("zig", function(src, _)
          return { "zig", "run", src }
        end, code, callback)
      end,
    },
    cpp = {
      desc = "C++ (compiled via clang++ / g++, auto-wraps main)",
      template = 'std::cout << "Hello from C++!" << std::endl;',
      runner = function(code, _, callback)
        local cc = (vim.fn.executable("clang++") == 1 and "clang++") or (vim.fn.executable("g++") == 1 and "g++")
        if not cc then
          callback("", "Neither 'clang++' nor 'g++' found in PATH")
          return
        end
        local full_code = auto_wrap_main("cpp", code)
        run_temp_compiled("cpp", function(src, bin)
          return { "bash", "-c", string.format("%s -std=c++17 %q -o %q && %q", cc, src, bin, bin) }
        end, full_code, callback)
      end,
    },
    c = {
      desc = "C (compiled via clang / gcc, auto-wraps main)",
      template = 'printf("Hello from C!\\n");',
      runner = function(code, _, callback)
        local cc = (vim.fn.executable("clang") == 1 and "clang") or (vim.fn.executable("gcc") == 1 and "gcc")
        if not cc then
          callback("", "Neither 'clang' nor 'gcc' found in PATH")
          return
        end
        local full_code = auto_wrap_main("c", code)
        run_temp_compiled("c", function(src, bin)
          return { "bash", "-c", string.format("%s %q -o %q && %q", cc, src, bin, bin) }
        end, full_code, callback)
      end,
    },
    go = {
      desc = "Go (run via go run, auto-wraps main)",
      template = 'fmt.Println("Hello from Go!")',
      runner = function(code, _, callback)
        if vim.fn.executable("go") ~= 1 then
          callback("", "Executable 'go' not found in PATH")
          return
        end
        local full_code = auto_wrap_main("go", code)
        run_temp_compiled("go", function(src, _)
          return { "go", "run", src }
        end, full_code, callback)
      end,
    },
    java = {
      desc = "Java (executed via java runner, auto-wraps main)",
      template = 'System.out.println("Hello from Java!");',
      runner = function(code, _, callback)
        if vim.fn.executable("java") ~= 1 then
          callback("", "Executable 'java' not found in PATH")
          return
        end
        local full_code = auto_wrap_main("java", code)
        run_temp_compiled("java", function(src, _)
          return { "java", src }
        end, full_code, callback)
      end,
    },
    csharp = {
      desc = "C# (dotnet-script / csharp)",
      template = {
        'System.Console.WriteLine("Hello from C#!");',
      },
      runner = function(code, _, callback)
        local cmd = nil
        if vim.fn.executable("dotnet-script") == 1 then
          cmd = { "dotnet-script", "eval", code }
        elseif vim.fn.executable("csharp") == 1 then
          cmd = { "csharp", "-e", code }
        end
        if not cmd then
          callback("", "Neither 'dotnet-script' nor 'csharp' found in PATH")
          return
        end
        vim.system(cmd, { text = true }, function(obj)
          local out = (obj.stdout or "") .. (obj.stderr or "")
          callback(out, obj.code ~= 0 and ("C# execution failed (exit code " .. obj.code .. ")") or nil)
        end)
      end,
    },
    sql = {
      cmd = "sqlite3",
      args = { ":memory:" },
      desc = "SQL (sqlite3 in-memory)",
      template = "SELECT 'Hello from SQL' AS message;",
    },
    r = {
      cmd = "Rscript",
      args = { "-e" },
      desc = "R script",
      template = 'cat("Hello from R\\n")',
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
