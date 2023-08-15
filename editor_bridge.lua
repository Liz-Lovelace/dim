local tmux = require("tmux")

modifier_keys = {shift = false, ctrl = false, alt = false}

function send_input_to_editor(love_keycode, modifier_keys)
  local tmux_keycode = love_to_tmux_key(love_keycode, modifier_keys)
  tmux.send_keys("mySession", tmux_keycode)
end

function run_editor()
  print("starting new tmux session")
  tmux.spawn_console("mySession", "nvim")
  tmux.resize_window("mySession", 120, 30)
end

function grab_editor_output() return tmux.capture_pane("mySession") end

function kill_editor()
  print("killing tmux session")
  tmux.send_keys("mySession", "Escape")
  tmux.send_keys("mySession", "Escape")
  tmux.send_keys("mySession", ":")
  tmux.send_keys("mySession", "w")
  tmux.send_keys("mySession", "Enter")
  tmux.kill_console("mySession")
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
