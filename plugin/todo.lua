--- @brief Registers todo.nvim commands.

vim.api.nvim_create_user_command("TodoOpen", function()
  require("todo").open()
end, { desc = "Open Todo List" })
