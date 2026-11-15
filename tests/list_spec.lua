local list = require("article.list")
local article = require("article")

local test_dir = vim.fn.tempname() .. "_articles_list"

-- Create test articles
local path1 = article.create("First Article", { directory = test_dir })
assert(path1 ~= nil, "First article created")

-- Small pause to ensure differing mtime if filesystem resolution allows
vim.uv.sleep(10)

local path2 = article.create("Second Advanced Topic", { directory = test_dir })
assert(path2 ~= nil, "Second article created")

-- Scan articles
local scanned = list.scan_articles(test_dir, "md")
assert(#scanned == 2, "Should find 2 articles, found: " .. #scanned)

-- Verify titles and sort order (newest first)
assert(scanned[1].title == "Second Advanced Topic", "First item should be newest: " .. scanned[1].title)
assert(scanned[2].title == "First Article", "Second item should be older: " .. scanned[2].title)

-- Verify filename and path
assert(scanned[1].path == path2, "Path should match")
assert(scanned[1].filename:find("%.md$"), "Filename should have md extension")

-- Cleanup
vim.fn.delete(test_dir, "rf")

print("list_spec passed successfully!")
