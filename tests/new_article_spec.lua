local article = require("article")
local config = require("article.config")

local test_dir = vim.fn.tempname() .. "_articles"

-- 1. Test creating article with title
local path1 = article.create("Docker Setup Guide", { directory = test_dir })
assert(path1 ~= nil, "File should be created")
assert(vim.uv.fs_stat(path1) ~= nil, "File should exist on disk")
assert(path1:find("docker%-setup%-guide%.md$"), "Filename should include slug")

-- Verify content has title and environment expanded
local content1 = table.concat(vim.fn.readfile(path1), "\n")
assert(content1:find("# Docker Setup Guide"), "Content should include title")
assert(content1:find("%- OS:"), "Content should include OS info")
assert(content1:find("%- Editor: NVIM"), "Content should include Neovim info")
assert(content1:find("%- Tags: #article"), "Content should include tags")

-- 2. Test creating untitled (sequential) article
local path2 = article.create(nil, { directory = test_dir })
assert(path2 ~= nil, "Sequential file should be created")
assert(path2:find("%-%d%d%.md$"), "Filename should end with sequential number")

-- 3. Test OS-specific directory table
local test_dir_table = {
  windows = vim.fn.tempname() .. "_win_articles",
  mac = vim.fn.tempname() .. "_mac_articles",
  linux = vim.fn.tempname() .. "_linux_articles",
}
local path3 = article.create("OS Table Test", { directory = test_dir_table })
assert(path3 ~= nil, "File should be created with directory table")
assert(vim.uv.fs_stat(path3) ~= nil, "File should exist")
local resolved = config.resolve_directory(test_dir_table)
assert(path3:find(vim.fs.basename(resolved), 1, true), "Path should use resolved OS dir")

-- 4. Cleanup
vim.fn.delete(test_dir, "rf")
vim.fn.delete(resolved, "rf")

print("new_article_spec passed successfully!")
