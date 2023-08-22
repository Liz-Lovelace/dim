local db = require("dimDB")
local async = require("async")
local state = require("state")
local editor = require("editor")
local fzf = require("fzf")
local json = require("dkjson")

function love.load()
  love.keyboard.setKeyRepeat(true)
  font = love.graphics.newFont('iosevka-splendid-regular.ttf', 14)
  love.graphics.setFont(font)

  state.update("modifier_keys.shift", false)
  state.update("modifier_keys.ctrl", false)
  state.update("modifier_keys.alt", false)

  state.update("fileA", "README.note")
  state.update("focus", "editor")
end

function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end

function swapAFromFzf()
  fzf.run()
  state.update("focus", "fzf")
  async.await(function() return fzf.grab_output().content == nil end)
  state.update("focus", "editor")
  local lastFzfChoice = trim(fzf.getLastChoice())
  if lastFzfChoice == "" then return end
  state.update("fileA", lastFzfChoice)
end

function love.update() async.tick() end

function love.draw()
  love.graphics.clear(0, 0, 0)

  if state.get().focus == "control" then
    love.graphics.setColor(1, 0, 1)
    love.graphics.print("control mode active", 0, 0)
  end

  love.graphics.setColor(1, 0, 1)
  love.graphics.print(json.encode(state.get(), {indent = true}), 500, 0)

  local connectedFiles = db.connectedFiles("d.note")
  love.graphics.setColor(0, 1, 1)
  local y = 400
  for i, file in pairs(connectedFiles) do
    love.graphics.print(i .. file, 400, y)
    y = y + 20
  end

  local pane_output = editor.grab_output()
  if state.get().focus == "editor" and pane_output.content then
    love.graphics.setColor(0, 1, 0)
    local y = 0
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", pane_output.cursor.x * 7,
                            pane_output.cursor.y * 18, 7, 18)
    for line in pane_output.content:gmatch("[^\n]+") do
      local x = 0
      for char in line:gmatch('.') do
        love.graphics.setColor(0, 1, 0)
        pcall(function() return love.graphics.print(char, x, y) end)
        x = x + 7
      end
      love.graphics.setColor(0, 0.1, 0)
      love.graphics.line(0, y, 600, y)
      y = y + 18
    end
  end

  local pane_output = fzf.grab_output()
  if state.get().focus == "fzf" and pane_output.content then
    love.graphics.setColor(1, 1, 0)
    local y = 0
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", pane_output.cursor.x * 7,
                            pane_output.cursor.y * 18, 7, 18)
    for line in pane_output.content:gmatch("[^\n]+") do
      local x = 0
      for char in line:gmatch('.') do
        love.graphics.setColor(0, 1, 0)
        pcall(function() return love.graphics.print(char, x, y) end)
        x = x + 7
      end
      love.graphics.setColor(0.1, 0, 0)
      love.graphics.line(0, y, 600, y)
      y = y + 18
    end
  end

  love.graphics.setColor(0.1, 1, 0)
  love.graphics.print(string.format("FPS %d", love.timer.getFPS()),
                      love.graphics.getWidth() - 40, 0)
  love.graphics.print(string.format("cursor %d %d", pane_output.cursor.x,
                                    pane_output.cursor.y),
                      love.graphics.getWidth() - 80, 20)
end

function interpretControlKey(key, modifier_keys)
  if key == "e" then
    state.update("focus", "editor")
    state.update("control.active", false)
  elseif key == "f" then
    async.start(swapAFromFzf)
    state.update("control.active", false)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "lshift" or key == "rshift" then
    state.update("modifier_keys.shift", true)
  elseif key == "lctrl" or key == "rctrl" then
    state.update("modifier_keys.ctrl", true)
  elseif key == "lalt" or key == "ralt" then
    state.update("modifier_keys.alt", true)
  end

  local focus = state.get().focus
  if focus == "editor" then
    if key == "ralt" then
      state.update("focus", "control")
      return
    end
    editor.send_input(key, state.get().modifier_keys)
  elseif focus == "fzf" then
    fzf.send_input(key, state.get().modifier_keys)
  elseif focus == "control" then
    interpretControlKey(key, state.get().modifier_keys)
  end
end

function love.keyreleased(key)
  if key == "lshift" or key == "rshift" then
    state.update("modifier_keys.shift", false)
  elseif key == "lctrl" or key == "rctrl" then
    state.update("modifier_keys.ctrl", false)
  elseif key == "lalt" or key == "ralt" then
    state.update("modifier_keys.alt", false)
  end
end

function love.quit() editor.kill() end

