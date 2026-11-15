-- Test which-key integration
local registered = false
package.loaded["which-key"] = {
  add = function(spec)
    registered = true
    assert(type(spec) == "table", "Spec must be a table")
    assert(spec[1][1] == "<leader>a", "Group mapping mismatch")
  end,
}

local article = require("article")
article.setup()

assert(registered == true, "which-key add was not called when which-key is present")
print("which-key mock test passed successfully!")
