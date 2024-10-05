-- search.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local search = {
  __VERSION = { 0, 2, 0 },
}

local tables = require("globals/tables")

local instances = {}

local function getTable(instanceName)
  return instances[instanceName].table
end

local function setTable(instanceName, t)
  instances[instanceName].table = tables.deepcopy(tables.retrieveTable(t))
end

local function getContents(instanceName)
  return instances[instanceName].contents
end

local function setContents(instanceName, t)
  local contents = tables.retrieveTable(t)

  if tables.getTableType(contents) == "array" then
    instances[instanceName].contents = contents
  else
    instances[instanceName].contents = tables.assignKeysOrder(contents)
  end
end

local function initailize(instanceName)
  local newInstance = {
    contents = {},
    table = {},
  }

  instances[instanceName] = newInstance
end

local function getNewContents(instanceName, query)
  local contents = getContents(instanceName)
  local t = getTable(instanceName)

  if type(query) == "number" then
    local k = contents[query]
    return k ~= nil and t[k] or nil
  elseif type(query) == "string" then
    return t[query]
  end

  return nil
end

function search.setInstance(instanceName, t)
  if instances[instanceName] == nil then
    initailize(instanceName)
  end

  setTable(instanceName, t)
  setContents(instanceName, t)
end

function search.isItem(instanceName, query)
  if getNewContents(instanceName, query) then
    return true
  else
    return false
  end
end

function search.followItem(instanceName, query)
  local contents = getNewContents(instanceName, query)

  if contents then
    search.setInstance(instanceName, contents)
    return true
  else
    return false
  end
end

function search.getContents(instanceName)
  local contents

  if instances[instanceName] ~= nil then
    contents = getContents(instanceName)
  end

  if contents ~= nil then
    return contents, #contents
  else
    return contents, 0
  end
end

function search.getTable(instanceName)
  local t

  if instances[instanceName] then
    t = getTable(instanceName)
  end

  return t
end

function search.getItemType(instanceName, query)
  local contents = getContents(instanceName)
  local t = getTable(instanceName)
  local value

  if not contents or not table then
    return nil
  end
  
  if type(query) == "number" then
    local k = contents[query]
    value = k ~= nil and t[k] or nil
  elseif type(query) == "string" then
    value = t[query]
  end

  return type(value)
end

function search.filter(t, query)
  local results = {}

  for k, v in pairs(t) do
    if type(v) == "string" and string.find(string.lower(v), string.lower(query)) then
      table.insert(results, {k = k, v = v})
    elseif type(v) == "number" and tostring(v):find(query) then
      table.insert(results, {k = k, v = v})
    end
  end

  return results
end

-- @param `instanceName` string; optional
function search.flush(instanceName)
  if instanceName then
    instances[instanceName] = nil
  else
    instances = {}
  end
end

return search