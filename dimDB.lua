local sqlite3 = require("lsqlite3")
local log = require("logger").log
local config = require("config")

local M = {}

local db = sqlite3.open(config.baseFileStorePath .. "dim.db")

local function query(queryTemplate, ...)
  local stmt = db:prepare(queryTemplate)
  stmt:bind_values(...)
  local res = stmt:step()
  if res == sqlite3.DONE or res == sqlite3.ERROR then
    return nil
  end
  return stmt:get_value(0)
end

function M.closeDB()
  db:close()
end

function M.initializeDB()
  db:exec[[
    CREATE TABLE IF NOT EXISTS files (
      id INTEGER PRIMARY KEY,
      filename TEXT UNIQUE
    );
  ]]

  db:exec[[
    CREATE TABLE IF NOT EXISTS links (
      file1_id INTEGER,
      file2_id INTEGER,
      FOREIGN KEY(file1_id) REFERENCES files(id),
      FOREIGN KEY(file2_id) REFERENCES files(id)
    );
  ]]
end

function M.getFileID(filename)
  return query("SELECT id FROM files WHERE filename = ?", filename)
end

function M.insertFile(filename)
  print('inserting', filename)
  query("INSERT OR IGNORE INTO files VALUES (NULL, ?)", filename)
end

function M.connect(file1, file2)
  if file1 == file2 then 
    log("LINK CONNECTION ERROR: files are identical")
    return
  end

  M.insertFile(file1)
  M.insertFile(file2)

  local file1_id = M.getFileID(file1)
  local file2_id = M.getFileID(file2)

  if file1_id > file2_id then 
    file1_id, file2_id = file2_id, file1_id 
  end

  local existing_link = query("SELECT 1 FROM links WHERE file1_id = ? AND file2_id = ?", file1_id, file2_id)
  if existing_link then
    log("LINK CONNECTION ERROR: link already exists")
    return 
  end

  query("INSERT INTO links (file1_id, file2_id) VALUES (?, ?)", file1_id, file2_id)
end

function M.disconnect(file1, file2)
  local file1_id = M.getFileID(file1)
  local file2_id = M.getFileID(file2)

  if not file1_id or not file2_id then
    log("LINK DISCONNECTION ERROR: one of the files not found")
  end

  if file1_id > file2_id then 
    file1_id, file2_id = file2_id, file1_id 
  end

  query("DELETE FROM links WHERE file1_id = ? AND file2_id = ?", file1_id, file2_id)
end

function M.connectedFiles(file)
  local file_id = M.getFileID(file)

  local query = "SELECT filename FROM files JOIN links ON id = file1_id WHERE file2_id = ? UNION SELECT filename FROM files JOIN links ON id = file2_id WHERE file1_id = ?"
  
  local stmt = db:prepare(query)
  stmt:bind_values(file_id, file_id)
  local connected = {}
  
  for row in stmt:nrows() do
    table.insert(connected, row.filename)
  end

  return connected
end

return M

