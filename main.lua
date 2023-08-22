local db = require("dimDB")
local async = require("async")
local state = require("state")
local editor = require("editor")
local fzf = require("fzf")
local json = require("dkjson")
local layout = require("layout")

function love.load()
  love.window.setMode(400, 400, {msaa = 0, resizable = true, fullscreen = true})
  layout.setViewportSize(1600, 850)
  love.keyboard.setKeyRepeat(true)
  font = love.graphics.newFont('iosevka-splendid-regular.ttf', 14)
  love.graphics.setFont(font)

  love.graphics.setLineStyle("rough")

  state.update("modifier_keys.shift", false)
  state.update("modifier_keys.ctrl", false)
  state.update("modifier_keys.alt", false)

  state.update("fileA", "README.note")
  state.update("focus", "editor")

  state.update("frame_number", 0)
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

function randomNoise()
  local strings = {
    "S C P", "CLASSIFIED", "| | | | | |\n| | | | | |\n| | | | | |", "2 2 2 2",
    "@", "@$)*@f;f0fl", "0x0000001", "the end is not the end", "antimemetics",
    ". . . . . . . . . . . . . .\n. . . . . . . . . . . . . .\n. . . . . . . . . . . . . .\n. . . . . . . . . . . . . .\n. . . . . . . . . . . . . .\n. . . . . . . . . . . . . .",
    ". . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
    ". . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n. . .\n",
    ".............\n.............\n.............\n.............\n.............\n",
    "root@root >_"
  }

  local randomString = strings[love.math.random(#strings)]

  local x = love.math.random(love.graphics.getWidth())
  local y = love.math.random(love.graphics.getHeight())

  love.graphics.print(randomString, x, y)
end

function love.draw()
  state.update("frame_number", state.get().frame_number + 1)
  love.graphics.clear(0, 0, 0)

  if love.math.random(200) == 1 then randomNoise() end

  drawBoundingBox(layout.getBox("content"))
  drawBoundingBox(layout.getBox("links"))
  drawBoundingBox(layout.getBox("state"))
  drawBoundingBox(layout.getBox("debug"))
  drawBoundingBox(layout.getBox("log"))
  drawBoundingBox(layout.getBox("filesAB"))
  drawBoundingBox(layout.getBox("focus"))

  if state.get().focus == "control" then
    love.graphics.setColor(1, 0, 1)
    love.graphics.print("control mode active", 50, 300)
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
    love.graphics.setLineWidth(1)
    local y = 0
    love.graphics.setColor(0, 1, 0)
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
    love.graphics.setLineWidth(1)
    local y = 0
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", pane_output.cursor.x * 7,
                            pane_output.cursor.y * 18, 7, 18)
    for line in pane_output.content:gmatch("[^\n]+") do
      local x = 0
      for char in line:gmatch('.') do
        love.graphics.setColor(0, 1, 1)
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
  elseif key == "f" then
    async.start(swapAFromFzf)
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

function drawBoundingBox(box)
  love.graphics.setColor(1, 0, 0)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", box.x1, box.y1, box.x2 - box.x1,
                          box.y2 - box.y1)
end
