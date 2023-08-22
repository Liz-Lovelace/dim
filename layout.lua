local M = {}

local columns = {left = 0, b = 0.475, c = 0.6, d = 0.75, right = 1}

local rows = {top = 0, b = 0.5875, c = 0.9125, bottom = 1}

local viewport = {width = 1, height = 1}

local function computeCoordinates(box)
  return {
    x1 = box.x1 * viewport.width,
    y1 = box.y1 * viewport.height,
    x2 = box.x2 * viewport.width,
    y2 = box.y2 * viewport.height
  }
end

local boxesTemplate = {
  content = {
    x1 = columns["left"],
    y1 = rows["top"],
    x2 = columns["b"],
    y2 = rows["c"]
  },
  links = {
    x1 = columns["b"],
    y1 = rows["top"],
    x2 = columns["c"],
    y2 = rows["c"]
  },
  state = {
    x1 = columns["c"],
    y1 = rows["top"],
    x2 = columns["d"],
    y2 = rows["b"]
  },
  debug = {x1 = columns["c"], y1 = rows["b"], x2 = columns["d"], y2 = rows["c"]},
  log = {
    x1 = columns["d"],
    y1 = rows["top"],
    x2 = columns["right"],
    y2 = rows["bottom"]
  },
  filesAB = {
    x1 = columns["left"],
    y1 = rows["c"],
    x2 = columns["c"],
    y2 = rows["bottom"]
  },
  focus = {
    x1 = columns["c"],
    y1 = rows["c"],
    x2 = columns["d"],
    y2 = rows["bottom"]
  }
}

function M.setViewportSize(width, height)
  viewport.width = width
  viewport.height = height
end

function M.getBox(boxName)
  local box = boxesTemplate[boxName]
  return computeCoordinates(box)
end

return M

