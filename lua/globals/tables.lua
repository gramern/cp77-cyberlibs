-- tables.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local tables = {
  __VERSION = { 0, 2, 0 },
}

---@param contents table
---@return table
function tables.deepcopy(contents)
  local copy

  if type(contents) == 'table' then
    copy = {}

    for k, v in next, contents, nil do
      copy[tables.deepcopy(k)] = tables.deepcopy(v)
    end

    setmetatable(copy, tables.deepcopy(getmetatable(contents)))
  else
    copy = contents
  end

  return copy
end

---@param t table
---@return table
function tables.assignKeysOrder(t)
  local sortedKeys = {}

  for k in pairs(t) do
    table.insert(sortedKeys, k)
  end
  table.sort(sortedKeys)

  return sortedKeys
end

---@param t table
---@return string
function tables.getTableType(t)
  local count = 0
  local isSequential = true
 
  for k, v in pairs(t) do
    count = count + 1
    if type(k) ~= "number" or k ~= count then
      isSequential = false
      break
    end
  end

  if count == 0 then
    return "empty"
  elseif isSequential and count == #t then
    return "array"
  else
    return "associative"
  end
end

function tables.add(addTo, addFrom)
  if addFrom == nil then return addTo end

  for k, v in pairs(addFrom) do
    if addTo[k] == nil then
      if type(v) == "table" then
        addTo[k] = tables.add({}, v)
      else
        addTo[k] = v
      end
    elseif type(addTo[k]) == "table" and type(v) == "table" then
      tables.add(addTo[k], v)
    end
  end

  return addTo
end

---@param mergeTo table
---@param mergeA table
---@return table
function tables.mergeTables(mergeTo, mergeA)
  if mergeA == nil then return mergeTo end

  for k, v in pairs(mergeA) do
    if type(v) == "table" then
      if type(mergeTo[k]) == "table" then
        mergeTo[k] = tables.mergeTables(mergeTo[k], v)
      else
        mergeTo[k] = tables.mergeTables({}, v)
      end
    else
      mergeTo[k] = v
    end
  end

  return mergeTo
end

---@param func function
---@return table
function tables.retrieveTable(func)
  local result = func
  local maxDepth = 8
  local depth = 0

  while type(result) == "function" and depth < maxDepth do
    result = result()
    depth = depth + 1
  end

  return result
end

---@param t table
---@return string
function tables.tableToString(t)
  if t == nil then return nil end

  local result = "{"

  for k, v in pairs(t) do
    if type(v) == "table" then
      result = result .. k .. " = " .. tables.tableToString(v) .. ", "
    else
      result = result .. k .. " = " .. tostring(v) .. ", "
    end
  end

  return result:sub(1, -3) .. "}"
end

return tables