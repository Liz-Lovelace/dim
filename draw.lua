local state = require("state")
local logger = require("logger")
local editor = require("editor")
local layout = require("layout")
local json = require("dkjson")
local db = require("dimDB")
local fzf = require("fzf")
local files = require("files")

local M = {}

function M.random_noise()
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

function M.editor()
  local pane_output = editor.grab_output()
  if not pane_output.content then return end
  love.graphics.setColor(0, 1, 0)
  local box = layout.getBox("content"):inset(10)
  love.graphics.rectangle("fill", box.x1 + pane_output.cursor.x *
                              state.get().font.width, box.y1 +
                              pane_output.cursor.y * state.get().font.height,
                          state.get().font.width, state.get().font.height)
  M.text_in_box(box, pane_output.content, 0, 1, 0)
end

function M.fzf()
  local pane_output = fzf.grab_output()
  if not pane_output.content then return end
  love.graphics.setColor(0, 1, 0)
  -- love.graphics.rectangle("fill", pane_output.cursor.x * state.get().font.width,
  --                         pane_output.cursor.y * state.get().font.height, state.get().font.width, state.get().font.height)
  M.text_in_box(layout.getBox("content"), pane_output.content, 0, 1, 0)
end

function M.state()
  love.graphics.setColor(1, 0, 1)

  M.text_in_box(layout.getBox("state"):inset(10), logger.getLog(), 1, 0, 0)
end

function M.debug()
  love.graphics.setColor(0.1, 1, 0)
  local box = layout.getBox("debug"):inset(10)

  local y = box.y1

  -- love.graphics.print("FPS " .. love.timer.getFPS(), box.x1, y)
  -- y = y + state.get().font.height

  local info = files.getFileInfo(state.get().fileA)
  if info then
    y = y + 10
    love.graphics.print("FILEINFO " .. state.get().fileA, box.x1 + 30, y)
    y = y + state.get().font.height + 10
    love.graphics.print("size " .. info.size, box.x1, y)
    y = y + state.get().font.height
    love.graphics.print("atime " .. info.atime, box.x1, y)
    y = y + state.get().font.height
    love.graphics.print("mtime " .. info.mtime, box.x1, y)
    y = y + state.get().font.height
    love.graphics.print("ctime " .. info.ctime, box.x1, y)
    y = y + state.get().font.height
  end
end

function M.links()
  local connectedFiles = db.connectedFiles(state.get().fileA)
  local box = layout.getBox("links"):inset(10)
  local y = box.y1
  for i, file in pairs(connectedFiles) do
    if state.get().chosen_link == i then
      love.graphics.setColor(1, 0, 1)
    else
      love.graphics.setColor(0, 1, 1)
    end
    love.graphics.print(file, box.x1, y)
    y = y + 20
  end
end

function M.extraText()
  love.graphics.setColor(0, 1, 1)
  local box = layout.getBox("extraText"):inset(20)
  M.text_in_box(box,
                "MANUAL:\n \n \n   Any mode:\n \nRight ALT - enter Control mode\n(press again to get back to editor)\n \n \n   Control mode:\n \nf - launch fzf\ns - swap FILE A and FILE B\nl - link FILE A and FILE B\nj/k - move link selection down/up\nh - go to selected link\nu - unlink selected link\nr - rename current file\nc - create new file",
                0, 0.8, 0)
end

function M.runlines(box)
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

function M.filesAB()
  love.graphics.setColor(0, 1, 1)
  local box = layout.getBox("filesAB"):inset(10)
  love.graphics.print("FILE A: " .. state.get().fileA, box.x1, box.y1)
  love.graphics.print("FILE B: " .. state.get().fileB, box.x1, box.y1 + 20)
end

function M.text_in_box(box, text, r, g, b)
  love.graphics.setLineWidth(1)
  local y = box.y1
  for line in text:gmatch("[^\n]+") do
    local x = box.x1
    for char in line:gmatch('.') do
      love.graphics.setColor(r, g, b)
      pcall(function() return love.graphics.print(char, x, y) end)
      x = x + state.get().font.width
    end
    love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1)
    love.graphics.line(box.x1, y + state.get().font.height, box.x2 - 1,
                       y + state.get().font.height)
    y = y + state.get().font.height
  end
end

function M.boundingbox(box)
  love.graphics.setColor(1, 0, 0)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", box.x1, box.y1, box.x2 - box.x1,
                          box.y2 - box.y1)
end

return M
