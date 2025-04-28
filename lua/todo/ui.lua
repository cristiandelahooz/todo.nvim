--- @module "todo.ui"
--- @brief Floating window UI for todo.nvim.

local M = {}

local Config = require("todo.config")
local Keymaps = require("todo.keymaps")
local TodoList = require("todo.todo_list")

--- @class Window
--- @field buf number Buffer handle
--- @field win number Window handle

--- Open the todo list UI
--- @return Window Window handles
function M.open()
  local todos = TodoList.load_todos()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#todos + 2, math.floor(vim.o.lines * 0.6))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- Set buffer content
  local lines = { " Todo List (Press ? for help) " }
  for i, todo in ipairs(todos) do
    local icon = todo.done and "✓" or " "
    table.insert(lines, string.format(" %s %d. %s", icon, i, todo.text))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Apply highlights
  M.apply_highlights(buf, todos)

  -- Set keymaps
  Keymaps.set_window_keymaps(buf, win)

  return { buf = buf, win = win }
end

--- Apply Solarized Osaka and orange highlights
--- @param buf number Buffer handle
--- @param todos Todo[] List of todos
function M.apply_highlights(buf, todos)
  local colors = Config.config.colors
  -- Try to load Solarized Osaka colors, fallback to config defaults
  local has_solarized, solarized_colors = pcall(require, "solarized-osaka.colors")
  if has_solarized then
    colors = vim.tbl_deep_extend("force", colors, solarized_colors.setup())
  end

  -- Define highlight groups
  vim.api.nvim_set_hl(0, "TodoTitle", { fg = colors.orange, bg = colors.base03, bold = true })
  vim.api.nvim_set_hl(0, "TodoDone", { fg = colors.green })
  vim.api.nvim_set_hl(0, "TodoText", { fg = colors.base0 })

  -- Apply highlights
  vim.api.nvim_buf_add_highlight(buf, -1, "TodoTitle", 0, 0, -1)
  for i, todo in ipairs(todos) do
    vim.api.nvim_buf_add_highlight(buf, -1, todo.done and "TodoDone" or "TodoText", i, 0, -1)
  end
end

return M
