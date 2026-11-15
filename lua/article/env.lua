local M = {}

local version_cache = {}

---Get operating system summary string
---@return string
function M.get_os_info()
  local uname = vim.uv.os_uname()
  local sysname = uname.sysname
  local machine = uname.machine

  if sysname == "Darwin" then
    -- macOS
    local ver = nil
    if vim.fn.executable("sw_vers") == 1 then
      local out = vim.fn.system("sw_vers -productVersion")
      if vim.v.shell_error == 0 and out then
        ver = vim.trim(out)
      end
    end
    if ver then
      return string.format("macOS %s (%s)", ver, machine)
    else
      return string.format("macOS / Darwin %s (%s)", uname.release, machine)
    end
  elseif sysname == "Linux" then
    -- Linux distro
    local distro = nil
    if vim.fn.filereadable("/etc/os-release") == 1 then
      for _, line in ipairs(vim.fn.readfile("/etc/os-release")) do
        local name = line:match('^PRETTY_NAME="?([^"]+)"?')
        if name then
          distro = name
          break
        end
      end
    end
    return string.format("%s (%s, %s)", distro or "Linux", uname.release, machine)
  elseif sysname == "Windows_NT" then
    return string.format("Windows (%s, %s)", uname.release, machine)
  end

  return string.format("%s %s (%s)", sysname, uname.release, machine)
end

---Get Neovim version string
---@return string
function M.get_nvim_info()
  local v = vim.version()
  return string.format("NVIM v%d.%d.%d", v.major, v.minor, v.patch)
end

---Comment prefix syntax per language
local comment_prefix = {
  bash = "#",
  zsh = "#",
  pwsh = "#",
  python = "#",
  ruby = "#",
  r = "#",
  dockerfile = "#",
  yaml = "#",
  javascript = "//",
  typescript = "//",
  rust = "//",
  zig = "//",
  cpp = "//",
  c = "//",
  go = "//",
  java = "//",
  csharp = "//",
  sql = "--",
}

---Fetch runtime version string for a language (cached)
---@param lang string
---@return string? version_line
function M.get_lang_version(lang)
  lang = lang:lower()
  if version_cache[lang] ~= nil then
    return version_cache[lang]
  end

  local cmd = nil

  if lang == "bash" and vim.fn.executable("bash") == 1 then
    cmd = { "bash", "-c", "bash --version | head -n 1" }
  elseif lang == "zsh" and vim.fn.executable("zsh") == 1 then
    cmd = { "zsh", "-c", "zsh --version" }
  elseif lang == "pwsh" and vim.fn.executable("pwsh") == 1 then
    cmd = { "pwsh", "-NoProfile", "-NonInteractive", "-Command", "$PSVersionTable.PSVersion.ToString()" }
  elseif lang == "python" and vim.fn.executable("python3") == 1 then
    cmd = { "python3", "--version" }
  elseif lang == "javascript" then
    if vim.fn.executable("bun") == 1 then
      cmd = { "bun", "--version" }
    elseif vim.fn.executable("node") == 1 then
      cmd = { "node", "--version" }
    end
  elseif lang == "typescript" then
    if vim.fn.executable("tsc") == 1 then
      cmd = { "tsc", "--version" }
    elseif vim.fn.executable("bun") == 1 then
      cmd = { "bun", "--version" }
    elseif vim.fn.executable("tsx") == 1 then
      cmd = { "tsx", "--version" }
    elseif vim.fn.executable("node") == 1 then
      cmd = { "node", "--version" }
    end
  elseif lang == "rust" and vim.fn.executable("rustc") == 1 then
    cmd = { "rustc", "--version" }
  elseif lang == "zig" and vim.fn.executable("zig") == 1 then
    cmd = { "zig", "version" }
  elseif lang == "ruby" and vim.fn.executable("ruby") == 1 then
    cmd = { "ruby", "--version" }
  elseif (lang == "cpp" or lang == "c++") then
    local cc = vim.fn.executable("clang++") == 1 and "clang++" or (vim.fn.executable("g++") == 1 and "g++")
    if cc then
      cmd = { "bash", "-c", cc .. " --version | head -n 1" }
    end
  elseif lang == "c" then
    local cc = vim.fn.executable("clang") == 1 and "clang" or (vim.fn.executable("gcc") == 1 and "gcc")
    if cc then
      cmd = { "bash", "-c", cc .. " --version | head -n 1" }
    end
  elseif lang == "go" and vim.fn.executable("go") == 1 then
    cmd = { "go", "version" }
  elseif lang == "java" and vim.fn.executable("java") == 1 then
    cmd = { "bash", "-c", "java --version 2>&1 | head -n 1" }
  elseif (lang == "csharp" or lang == "cs") and vim.fn.executable("dotnet") == 1 then
    cmd = { "dotnet", "--version" }
  elseif lang == "sql" and vim.fn.executable("sqlite3") == 1 then
    cmd = { "sqlite3", "--version" }
  elseif lang == "r" and vim.fn.executable("R") == 1 then
    cmd = { "bash", "-c", "R --version 2>&1 | head -n 1" }
  end

  if not cmd then
    version_cache[lang] = false
    return nil
  end

  local out = vim.fn.system(cmd)
  if vim.v.shell_error == 0 and out and #out > 0 then
    local line = vim.trim((out:match("^[^\r\n]+") or out))
    -- Format nicely if it is just a plain version number
    if line:match("^%d+%.%d+") and not line:lower():find(lang) then
      line = string.format("%s %s", lang, line)
    end
    version_cache[lang] = line
    return line
  end

  version_cache[lang] = false
  return nil
end

---Generate a version header comment for the given language
---@param lang string
---@return string?
function M.get_lang_comment(lang)
  local prefix = comment_prefix[lang:lower()]
  if not prefix then
    return nil
  end
  local ver = M.get_lang_version(lang)
  if ver and #ver > 0 then
    return string.format("%s %s", prefix, ver)
  end
  return nil
end

return M
