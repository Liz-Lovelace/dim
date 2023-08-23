local tmux = {}

local function execute(command) return os.execute(command) end

function tmux.spawn_console(session, command, width, height)
  execute("tmux new-session -d -s " .. session .. " '" .. command .. "'")
  execute("sleep 0.1")
  tmux.resize_window(session, width, height)
end

function tmux.kill_console(session) execute("tmux kill-session -t " .. session) end

function tmux.send_keys(session, love_keycode, modifier_keys)
  modifier_keys = modifier_keys or {}
  local tmux_keycode = love_to_tmux_key(love_keycode, modifier_keys)
  execute("tmux send-keys -t " .. session .. " '" .. tmux_keycode .. "'")
end

function tmux.resize_window(session, width, height)
  execute("tmux resize-window -x " .. width .. " -y " .. height .. " -t " ..
              session)
end

function tmux.capture_pane(session)
  local statusCode = execute("tmux capture-pane -t " .. session)
  if statusCode ~= 0 then return {content = nil, cursor = {x = 0, y = 0}} end
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

  return {
    content = content,
    cursor = {x = tonumber(x) or 0, y = tonumber(y) or 0}
  }
end

function love_to_tmux_key(love_key, modifier_keys)
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

  if modifier_keys.shift then
    tmux_key = shift_love_tmux_key_map[love_key] or tmux_key
  end

  local modifier = ""
  if modifier_keys.ctrl then modifier = "C-" end
  if modifier_keys.alt then modifier = "M-" end

  if tmux_key and tmux_key:len() > 0 then
    return modifier .. tmux_key
  else
    return ""
  end
end

return tmux

