modifier_keys_state = {
  shift = false,
  ctrl = false,
  alt = false
}

function send_input_to_editor(love_keycode)
    local tmux_keycode = love_to_tmux_key(love_keycode, modifier_keys_state)

    os.execute("tmux send-keys -t mySession '" .. tmux_keycode .. "'")
end

function run_editor()
  print("starting new tmux session")
  os.execute("tmux new-session -d -s mySession 'nvim'")
  os.execute("sleep 0.1")
end

function grab_editor_output()
  os.execute("tmux capture-pane -t mySession")
  os.execute("tmux save-buffer /tmp/pane_content.txt")

  local handle = io.popen("tmux display-message -p -F '#{cursor_x},#{cursor_y}' -t mySession")
  local cursor_position = handle:read("*a")
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

  return {
    content = content,
    cursor = {
      x = tonumber(x),
      y = tonumber(y)
    }
  }
end

function love_to_tmux_key(love_key, modifier_keys_state)
    -- rest of the function as it was
end

function kill_editor()
  print("killing tmux session")
  os.execute("tmux kill-session -t mySession")
end

