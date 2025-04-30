# todo.nvim

A professional Neovim plugin for managing a todo list with a LazyVim-style UI, styled with Solarized Osaka and TailwindCSS orange accents.

## Features

- Floating window UI with rounded borders, inspired by `lazy.nvim`.
- CRUD operations: Add (`a`), toggle completion (`<CR>`), delete (`x`), edit (`e`).
- Todos stored in `stdpath("state")/todo/todos.json` by default.
- Configurable auto-deletion of todos after a specified time (in milliseconds).
- Keymaps: `a`, `<CR>`, `x`, `e`, `q` (close), `?` (help).
- Styled with Solarized Osaka colors and TailwindCSS orange (`#f97316`).

## Requirements

- Neovim 0.9.0 or later.
- `folke/lazy.nvim` for plugin management.
- `craftzdog/solarized-osaka.nvim` (optional, for optimal styling).

## Installation

Install with `lazy.nvim`:

```lua
{
  "cristiandelahooz/todo.nvim",
  event = "VeryLazy",
  config = function()
    require("todo").setup({
      state_dir = vim.fn.stdpath("state"),
      auto_delete_ms = 7 * 24 * 60 * 60 * 1000, -- 7 days
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
  - `e`: Edit a todo.
  - `q`: Close the window.
  - `?`: Show keymap help.

## Configuration

Available options:

```lua
config = function()
  require("todo").setup({
    -- Custom state directory for testing
    state_dir = vim.fn.expand("~/.todo-nvim-test/state"),
    -- Custom todo file for testing
    todo_file = vim.fn.expand("~/.todo-nvim-test/todo/todos.json"),
    -- Short auto-deletion time for testing (10 seconds)
    auto_delete_ms = 10 * 1000,
    -- Optional: Override colors for testing
    colors = {
      orange = "#f97316", -- TailwindCSS orange-500
      yellow = "#b58900",
      green = "#859900",
      base0 = "#839496",
      base03 = "#002b36",
    },
    -- Enable debug logging for development
    debug = false,
  })
end,
keys = {
  { "<leader>t", "<cmd>TodoOpen<cr>", desc = "Open Todo List" },
},

```

## Development

To develop locally:

1. Clone the repository:

   ```bash
   git clone git@github.com:cristiandelahooz/todo.nvim.git ~/projects/todo.nvim
   ```

2. Add to your LazyVim config as a local plugin:

   ```lua
   {
     dir = "~/projects/todo.nvim",
     lazy = false,
     config = function()
       require("todo").setup()
     end,
     keys = { { "<leader>t", "<cmd>TodoOpen<cr>", desc = "Open Todo List" } },
   }
   ```

3. Run `:Lazy sync` and test with `<leader>t`.

## Troubleshooting

- **JSON errors**: Delete `stdpath("state")/todo/todos.json` and restart Neovim.
- **Colors incorrect**: Ensure `solarized-osaka.nvim` is loaded and `termguicolors` is enabled.
- **Keymaps not working**: Check for conflicts with `:map <leader>t`.

## License

MIT
