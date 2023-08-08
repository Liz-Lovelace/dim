local db = require("dimDB")
require("editor_bridge")

function love.load()
  love.keyboard.setKeyRepeat(true)
  font = love.graphics.newFont('iosevka-splendid-regular.ttf', 14)
  love.graphics.setFont(font)

  run_editor()
end

function love.draw()
  love.graphics.clear(0, 0, 0)

  local connectedFiles = db.connectedFiles("d.note")
  love.graphics.setColor(0, 1, 1)
  local y = 0
  for i, file in pairs(connectedFiles) do
    love.graphics.print(i .. file, 400, y)
    y = y + 20
  end

  local pane_output = grab_editor_output()
  love.graphics.setColor(0, 1, 0)
  local y = 0
  love.graphics.setColor(0, 0, 1)
  love.graphics.rectangle("fill", pane_output.cursor.x * 7,
                          pane_output.cursor.y * 18, 7, 18)
  for line in pane_output.content:gmatch("[^\n]+") do
    local x = 0
    for char in line:gmatch('.') do
      love.graphics.setColor(0, 1, 0)
      love.graphics.print(char, x, y)
      x = x + 7
    end
    love.graphics.setColor(0, 0.1, 0)
    love.graphics.line(0, y, 600, y)
    y = y + 18
  end
  love.graphics.print(string.format("FPS %d", love.timer.getFPS()),
                      love.graphics.getWidth() - 40, 0)
  love.graphics.print(string.format("cursor %d %d", pane_output.cursor.x,
                                    pane_output.cursor.y),
                      love.graphics.getWidth() - 80, 20)

end

modifier_keys_state = {shift = false, ctrl = false, alt = false}

function love.keypressed(key, scancode, isrepeat)
  if key == "lshift" or key == "rshift" then
    modifier_keys_state.shift = true
  elseif key == "lctrl" or key == "rctrl" then
    modifier_keys_state.ctrl = true
  elseif key == "lalt" or key == "ralt" then
    modifier_keys_state.alt = true
  end

  send_input_to_editor(key)
end

function love.keyreleased(key)
  if key == "lshift" or key == "rshift" then
    modifier_keys_state.shift = false
  elseif key == "lctrl" or key == "rctrl" then
    modifier_keys_state.ctrl = false
  elseif key == "lalt" or key == "ralt" then
    modifier_keys_state.alt = false
  end
end

function send_input_to_editor(love_keycode)
  local tmux_keycode = love_to_tmux_key(love_keycode, modifier_keys_state)

  os.execute("tmux send-keys -t mySession '" .. tmux_keycode .. "'")
end

function love.quit() kill_editor() end

function run_editor()
  print("starting new tmux session")
  os.execute("tmux new-session -d -s mySession 'nvim'")
  os.execute("sleep 0.1")
end

function grab_editor_output()
  os.execute("tmux capture-pane -t mySession")
  os.execute("tmux save-buffer /tmp/pane_content.txt")

  local handle = io.popen(
                     "tmux display-message -p -F '#{cursor_x},#{cursor_y}' -t mySession")
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

  return {content = content, cursor = {x = tonumber(x), y = tonumber(y)}}
end

function love_to_tmux_key(love_key, modifier_keys_state)
  local love_tmux_key_map = {
    escape = 'Escape',
    home = 'Home',
    ['end'] = 'End',
    tab = 'Tab',
    ['return'] = 'Enter',
    space = 'Space',
    up = 'Up',
    left = 'Left',
    down = 'Down',
    right = 'Right',
    pageup = 'PPage',
    pagedown = 'NPage',
    backspace = 'BSpace',
    capslock = '',
    lshift = '',
    rshift = '',
    lctrl = '',
    rctrl = '',
    lalt = '',
    ralt = '',
    lgui = '',
    ['\''] = "\'\\'\'",
    insert = 'IC',
    delete = 'DC',
    f1 = 'F1',
    f2 = 'F2',
    f3 = 'F3',
    f4 = 'F4',
    f5 = 'F5',
    f6 = 'F6',
    f7 = 'F7',
    f8 = 'F8',
    f9 = 'F9',
    f10 = 'F10',
    f11 = 'F11',
    f12 = 'F12'
  }

  local shift_love_tmux_key_map = {
    a = 'A',
    b = 'B',
    c = 'C',
    d = 'D',
    e = 'E',
    f = 'F',
    g = 'G',
    h = 'H',
    i = 'I',
    j = 'J',
    k = 'K',
    l = 'L',
    m = 'M',
    n = 'N',
    o = 'O',
    p = 'P',
    q = 'Q',
    r = 'R',
    s = 'S',
    t = 'T',
    u = 'U',
    v = 'V',
    w = 'W',
    x = 'X',
    y = 'Y',
    z = 'Z',
    ['`'] = '~',
    ['1'] = '!',
    ['2'] = '@',
    ['3'] = '#',
    ['4'] = '$',
    ['5'] = '%',
    ['6'] = '^',
    ['7'] = '&',
    ['8'] = '*',
    ['9'] = '(',
    ['0'] = ')',
    ['-'] = '_',
    ['='] = '+',
    ['['] = '{',
    [']'] = '}',
    ['\\'] = '|',
    [';'] = ':',
    ['\''] = '"',
    [','] = '<',
    ['.'] = '>',
    ['/'] = '?'
  }

  local tmux_key = love_tmux_key_map[love_key] or love_key

  if modifier_keys_state.shift then
    tmux_key = shift_love_tmux_key_map[love_key] or tmux_key
  end

  local modifier = ""
  if modifier_keys_state.ctrl then modifier = "C-" end
  if modifier_keys_state.alt then modifier = "M-" end

  if tmux_key and tmux_key:len() > 0 then
    return modifier .. tmux_key
  else
    return ""
  end
end

function kill_editor()
  print("killing tmux session")
  os.execute("tmux kill-session -t mySession")
end

