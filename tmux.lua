local tmux = {}

local function execute(command) os.execute(command) end

function tmux.spawn_console(session, command)
  execute("tmux new-session -d -s " .. session .. " '" .. command .. "'")
  execute("sleep 0.1")
end

function tmux.kill_console(session) execute("tmux kill-session -t " .. session) end

function tmux.send_keys(session, key)
  execute("tmux send-keys -t " .. session .. " '" .. key .. "'")
end

function tmux.resize_window(session, width, height)
  execute("tmux resize-window -x " .. width .. " -y " .. height .. " -t " ..
              session)
end

function tmux.capture_pane(session)
  execute("tmux capture-pane -t " .. session)
  execute("tmux save-buffer /tmp/pane_content.txt")

  local handle = io.popen(
                     "tmux display-message -p -F '#{cursor_x},#{cursor_y}' -t " ..
                         session)
  local cursor_position = handle:read("*a") or ""
  handle:close()
  local x, y = string.match(cursor_position, "(%d+),(%d+)")

  local file = io.open("/tmp/pane_content.txt", "r")
  local content = ''
  if file then
    content = file:read("*all")
    file:close()
  else
    print("Error: Failed to open the tmux pane_content.txt file")
  end

  return {content = content, cursor = {x = tonumber(x), y = tonumber(y)}}
end

return tmux

