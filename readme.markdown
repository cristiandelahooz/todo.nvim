# todo.nvim

A professional Neovim plugin for managing a todo list with a LazyVim-style UI, styled with Solarized Osaka and TailwindCSS orange accents.

## Features

- Floating window UI with rounded borders, inspired by `lazy.nvim`.
- CRUD operations: Add (`a`), toggle completion (`<CR>`), delete (`x`), edit (`e`).
- Todos stored in `stdpath("state")/todo/todos.json` by default.
- Auto-deletion of **completed** todos based on time since completion (`auto_delete_ms`).
- Real-time display of remaining time until deletion for completed todos (e.g., “5m 30s remaining”), updated every second.
- Keymaps: `a`, `<CR>`, `x`, `e`, `q` (close), `?` (help).
- Styled with Solarized Osaka colors, created by @craftzdog and TailwindCSS orange (`#f97316`).

## Requirements

- Neovim 0.9.0 or later.
- `folke/lazy.nvim` for plugin management.
- `craftzdog/solarized-osaka.nvim` (optional, for optimal styling).

## Installation

Install with `lazy.nvim`:

```lua
{
  "cristiandelahooz/todo.nvim",
  lazy = false, -- Ensure setup is called early
  config = function()
    require("todo").setup({
      state_dir = vim.fn.stdpath("state"),
      auto_delete_ms =  5 * 60 * 1000, -- 5 minutes
    })
  end,
  keys = {
    { "<leader>t", "<cmd>TodoOpen<cr>", desc = "Open Todo List" },
  },
}
```

## Usage

- Press `<leader>t` to open the todo list.
- In the todo window:
  - `a`: Add a new todo.
  - `<CR>`: Toggle completion (mark as done/undone).
  - `x`: Delete a todo.
  - `e`: Edit todo.
  - `q`: Close the window.
  - `?`: Show keymap help.
- Completed todos show remaining time until deletion (e.g., “✓ Done task 5m 30s remaining”) in a low-contrast color, updated in real-time.
- Completed todos are automatically removed when the time since completion exceeds `auto_delete_ms`.

## Configuration

Available options:

```lua
require("todo").setup({
  state_dir = vim.fn.stdpath("state"), -- Directory for todo storage
  todo_file = nil, -- Defaults to state_dir/todo/todos.json
  auto_delete_ms =  5 * 60 * 1000, -- Auto-delete completed todos after 5 minutes since completion
  colors = { -- Override default colors
    orange = "#f97316",
    yellow = "#b58900",
    green = "#859900",
    base0 = "#839496",
    base03 = "#002b36",
  },
  debug = false, -- Enable debug logging
})
```

## Development

To develop locally:

1. Clone the repository:

   ```bash
   git clone git@github.com:cristiandelahooz/todo.nvim.git ~/projects/todo.nvim
   ```

2. Create a development config:

   ```lua
   -- ~/todo-nvim-dev/nvim/lua/plugins/todo.lua
   return {
     {
       dir = "~/projects/todo.nvim",
       lazy = false,
       config = function()
         require("todo").setup({
           state_dir = vim.fn.expand("~/.todo-nvim-test/state"),
           auto_delete_ms = 10 * 1000, -- 10 seconds for testing
           debug = true,
         })
       end,
       keys = { { "<leader>t", "<cmd>TodoOpen<cr>", desc = "Open Todo List" } },
     },
   }
   ```

3. Run Neovim with:

   ```bash
   NVIM_APPNAME=todo-nvim-dev nvim
   ```

4. Test with `:Lazy sync` and `<leader>t`.

## Troubleshooting

- **attempt to index field 'config' (a nil value)**:
  - Ensure `require("todo").setup()` is called and `lazy = false` in LazyVim spec.
  - Update `config.lua` to initialize `M.config`.
- **E475: Invalid argument: writefile()**:
  - Delete `state_dir/todo/todos.json` and restart Neovim.
  - Ensure `todo_list.lua` uses `write_file` instead of `vim.fn.write`.
- **init_todo_file errors**:
  - Enable `debug = true` to log file paths.
  - Ensure `state_dir` is writable.
- **Time display not updating**:
  - Verify `auto_delete_ms` is set and todos are completed with `completed_at`.
  - Check `ui.lua` timer logic and ensure Neovim supports `vim.loop`.
- **Colors incorrect**:
  - Ensure `solarized-osaka.nvim` is loaded and `termguicolors` is enabled.

## License

MIT
