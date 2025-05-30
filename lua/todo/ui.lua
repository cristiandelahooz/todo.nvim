--- @module "todo.ui"
--- @brief Floating window UI for todo.nvim.

local M = {}

local Config = require("todo.config")
local TodoList = require("todo.todo_list")

--- @class Window
--- @field buf number Buffer handle
--- @field win number Window handle
--- @field timer userdata? Timer for real-time updates

--- Format milliseconds to a human-readable time (e.g., "5m 30s")
--- @param ms number Milliseconds
--- @return string Formatted time
local function format_time_remaining(ms)
  if ms <= 0 then
    return "0s"
  end
  local seconds = math.floor(ms / 1000)
  local minutes = math.floor(seconds / 60)
  seconds = seconds % 60
  if minutes > 0 then
    return string.format("%dm %ds", minutes, seconds)
  end
  return string.format("%ds", seconds)
end

--- Update buffer content with current todos and times
--- @param buf number Buffer handle
--- @param todos Todo[] List of todos
--- @return table<number, number?> time_starts Start column of time text for each todo
local function update_buffer(buf, todos)
  local lines = { " Todo List (Press ? for help) " }
  local time_starts = {}
  local now = os.time() * 1000
  for i, todo in ipairs(todos) do
    local icon = todo.done and "✓" or "[ ]"
    local time_remaining = Config.config.auto_delete_ms
        and todo.done
        and todo.completed_at
        and (Config.config.auto_delete_ms - (now - todo.completed_at))
      or nil
    local time_text = time_remaining and format_time_remaining(time_remaining) .. " remaining" or ""
    local main_text = string.format("%s %s", icon, todo.text)
    local line = time_text ~= "" and (main_text .. " " .. time_text) or main_text
    table.insert(lines, line)
    time_starts[i] = time_text ~= "" and #main_text + 2 or nil -- +2 for space and 1-based indexing
  end
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  return time_starts
end

--- Open the todo list UI
--- @return Window Window handles
function M.open()
  local todos = TodoList.load_todos()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#todos + 25, math.floor(vim.o.lines * 0.6))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = vim.o.columns - width - 2

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- Set buffer content with remaining time
  local time_starts = update_buffer(buf, todos)

  -- Create floating window
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Set window options
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Apply highlights
  M.apply_highlights(buf, todos, time_starts)

  -- Set keymaps
  M.set_window_keymaps(buf, win)

  -- Set up timer for real-time updates
  local timer = vim.loop.new_timer()
  timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
        timer:stop()
        timer:close()
        return
      end
      todos = TodoList.load_todos()
      time_starts = update_buffer(buf, todos)
      M.apply_highlights(buf, todos, time_starts)
      local new_height = math.min(#todos + 25, math.floor(vim.o.lines * 0.6))
      vim.api.nvim_win_set_config(win, {
        relative = win_config.relative,
        width = win_config.width,
        height = new_height,
        row = math.floor((vim.o.lines - new_height) / 2),
        col = win_config.col,
        style = win_config.style,
        border = win_config.border,
      })
    end)
  )

  -- Stop timer on window close
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    callback = function()
      if timer:is_active() then
        timer:stop()
        timer:close()
      end
    end,
    once = true,
  })

  return { buf = buf, win = win, timer = timer }
end

--- Apply Solarized Osaka and orange highlights
--- @param buf number Buffer handle
--- @param todos Todo[] List of todos
--- @param time_starts table<number, number?> Start column of time text for each todo
function M.apply_highlights(buf, todos, time_starts)
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
  vim.api.nvim_set_hl(0, "TodoTimeRemaining", { fg = "#657b83" }) -- Solarized Osaka base01, lower contrast

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "TodoTitle", 0, 0, -1)
  for i, todo in ipairs(todos) do
    local line = i
    local time_start = time_starts[i]
    if time_start then
      vim.api.nvim_buf_add_highlight(buf, -1, todo.done and "TodoDone" or "TodoText", line, 0, time_start - 1)
      vim.api.nvim_buf_add_highlight(buf, -1, "TodoTimeRemaining", line, time_start - 1, -1)
    else
      vim.api.nvim_buf_add_highlight(buf, -1, todo.done and "TodoDone" or "TodoText", line, 0, -1)
    end
  end
end

--- Set keymaps for the todo window
--- @param buf number Buffer handle
--- @param win number Window handle
function M.set_window_keymaps(buf, win)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Add todo
  vim.keymap.set("n", "a", function()
    -- Create a temporary buffer for input
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "todo_input")

    -- Open the buffer in a new window
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 40,
      height = 5,
      row = math.floor(vim.o.lines / 2 - 2),
      col = math.floor(vim.o.columns / 2 - 20),
      style = "minimal",
      border = "rounded",
    })

    -- Set keymaps for confirming or canceling input
    vim.api.nvim_buf_set_keymap(
      buf,
      "n",
      "<CR>",
      [[<Cmd>lua require('todo.ui').confirm_input(]] .. buf .. [[, ]] .. win .. [[)<CR>]],
      { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(
      buf,
      "n",
      "<Esc>",
      [[<Cmd>lua vim.api.nvim_win_close(]] .. win .. [[, true)<CR>]],
      { noremap = true, silent = true }
    )
  end, opts)

  -- Toggle todo completion
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      TodoList.toggle_todo(line - 1)
      vim.api.nvim_win_close(win, true)
      M.open()
    end
  end, opts)

  -- Delete todo
  vim.keymap.set("n", "x", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      TodoList.delete_todo(line - 1)
      vim.api.nvim_win_close(win, true)
      M.open()
    end
  end, opts)

  -- Edit todo
  vim.keymap.set("n", "E", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      local todos = TodoList.load_todos()
      vim.ui.input({ prompt = "Edit Todo: ", default = todos[line - 1].text }, function(input)
        if input and input ~= "" then
          local success = TodoList.edit_todo(line - 1, input)
          if success then
            vim.api.nvim_win_close(win, true)
            M.open()
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
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end, opts)
end

function M.confirm_input(buf, win)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local input = table.concat(lines, "\n")

  if input and input ~= "" then
    local success = TodoList.add_todo(input)
    if success then
      vim.api.nvim_win_close(win, true)
      M.open()
    else
      vim.notify("Failed to add todo: Invalid input", vim.log.levels.ERROR)
    end
  else
    vim.notify("Input cannot be empty", vim.log.levels.WARN)
  end
end

return M
