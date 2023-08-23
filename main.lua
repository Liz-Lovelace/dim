local db = require("dimDB")
local async = require("async")
local state = require("state")
local editor = require("editor")
local fzf = require("fzf")
local json = require("dkjson")
local layout = require("layout")
local draw = require("draw")

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

  state.update("fileA", "scratchpad.note")
  swapIntoA("README.note")

  state.update("focus", "editor")

  state.update("frame_number", 0)
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
  swapIntoA(lastFzfChoice)
end

function swapIntoA(fileName)
  editor.kill()
  editor.run(fileName, layout.getBox("content"):getCharWidth(),
             layout.getBox("content"):getCharHeight())
  state.update("fileB", state.get().fileA)
  state.update("fileA", fileName)
  state.update("chosen_link", 1)
end

function love.update() async.tick() end

function love.draw()
  state.update("frame_number", state.get().frame_number + 1)
  love.graphics.clear(0, 0, 0)

  -- if love.math.random(200) == 1 then draw.random_noise() end

  draw.boundingbox(layout.getBox("content"))
  draw.boundingbox(layout.getBox("links"))
  draw.boundingbox(layout.getBox("state"))
  draw.boundingbox(layout.getBox("debug"))
  draw.boundingbox(layout.getBox("log"))
  draw.boundingbox(layout.getBox("filesAB"))
  draw.boundingbox(layout.getBox("focus"))

  local focus = state.get().focus

  if focus == "editor" then
    draw.editor()
  elseif focus == "fzf" then
    draw.fzf()
    draw.runlines()
  elseif focus == "control" then
    draw.editor()
    draw.runlines()
  end

  draw.state()
  draw.debug()
  draw.links()
  draw.filesAB()
end

function interpretControlKey(key, modifier_keys)
  if key == "e" then
    state.update("focus", "editor")
  elseif key == "f" then
    async.start(swapAFromFzf)
  elseif key == "s" then
    swapIntoA(state.get().fileB)
  elseif key == "l" then
    db.connect(state.get().fileA, state.get().fileB)
  elseif key == "u" then
    db.disconnect(state.get().fileA,
                  db.connectedFiles(state.get().fileA)[state.get().chosen_link])
    state.update("chosen_link", 1)
  elseif key == "j" then
    if state.get().chosen_link >= #db.connectedFiles(state.get().fileA) then
      return
    end
    state.update("chosen_link", state.get().chosen_link + 1)
  elseif key == "k" then
    if 1 >= state.get().chosen_link then return end
    state.update("chosen_link", state.get().chosen_link - 1)
  elseif key == "h" then
    local chosenLinkedFile = db.connectedFiles(state.get().fileA)[state.get()
                                 .chosen_link]
    if not chosenLinkedFile then return end
    swapIntoA(chosenLinkedFile)
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

