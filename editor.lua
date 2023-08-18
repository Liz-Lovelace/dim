local tmux = require("tmux")

local M = {}

modifier_keys = {shift = false, ctrl = false, alt = false}

function M.send_input(key, modifier_keys)
  tmux.send_keys("mySession", key, modifier_keys)
end

function M.run(filename)
  print("starting new tmux session")
  tmux.spawn_console("mySession", "nvim " .. filename)
  tmux.resize_window("mySession", 120, 30)
end

function M.grab_output() return tmux.capture_pane("mySession") end

function M.kill()
  print("killing tmux session")
  tmux.send_keys("mySession", "escape")
  tmux.send_keys("mySession", "escape")
  tmux.send_keys("mySession", ":")
  tmux.send_keys("mySession", "w")
  tmux.send_keys("mySession", "return")
  tmux.kill_console("mySession")
end

return M
