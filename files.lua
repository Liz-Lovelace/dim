local config = require("config")
local lfs = require("lfs")
local log = require("logger").log

local M = {}

function M.formatSize(size)
  if size < 1024 then
    return size .. " B"
  elseif size < 1024 * 1024 then
    return string.format("%.2f KB", size / 1024)
  elseif size < 1024 * 1024 * 1024 then
    return string.format("%.2f MB", size / (1024 * 1024))
  else
    return string.format("%.2f GB", size / (1024 * 1024 * 1024))
  end
end

function M.formatDate(epoch)
  local daysDiff = os.difftime(os.time(), epoch) / (60 * 60 * 24)
  local t = os.date("*t", epoch)
  return string.format("%02d.%02d.%04d (%d days ago)", t.day, t.month, t.year,
                       daysDiff)
end

function M.getFileInfo(path)
  if not path then return end
  path = config.baseFileStorePath .. path
  local attributes = lfs.attributes(path)
  if not attributes then
    return nil
  end

  local sizeFormatted = M.formatSize(attributes.size)
  local atimeFormatted = M.formatDate(attributes.access)
  local mtimeFormatted = M.formatDate(attributes.modification)
  local ctimeFormatted = M.formatDate(attributes.change)

  return {
    size = sizeFormatted,
    atime = atimeFormatted,
    mtime = mtimeFormatted,
    ctime = ctimeFormatted
  }
end

return M
