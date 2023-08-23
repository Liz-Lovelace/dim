local tmux = require("tmux")

local M = {}

local sessionName = "fzfSession"

function M.send_input(key, modifier_keys)
  tmux.send_keys(sessionName, key, modifier_keys)
end

function M.run(width, height)
  print("starting new tmux session for fzf")
  tmux.spawn_console(sessionName, "fzf > /tmp/fzfResult ", width, height)
end

function M.grab_output() return tmux.capture_pane(sessionName) end

function M.kill()
  print("killing fzf tmux session")
  tmux.kill_console(sessionName)
end

function M.getLastChoice()
  local f = io.open("/tmp/fzfResult", "r")
  if not f then return {} end

  local content = f:read("*all")
  f:close()
  return content
end

return M
