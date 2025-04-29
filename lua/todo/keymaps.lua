--- @module "todo.keymaps"
--- @brief Keymap definitions for todo.nvim UI.

local M = {}

local TodoList = require("todo.todo_list")
local UI = require("todo.ui")

--- Set keymaps for the todo window
--- @param buf number Buffer handle
--- @param win number Window handle
function M.set_window_keymaps(buf, win)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Add todo
  vim.keymap.set("n", "a", function()
    vim.ui.input({ prompt = "New Todo: " }, function(input)
      if input and input ~= "" then
        local success = TodoList.add_todo(input)
        if success then
          vim.api.nvim_win_close(win, true)
          UI.open()
        else
          vim.notify("Failed to add todo: Invalid input", vim.log.levels.ERROR)
        end
      end
    end)
  end, opts)

  -- Toggle todo completion
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      TodoList.toggle_todo(line - 1)
      vim.api.nvim_win_close(win, true)
      UI.open()
    end
  end, opts)

  -- Delete todo
  vim.keymap.set("n", "x", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      TodoList.delete_todo(line - 1)
      vim.api.nvim_win_close(win, true)
      UI.open()
    end
  end, opts)

  -- Edit todo
  vim.keymap.set("n", "e", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      local todos = TodoList.load_todos()
      vim.ui.input({ prompt = "Edit Todo: ", default = todos[line - 1].text }, function(input)
        if input and input ~= "" then
          local success = TodoList.edit_todo(line - 1, input)
          if success then
            vim.api.nvim_win_close(win, true)
            UI.open()
          else
            vim.notify("Failed to edit todo: Invalid input", vim.log.levels.ERROR)
          end
        end
      end)
    end
  end, opts)

  -- Close window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, opts)

  -- Show help
  vim.keymap.set("n", "?", function()
    local help = {
      "Todo List Keymaps:",
      "a: Add new todo",
      "<CR>: Toggle todo completion",
      "x: Delete todo",
      "e: Edit todo",
      "q: Close window",
      "?: Show this help",
    }
    vim.api.nvim_win_set_height(win, #help + 2)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end, opts)
end

return M
