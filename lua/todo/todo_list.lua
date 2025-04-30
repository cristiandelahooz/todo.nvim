--- @module "todo.todo_list"
--- @brief Manages todo list CRUD operations and storage.

local M = {}

local config = require("todo.config")

--- @class Todo
--- @field text string Todo description
--- @field done boolean Completion status
--- @field created_at number Timestamp (milliseconds since epoch) when created
--- @field completed_at number? Timestamp (milliseconds since epoch) when completed

--- @type string Path to the todo JSON file
M.todo_file = nil

--- Helper: Write a string to a file
--- @param file_path string Path to the file
--- @param content string Content to write
local function write_file(file_path, content)
  if config.config.debug then
    vim.notify("Writing to: " .. file_path, vim.log.levels.INFO)
  end
  local file = io.open(file_path, "w")
  if not file then
    error("Failed to open file for writing: " .. file_path)
  end
  file:write(content)
  file:close()
end

--- Initialize an empty todo file if it doesn't exist
--- @param file string Path to the todo file
local function init_todo_file(file)
  if config.config.debug then
    vim.notify("init_todo_file called with file: " .. tostring(file), vim.log.levels.INFO)
  end

  if type(file) ~= "string" or file == "" then
    error("Invalid file path provided")
  end

  -- Ensure the directory exists
  local dir = vim.fn.fnamemodify(file, ":h")
  if config.config.debug then
    vim.notify("Ensuring directory exists: " .. dir, vim.log.levels.INFO)
  end
  vim.fn.mkdir(dir, "p")

  if vim.fn.filereadable(file) == 0 then
    local success, content = pcall(vim.fn.json_encode, { todos = {} })
    if not success or type(content) ~= "string" then
      error("Failed to encode initial JSON for: " .. file)
    end

    local ok, err = pcall(write_file, file, content)
    if not ok then
      error("Failed to write to file: " .. file .. ". Error: " .. tostring(err))
    end

    if config.config.debug then
      vim.notify("Created new todo file: " .. file, vim.log.levels.INFO)
    end
  end
end

--- Load todos from file, applying auto-deletion
--- @return Todo[] List of todos
function M.load_todos()
  if config.config.debug then
    vim.notify("Loading todos from: " .. config.config.todo_file, vim.log.levels.INFO)
  end
  init_todo_file(config.config.todo_file)
  local content = vim.fn.readfile(config.config.todo_file)
  if not content or #content == 0 then
    local empty_content = vim.fn.json_encode({ todos = {} })
    write_file(config.config.todo_file, empty_content)
    return {}
  end

  local ok, data = pcall(vim.fn.json_decode, table.concat(content))
  if not ok or type(data) ~= "table" or type(data.todos) ~= "table" then
    local empty_content = vim.fn.json_encode({ todos = {} })
    write_file(config.config.todo_file, empty_content)
    return {}
  end

  -- Filter valid todos and apply auto-deletion
  local todos = {}
  local now = os.time() * 1000 -- Current time in milliseconds
  for i, todo in ipairs(data.todos) do
    if
      type(todo) == "table"
      and type(todo.text) == "string"
      and type(todo.done) == "boolean"
      and type(todo.created_at) == "number"
    then
      -- Skip if auto-deletion is enabled and todo is expired
      if config.config.debug then
        vim.notify("Checking todo: " .. vim.inspect(todo), vim.log.levels.INFO)
      end
      if
        not todo.done
        or not config.config.auto_delete_ms
        or not todo.completed_at
        or (now - todo.completed_at) <= config.config.auto_delete_ms
      then
        todos[#todos + 1] = {
          text = todo.text,
          done = todo.done,
          created_at = todo.created_at,
          completed_at = todo.completed_at,
        }
      end
    end
  end

  -- Save filtered todos
  M.save_todos(todos)
  return todos
end

--- Save todos to file
--- @param todos Todo[] List of todos to save
function M.save_todos(todos)
  if config.config.debug then
    vim.notify("Saving todos: " .. vim.inspect(todos), vim.log.levels.INFO)
  end
  local valid_todos = {}
  for i, todo in ipairs(todos or {}) do
    if
      type(todo) == "table"
      and type(todo.text) == "string"
      and type(todo.done) == "boolean"
      and type(todo.created_at) == "number"
      and (not todo.completed_at or type(todo.completed_at) == "number")
    then
      valid_todos[i] = {
        text = todo.text,
        done = todo.done,
        created_at = todo.created_at,
        completed_at = todo.completed_at,
      }
    end
  end

  local data = { todos = valid_todos }
  local ok, encoded = pcall(vim.fn.json_encode, data)
  if not ok then
    vim.notify("Failed to encode todos: " .. tostring(encoded), vim.log.levels.ERROR)
    return
  end
  write_file(config.config.todo_file, encoded)
end

--- Add a new todo
--- @param text string Todo description
--- @return boolean Success status
function M.add_todo(text)
  if type(text) ~= "string" or text == "" then
    vim.notify("Invalid todo text: Must be a non-empty string", vim.log.levels.ERROR)
    return false
  end
  local todos = M.load_todos()
  table.insert(todos, {
    text = vim.trim(text),
    done = false,
    created_at = os.time() * 1000,
    completed_at = nil,
  })
  M.save_todos(todos)
  return true
end

--- Toggle todo completion
--- @param index number Todo index (1-based)
function M.toggle_todo(index)
  if type(index) ~= "number" or index < 1 then
    return
  end
  local todos = M.load_todos()
  if todos[index] then
    todos[index].done = not todos[index].done
    todos[index].completed_at = todos[index].done and os.time() * 1000 or nil
    if config.config.debug then
      vim.notify("Toggled todo: " .. vim.inspect(todos[index]), vim.log.levels.INFO)
    end
    M.save_todos(todos)
  end
end

--- Delete a todo
--- @param index number Todo index (1-based)
function M.delete_todo(index)
  if type(index) ~= "number" or index < 1 then
    return
  end
  local todos = M.load_todos()
  if todos[index] then
    table.remove(todos, index)
    M.save_todos(todos)
  end
end

--- Edit a todo
--- @param index number Todo index (1-based)
--- @param new_text string New todo description
--- @return boolean Success status
function M.edit_todo(index, new_text)
  if type(index) ~= "number" or index < 1 then
    return false
  end
  if type(new_text) ~= "string" or new_text == "" then
    vim.notify("Invalid todo text: Must be a non-empty string", vim.log.levels.ERROR)
    return false
  end
  local todos = M.load_todos()
  if todos[index] then
    todos[index].text = vim.trim(new_text)
    M.save_todos(todos)
    return true
  end
  return false
end

return M
