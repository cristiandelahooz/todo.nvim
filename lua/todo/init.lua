--- @module "todo"
--- @brief Main entry point for the todo.nvim plugin.

local M = {}

local Config = require("todo.config")
local UI = require("todo.ui")

--- Set up the plugin with user-provided options
--- @param opts? TodoConfig User configuration options
function M.setup(opts)
  M.config = Config.setup(opts)
end

--- Open the todo list UI
function M.open()
  UI.open()
end

return M
