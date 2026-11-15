local env = require("article.env")

-- 1. Test OS and Neovim info
local os_info = env.get_os_info()
assert(os_info ~= nil and #os_info > 0, "OS info should not be empty")
print("OS info: " .. os_info)

local nvim_info = env.get_nvim_info()
assert(nvim_info:find("NVIM v"), "Neovim info should contain NVIM v")
print("Neovim info: " .. nvim_info)

-- 2. Test language comment generation
local bash_ver = env.get_lang_comment("bash")
if vim.fn.executable("bash") == 1 then
  assert(bash_ver ~= nil and bash_ver:find("^#"), "Bash comment should start with #")
  print("Bash comment: " .. bash_ver)
end

local py_ver = env.get_lang_comment("python")
if vim.fn.executable("python3") == 1 then
  assert(py_ver ~= nil and py_ver:find("^#"), "Python comment should start with #")
  print("Python comment: " .. py_ver)
end

print("env_spec passed successfully!")
