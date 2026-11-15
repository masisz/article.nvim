# article.nvim

> **Executable Runbooks & Articles inside Neovim**  
> Emacs Org-Babel の快適さを、シンプルな Markdown の世界で。

`article.nvim` は、Neovim 上で技術記事やインフラ手順書（Runbook）を執筆しながら、書いたコマンド（Bash, Zsh, PowerShell, Python など）をその場で実行し、実行結果を Markdown 内に自動埋め込み・更新できる軽量プラグインです。

---

**English version: [README.md](README.md)**

## 主な特徴

- 🚀 **手書きの記述量ゼロ**: 通常の Markdown コードブロックを書くだけ。プラグインが直下に ````output` を自動生成・自動更新。
- 🖥️ **幅広い言語・インフラ対応**: Bash, Zsh, pwsh, Python, JavaScript, TypeScript, Rust, Zig, Ruby, C++ 等に対応。コンパイル言語も自動で即時ビルド＆実行。
- 🧹 **ANSI エスケープシーケンス自動除去**: ターミナルのカラーコードを綺麗にストリップして Markdown を汚しません。
- 🪟 **専用バッファ編集 (Emacs `C-c '` 相当)**: コードブロックの中身だけを独立したバッファで開き、言語固有の LSP・インデント・補完をフル活用して編集可能。
- 🧩 **拡張可能なブロック定義**: ユーザーが独自の言語、実行コマンド、テンプレートスニペットを自由に追加可能。
- ⌨️ **衝突のないキーバインド**: `usurai.nvim` や `todo.nvim` と競合しない `<leader>a`（Article）プレフィックス。
- 🗺️ **which-key.nvim 自動連携**: `which-key.nvim` がインストールされていれば自動で `<leader>a`（+article）グループを登録。未インストールの環境でもエラーなく透過的に動作。

---

## インストール

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "masisz/article.nvim", -- or local path: dir = "~/devs/public-git/article.nvim"
  ft = { "markdown", "pandoc" },
  opts = {
    -- カスタム設定（下記参照）
  },
}
```

---

## デフォルトキーバインド

| キー | コマンド | 説明 |
| :--- | :--- | :--- |
| `<leader>an` | `:ArticleNew [title]` | **指定ディレクトリ内に新規記事を作成**（環境メタデータ・タイトル入力・テンプレート付き） |
| `<leader>al` | `:ArticleList` | **記事リスト表示＆曖昧検索**（Snacks.picker / Telescope / vim.ui.select 対応、プレビュー付き） |
| `<leader>a/` | `:ArticleGrep` | **記事ディレクトリ内の全文曖昧検索 (grep)** |
| `<leader>ax` | `:ArticleRun` | カーソル位置のコードブロックを実行し、直下に ````output` を生成/更新 |
| `<leader>as` | `:ArticleNext` | 現在のブロックを実行後、**自動的に次のコードブロックへ進む（ステップ実行）** |
| `<leader>ab` | `:ArticleInsert` | コードブロック挿入セレクタを開く（**言語バージョンコメント自動付与**） |
| `<leader>ae` | `:ArticleEdit` | ブロックを専用バッファ（Float Window）で開き、LSP補完を効かせて編集 |
| `<leader>ac` | `:ArticleClear` | 直下の ````output` ブロックを消去 |

※ `<leader>an`, `<leader>al`, `<leader>a/` はどのバッファからでもグローバルに呼び出せます。  
※ 専用エディタ画面（`<leader>ae`）内では、`q` または `<C-c><C-c>` で保存して記事へ戻れます。

---

## 設定とブロック拡張 (Configuration & Extensibility)

`setup()` でブロックの実行コマンドやテンプレートを簡単に追加・上書きできます。

```lua
require("article").setup({
  directory = "~/articles", -- 記事の保存先ディレクトリ（自動作成されます）
  date_format = "%Y%m%d",   -- ファイル名の日付プレフィックス
  extension = "md",         -- 拡張子
  template = {              -- 新規作成時の初期テンプレート
    "# [Title]",
    "",
    function() return "Created: " .. os.date("%Y-%m-%d %H:%M") end,
    "Tags: #article",
    "",
    "## Overview",
    "",
  },
  cursor_pos = { 7, 0 },    -- 作成時の初期カーソル位置

  output_lang = "output",   -- 出力ブロックの言語タグ (```output)
  strip_ansi = true,        -- ターミナルカラーコードを除去
  timeout = 15000,          -- タイムアウト (ms)

  -- キーマップのカスタマイズ (false で無効化)
  keymaps = {
    enable = true,
    new = "<leader>an",     -- 新規記事作成
    list = "<leader>al",    -- 記事リスト・曖昧検索
    grep = "<leader>a/",    -- 記事ディレクトリ内の grep
    run = "<leader>ax",     -- 現在のブロック実行
    next = "<leader>as",    -- 実行して次のステップへ進む
    insert = "<leader>ab",  -- コードブロック挿入
    edit = "<leader>ae",    -- 専用バッファ編集
    clear = "<leader>ac",   -- 出力ブロック消去
  },

  -- ブロック定義の拡張
  blocks = {
    -- 例: Ruby の追加
    ruby = {
      cmd = "ruby",
      args = { "-e" },
      desc = "Ruby script",
      template = 'puts "Hello from Ruby #{RUBY_VERSION}"',
    },

    -- 例: Dockerfile のテンプレート定義（実行なし）
    dockerfile = {
      desc = "Dockerfile template",
      template = {
        "FROM alpine:latest",
        "RUN apk add --no-cache curl bash",
        "CMD [\"/bin/sh\"]",
      },
    },

    -- 例: Docker コンテナ上でコードを実行するカスタムランナー
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

## 執筆フロー例

````markdown
# Docker 環境セットアップガイド

## 1. バージョンの確認
以下のコマンドで Docker のインストールを確認します。

```bash
docker --version
docker compose version
```
```output
Docker version 24.0.7, build afdd53b
Docker Compose version v2.23.3
```

## 2. NGINX のテスト起動
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

1. Markdown を書く。
2. `<leader>ab` を押して `bash` を選択すると、空のブロックがスッと挿入される。
3. コードが複雑なときは `<leader>ae` を押して右画面で補完を効かせながら書く。
4. `<leader>an` を押すと、コマンドが裏で実行されて直下にログが埋め込まれ、次のステップへカーソルがジャンプ。
5. 記事を読み返しながら最後まで進めば、**手順書の検証と本物の実行ログの埋め込みが同時に完了**します。

---

## ライセンス

MIT
