local json = require("dkjson")

local function readDB()
  local f = io.open("dim.json", "r")
  if not f then return {} end

  local content = f:read("*all")
  f:close()

  local status, result = pcall(json.decode, content)
  if status then
    return result
  else
    return {}
  end
end

local function writeDB(db)
  local f = io.open("dim.json", "w")
  if not f then
    print("Error: Could not write to 'dim.json'")
    return
  end

  f:write(json.encode(db))
  f:close()
end

local function connect(file1, file2)
  if file1 == file2 then return "Failed: Files are identical" end

  local pair = {file1, file2}
  table.sort(pair)

  local db = readDB()

  for _, v in ipairs(db) do
    if v[1] == pair[1] and v[2] == pair[2] then
      return "Failed: Connection already exists"
    end
  end

  table.insert(db, pair)
  writeDB(db)
  return "Success: Files connected"
end

local function disconnect(file1, file2)
  local pair = {file1, file2}
  table.sort(pair)

  local db = readDB()

  for i, v in ipairs(db) do
    if v[1] == pair[1] and v[2] == pair[2] then
      table.remove(db, i)
      writeDB(db)
      return "Success: Files disconnected"
    end
  end
  return "Failure: Files to disconnect not found"
end

local function connectedFiles(file)
  local db = readDB()
  local connected = {}

  for _, v in ipairs(db) do
    if v[1] == file then
      table.insert(connected, v[2])
    elseif v[2] == file then
      table.insert(connected, v[1])
    end
  end

  return connected
end

return {
  connect = connect,
  disconnect = disconnect,
  connectedFiles = connectedFiles
}

