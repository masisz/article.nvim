# article.nvim

> **Executable Runbooks & Articles inside Neovim**  
> The comfort of Emacs Org-Babel in a simple Markdown workflow.

`article.nvim` is a lightweight Neovim plugin for writing technical articles and infrastructure runbooks while executing commands (Bash, Zsh, PowerShell, Python, and more) in place and automatically embedding and updating their output in Markdown.

---

**日本語版: [README.ja.md](README.ja.md)**

## Features

- 🚀 **Zero output boilerplate**: Write a regular Markdown code block. The plugin automatically creates and updates an ````output` block immediately below it.
- 🖥️ **Broad language and infrastructure support**: Bash, Zsh, pwsh, Python, JavaScript, TypeScript, Rust, Zig, Ruby, C++, and more. Compiled languages are automatically built and run on demand.
- 🧹 **Automatic ANSI escape sequence removal**: Terminal color codes are cleanly stripped so they do not pollute your Markdown.
- 🪟 **Dedicated buffer editing (similar to Emacs `C-c '`)**: Open only the contents of a code block in a separate buffer and use language-specific LSP features, indentation, and completion.
- 🧩 **Extensible block definitions**: Add your own languages, execution commands, and template snippets.
- ⌨️ **Non-conflicting keybindings**: Uses the `<leader>a` (Article) prefix, avoiding conflicts with `usurai.nvim` and `todo.nvim`.
- 🗺️ **Automatic which-key.nvim integration**: When `which-key.nvim` is installed, the `<leader>a` (`+article`) group is registered automatically. It also works transparently without which-key.nvim.

---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "masisz/article.nvim", -- or local path: dir = "~/devs/public-git/article.nvim"
  ft = { "markdown", "pandoc" },
  opts = {
    -- Custom options (see below)
  },
}
```

---

## Default keybindings

| Key | Command | Description |
| :--- | :--- | :--- |
| `<leader>an` | `:ArticleNew [title]` | **Create a new article in the configured directory** with environment metadata, title input, and a template |
| `<leader>al` | `:ArticleList` | **Show and fuzzy-search the article list** with preview support for Snacks.picker, Telescope, and vim.ui.select |
| `<leader>a/` | `:ArticleGrep` | **Fuzzy-search (grep) all articles** in the configured article directory |
| `<leader>ax` | `:ArticleRun` | Run the code block under the cursor and create or update the ````output` block below it |
| `<leader>as` | `:ArticleNext` | Run the current block and **automatically move to the next code block (step execution)** |
| `<leader>ab` | `:ArticleInsert` | Open the code-block insertion selector with **automatic language-version comments** |
| `<leader>ae` | `:ArticleEdit` | Open the block in a dedicated floating buffer and edit it with LSP completion |
| `<leader>ac` | `:ArticleClear` | Remove the ````output` block below the current block |

`<leader>an`, `<leader>al`, and `<leader>a/` can be invoked globally from any buffer.  
In the dedicated editor (`<leader>ae`), press `q` or `<C-c><C-c>` to save and return to the article.

---

## Configuration & extensibility

Use `setup()` to easily add or override block execution commands and templates.

```lua
require("article").setup({
  directory = "~/articles", -- Directory for articles (created automatically)
  date_format = "%Y%m%d",   -- Date prefix for filenames
  extension = "md",         -- File extension
  template = {              -- Initial template for new articles
    "# [Title]",
    "",
    function() return "Created: " .. os.date("%Y-%m-%d %H:%M") end,
    "Tags: #article",
    "",
    "## Overview",
    "",
  },
  cursor_pos = { 7, 0 },    -- Initial cursor position

  output_lang = "output",   -- Language tag for output blocks (```output)
  strip_ansi = true,        -- Strip terminal color codes
  timeout = 15000,          -- Timeout (ms)

  -- Customize keymaps (set to false to disable)
  keymaps = {
    enable = true,
    new = "<leader>an",     -- Create a new article
    list = "<leader>al",    -- Article list and fuzzy search
    grep = "<leader>a/",    -- Grep the article directory
    run = "<leader>ax",     -- Run the current block
    next = "<leader>as",    -- Run and move to the next step
    insert = "<leader>ab",  -- Insert a code block
    edit = "<leader>ae",    -- Edit in a dedicated buffer
    clear = "<leader>ac",   -- Clear the output block
  },

  -- Extend block definitions
  blocks = {
    -- Example: add Ruby
    ruby = {
      cmd = "ruby",
      args = { "-e" },
      desc = "Ruby script",
      template = 'puts "Hello from Ruby #{RUBY_VERSION}"',
    },

    -- Example: define a Dockerfile template (not executable)
    dockerfile = {
      desc = "Dockerfile template",
      template = {
        "FROM alpine:latest",
        "RUN apk add --no-cache curl bash",
        "CMD [\"/bin/sh\"]",
      },
    },

    -- Example: custom runner for executing code in a Docker container
    py_docker = {
      desc = "Python in Docker container",
      runner = function(code, block, callback)
        vim.system({ "docker", "run", "--rm", "-i", "python:3.11-slim", "python3", "-c", code }, { text = true }, function(obj)
          local out = (obj.stdout or "") .. (obj.stderr or "")
          callback(out, obj.code ~= 0 and "Docker run failed" or nil)
        end)
      end,
    },
  },
})
```

---

## Example workflow

````markdown
# Docker Environment Setup Guide

## 1. Check versions
Verify the Docker installation with the following commands.

```bash
docker --version
docker compose version
```
```output
Docker version 24.0.7, build afdd53b
Docker Compose version v2.23.3
```

## 2. Start NGINX for testing
```zsh
docker run -d -p 8080:80 --name my-web nginx:alpine
curl -I http://localhost:8080 | head -n 3
```
```output
HTTP/1.1 200 OK
Server: nginx/1.25.3
Date: Sun, 15 Nov 2026 03:00:00 GMT
```
````

1. Write Markdown.
2. Press `<leader>ab` and select `bash` to insert an empty block.
3. When the code is more complex, press `<leader>ae` to write it in the dedicated editor with completion.
4. Press `<leader>an` to execute the command in the background, embed its log below the block, and jump to the next step.
5. Continue through the article to verify the runbook and embed real execution logs at the same time.

---

## License

MIT
