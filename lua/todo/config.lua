--- @module "todo.config"
--- @brief Configuration management for todo.nvim.

local M = {}

--- @class TodoConfig
--- @field state_dir string Directory for storing todos (default: stdpath("state"))
--- @field todo_file string Path to the JSON file for todos (default: state_dir/todo/todos.json)
--- @field auto_delete_ms number? Time in milliseconds after which todos are auto-deleted (nil to disable)
--- @field colors table Color palette for UI (default: Solarized Osaka with TailwindCSS orange)
--- @field debug boolean Enable debug logging (default: false)

--- Default configuration
--- @type TodoConfig
local defaults = {
  state_dir = vim.fn.stdpath("state"),
  todo_file = nil, -- Computed dynamically if not set
  auto_delete_ms = nil,
  colors = {
    orange = "#f97316", -- TailwindCSS orange-500 (OKLCH: 0.77, 0.19, 32.67)
    yellow = "#b58900", -- Solarized Osaka yellow
    green = "#859900", -- Solarized Osaka green
    base0 = "#839496", -- Solarized Osaka base0
    base03 = "#002b36", -- Solarized Osaka base03
  },
  debug = false,
}

--- Set up and validate configuration
--- @param opts? TodoConfig User-provided options
--- @return TodoConfig Merged and validated configuration
function M.setup(opts)
  local config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Ensure state_dir exists
  vim.fn.mkdir(config.state_dir, "p")

  -- Set default todo_file if not provided
  if not config.todo_file then
    config.todo_file = config.state_dir .. "/todo/todos.json"
  end

  -- Ensure todo_file directory exists
  local todo_dir = vim.fn.fnamemodify(config.todo_file, ":h")
  vim.fn.mkdir(todo_dir, "p")

  -- Validate auto_delete_ms
  if config.auto_delete_ms and (type(config.auto_delete_ms) ~= "number" or config.auto_delete_ms < 0) then
    vim.notify("Invalid auto_delete_ms: Must be a non-negative number", vim.log.levels.WARN)
    config.auto_delete_ms = nil
  end

  -- Validate debug
  if type(config.debug) ~= "boolean" then
    config.debug = false
  end

  return config
end

return M
