local M = {}
local state = require("state")

local columns = {
  screenLeft = 0,
  left = 0.01,
  b = 0.475,
  c = 0.63,
  d = 0.8,
  right = 0.99,
  screenRight = 1
}

local rows = {
  screenTop = 0,
  top = 0.01,
  a = 0.1,
  b = 0.3,
  bottom = 0.91,
  screenBottom = 1
}

M.columns = columns
M.rows = rows

local viewport = {width = 1, height = 1}

local Box = {}
Box.__index = Box

function Box:new(box)
  local instance = setmetatable({}, Box)
  instance.x1 = box.x1
  instance.x2 = box.x2
  instance.y1 = box.y1
  instance.y2 = box.y2
  return instance
end

function Box:getWidth() return self.x2 - self.x1 end

function Box:getHeight() return self.y2 - self.y1 end

function Box:getCharWidth()
  return math.floor(self:getWidth() / state.get().font.width)
end

function Box:getCharHeight()
  return math.floor(self:getHeight() / state.get().font.height)
end

function Box:inset(width)
  return Box:new({
    x1 = self.x1 + width,
    y1 = self.y1 + width,
    x2 = self.x2 - width,
    y2 = self.y2 - width
  })
end

local function computeCoordinates(box)
  return {
    x1 = math.floor(box.x1 * viewport.width),
    y1 = math.floor(box.y1 * viewport.height),
    x2 = math.floor(box.x2 * viewport.width),
    y2 = math.floor(box.y2 * viewport.height)
  }
end

local boxesTemplate = {
  content = {
    x1 = columns["left"],
    y1 = rows["top"],
    x2 = columns["b"],
    y2 = rows["bottom"]
  },
  links = {
    x1 = columns["b"],
    y1 = rows["a"],
    x2 = columns["c"],
    y2 = rows["bottom"]
  },
  debug = {
    x1 = columns["c"],
    y1 = rows["top"],
    x2 = columns["d"],
    y2 = rows["b"]
  },
  state = {x1 = columns["c"], y1 = rows["b"], x2 = columns["d"], y2 = rows["bottom"]},
  extraText = {
    x1 = columns["d"],
    y1 = rows["top"],
    x2 = columns["right"],
    y2 = rows["bottom"]
  },
  filesAB = {
    x1 = columns["b"],
    y1 = rows["top"],
    x2 = columns["c"],
    y2 = rows["a"]
  },
  focus = {
    x1 = columns["c"],
    y1 = rows["bottom"],
    x2 = columns["d"],
    y2 = rows["bottom"]
  },
  runlines = {
    x1 = columns["screenLeft"],
    x2 = columns["screenRight"],
    y1 = rows["bottom"],
    y2 = rows["screenBottom"]
  }
}

function M.setViewportSize(width, height)
  viewport.width = width
  viewport.height = height
end

function M.getBox(boxName)
  local box = boxesTemplate[boxName]
  return Box:new(computeCoordinates(box))
end

return M

