local M = {}

local await_list = {}

function M.start(func)
  local co = coroutine.create(func)
  coroutine.resume(co)
end

function M.await(condition)
  local co = coroutine.running()
  if not co then
    error("Await can only be used inside a coroutine started by async.start")
  end

  table.insert(await_list, {co = co, condition = condition})

  return coroutine.yield()
end

function M.tick()
  local i = 1
  while i <= #await_list do
    local awaiting = await_list[i]
    if awaiting.condition() then
      table.remove(await_list, i)
      coroutine.resume(awaiting.co)
    else
      i = i + 1
    end
  end
end

return M

