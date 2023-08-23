local tmux = require("tmux")

local M = {}

local sessionName = "editorSession"

function M.send_input(key, modifier_keys)
  tmux.send_keys(sessionName, key, modifier_keys)
end

function M.run(filename, width, height)
  print("starting new tmux session for editor")
  tmux.spawn_console(sessionName, "nvim " .. filename, width, height)
end

function M.grab_output() return tmux.capture_pane(sessionName) end
function M.resize(width, height)
  return tmux.resize_window(sessionName, width, height)
end

function M.kill()
  print("killing editor tmux session")
  tmux.send_keys(sessionName, "escape")
  tmux.send_keys(sessionName, "escape")
  tmux.send_keys(sessionName, ":")
  tmux.send_keys(sessionName, "w")
  tmux.send_keys(sessionName, "return")
  tmux.kill_console(sessionName)
end

return M
