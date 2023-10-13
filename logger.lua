local M = {}

local log = ""

function M.log(message)
  print(message)
  log = message .. "\n" .. log
end

function M.getLog() return log end

return M

