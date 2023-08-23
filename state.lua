local editor = require("editor")

local M = {}

local state = {}

function M.get(prop) return state end

local function update_recursive(current_state, keys, value)
  local key = table.remove(keys, 1)

  if #keys == 0 then
    current_state[key] = value
  else
    if not current_state[key] or type(current_state[key]) ~= "table" then
      current_state[key] = {}
    end
    update_recursive(current_state[key], keys, value)
  end
end

function M.update(property, newValue)
  local keys = {}
  for part in property:gmatch("[^.]+") do table.insert(keys, part) end
  update_recursive(state, keys, newValue)
end

return M

