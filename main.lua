local db = require("dimDB")
local async = require("async")
local state = require("state")
local editor = require("editor")
local fzf = require("fzf")
local json = require("dkjson")
local layout = require("layout")

function draw_text_in_box(box, text)
  love.graphics.setLineWidth(1)
  local y = box.y1
  for line in text:gmatch("[^\n]+") do
    local x = box.x1
    for char in line:gmatch('.') do
      love.graphics.setColor(0, 1, 0)
      pcall(function() return love.graphics.print(char, x, y) end)
      x = x + state.get().font.width
    end
    love.graphics.setColor(0, 0.1, 0)
    love.graphics.line(box.x1, y + state.get().font.height, box.x2 - 1,
                       y + state.get().font.height)
    y = y + state.get().font.height
  end
end

function draw_editor()
  local pane_output = editor.grab_output()
  if not pane_output.content then return end
  love.graphics.setColor(0, 1, 0)
  local box = layout.getBox("content")
  love.graphics.rectangle("fill", box.x1 + pane_output.cursor.x *
                              state.get().font.width, box.y1 +
                              pane_output.cursor.y * state.get().font.height,
                          state.get().font.width, state.get().font.height)
  draw_text_in_box(box, pane_output.content)
end

function draw_fzf()
  local pane_output = fzf.grab_output()
  if not pane_output.content then return end
  love.graphics.setColor(0, 1, 0)
  -- love.graphics.rectangle("fill", pane_output.cursor.x * state.get().font.width,
  --                         pane_output.cursor.y * state.get().font.height, state.get().font.width, state.get().font.height)
  draw_text_in_box(layout.getBox("content"), pane_output.content)
end

function draw_state()
  love.graphics.setColor(1, 0, 1)
  draw_text_in_box(layout.getBox("state"),
                   json.encode(state.get(), {indent = true}))
end

function draw_debug()
  love.graphics.setColor(0.1, 1, 0)
  draw_text_in_box(layout.getBox("debug"),
                   string.format("FPS %d", love.timer.getFPS()))
end

function draw_links()
  local connectedFiles = db.connectedFiles("d.note")
  love.graphics.setColor(0, 1, 1)
  local box = layout.getBox("links")
  local y = box.y1
  for i, file in pairs(connectedFiles) do
    love.graphics.print(i .. file, box.x1, y)
    y = y + 20
  end
end

function draw_runlines(box)
  local rectWidth = 4
  love.graphics.setColor(1, 1, 1)

  local gap = 80
  local gap_lmao = 4
  local speed = 0.4

  local frame = state.get().frame_number
  local box = layout.getBox("runlines")
  for i = 0, gap, gap_lmao do
    local progress = (frame * speed + i) % (gap) / gap
    local sin = ((math.cos(progress * math.pi) + 1) / 2)
    love.graphics.rectangle("fill",
                            sin * (love.graphics.getWidth() - rectWidth) +
                                box.x1, box.y1 + 1, rectWidth, box:getHeight())
  end
end

function love.load()
  love.window.setMode(400, 400, {msaa = 0, resizable = true, fullscreen = true})
  layout.setViewportSize(1600, 900)
  love.keyboard.setKeyRepeat(true)

  font = love.graphics.newFont('iosevka-splendid-regular.ttf', 14)
  love.graphics.setFont(font)
  state.update("font.width", 7)
  state.update("font.height", 18)

  love.graphics.setLineStyle("rough")

  state.update("modifier_keys.shift", false)
  state.update("modifier_keys.ctrl", false)
  state.update("modifier_keys.alt", false)

  openIntoA("README.note")

  state.update("focus", "editor")

  state.update("frame_number", 0)
end

function openIntoA(fileName)
  editor.kill()
  editor.run(fileName, layout.getBox("content"):getCharWidth(),
             layout.getBox("content"):getCharHeight())
  state.update("fileA", fileName)
end

function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end

function swapAFromFzf()
  fzf.run(layout.getBox("content"):getCharWidth(),
          layout.getBox("content"):getCharHeight())
  state.update("focus", "fzf")
  async.await(function() return fzf.grab_output().content == nil end)
  state.update("focus", "editor")
  local lastFzfChoice = trim(fzf.getLastChoice())
  if lastFzfChoice == "" then return end
  openIntoA(lastFzfChoice)
end

function love.update() async.tick() end

function draw_random_noise()
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

  -- if love.math.random(200) == 1 then draw_random_noise() end

  drawBoundingBox(layout.getBox("content"))
  drawBoundingBox(layout.getBox("links"))
  drawBoundingBox(layout.getBox("state"))
  drawBoundingBox(layout.getBox("debug"))
  drawBoundingBox(layout.getBox("log"))
  drawBoundingBox(layout.getBox("filesAB"))
  drawBoundingBox(layout.getBox("focus"))

  local focus = state.get().focus

  if focus == "editor" then
    draw_editor()
  elseif focus == "fzf" then
    draw_fzf()
    draw_runlines()
  elseif focus == "control" then
    draw_runlines()
  end

  draw_state()
  draw_debug()
  draw_links()

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
