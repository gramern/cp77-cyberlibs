-- search.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local search = {
  __VERSION = { 0, 2, 0 },
}

local tables = require("globals/tables")

local browseVars = {
  instances = {}
}

local filterVars = {
  activeFilter = {},
  instances = {},
  states = {
    isFiltering = false
  }
}

local stringFind, stringLower = string.find, string.lower

------------------
-- Browse
------------------

local function getTable(instanceName)
  if browseVars[instanceName] ~= nil then
    return browseVars[instanceName].table
  else
    return nil
  end
end

local function setTable(instanceName, t)
  browseVars[instanceName].table = tables.deepcopy(tables.retrieveTable(t, 8))
end

local function getContents(instanceName)
  if browseVars[instanceName] ~= nil then
    return browseVars[instanceName].contents
  else
    return nil
  end
end

local function setContents(instanceName, t)
  local contents = tables.retrieveTable(t, 8)

  if tables.getTableType(contents) == "array" then
    browseVars[instanceName].contents = contents
  else
    browseVars[instanceName].contents = tables.assignKeysOrder(contents)
  end
end

local function initailize(instanceName)
  local newInstance = {
    contents = {},
    table = {},
  }

  browseVars[instanceName] = newInstance
end

---@param instanceName string
---@return boolean
function search.isBrowseInstance(instanceName)
  return browseVars[instanceName] ~= nil
end

---@param instanceName string
---@param t table
function search.setBrowseInstance(instanceName, t)
  if browseVars[instanceName] == nil then
    initailize(instanceName)
  end

  setTable(instanceName, t)
  setContents(instanceName, t)
end

---@param instanceName string
---@param query string
---@return boolean
function search.isBrowseItem(instanceName, query)
  if search.get(instanceName, query) then
    return true
  else
    return false
  end
end

---@param instanceName string
---@param query string
---@return boolean --`true` if success, `false` otherwise
---@return string --type of the requested item
function search.followBrowseItem(instanceName, query)
  local item = search.get(instanceName, query)

  if item then
    local itemType = type(item)

    if itemType == "table" then
      search.setBrowseInstance(instanceName, item)

      return true, "table"
    else
      return true, itemType
    end
  else
    return false, "nil"
  end
end

---@param instanceName string
---@param query string
---@return any
function search.getBrowseItem(instanceName, query)
  local contents = getContents(instanceName)
  local t = getTable(instanceName)

  if contents and t then
    if type(query) == "number" then
      local k = contents[query]
      return k ~= nil and t[k] or nil
    elseif type(query) == "string" then
      return t[query]
    end
  end

  return nil
end

---@param instanceName string
---@return table|nil --table of contents (array) for current table
---@return integer --number of items
function search.getBrowseContents(instanceName)
  local contents

  if browseVars[instanceName] ~= nil then
    contents = getContents(instanceName)
  end

  if contents ~= nil then
    return contents, #contents
  else
    return nil, 0
  end
end

---@param instanceName string
---@return table|nil --current table
function search.getBrowseTable(instanceName)
  local t

  if browseVars[instanceName] then
    t = getTable(instanceName)
  end

  return t
end

---@param instanceName string?
function search.flushBrowse(instanceName)
  if instanceName then
    browseVars[instanceName] = nil
  else
    browseVars = {}
  end
end

------------------
-- Filter
------------------

---@return boolean
function search.isFiltering()
  return filterVars.states.isFiltering
end

---@param isEnabled boolean
function search.setFiltering(isEnabled)
  filterVars.states.isFiltering = isEnabled
end

---@return table
function search.getActiveFilter()
  return filterVars.activeFilter
end

---@param instanceName string
---@return unknown
function search.getFilterQuery(instanceName)
  if filterVars.instances[instanceName] ~= nil then
    return filterVars.instances[instanceName].query
  else
    return ""
  end
end

---@param instanceName string
function search.initializeFilterInstance(instanceName)
  filterVars.instances[instanceName] = {
    label = instanceName,
    query = ""
  }
end

---@param instanceName string
---@return boolean
function search.isFilterInstance(instanceName)
  if filterVars.instances[instanceName] ~= nil then
    return true
  else
    return false
  end
end

---@param instanceName string
function search.setActiveFilterInstance(instanceName)
  filterVars.activeFilter = filterVars.instances[instanceName]
end

---@param instanceName string
function search.updateFilterInstance(instanceName)
  if not search.isFilterInstance(instanceName) then
    search.initializeFilterInstance(instanceName)
  end

  search.setActiveFilterInstance(instanceName)
end

local function filterTable(t, query, results, path)
  for k, v in pairs(t) do
    local currentPath = path and (path .. "." .. tostring(k)) or tostring(k)
  
    if type(v) == "table" then
      filterTable(v, query, results, currentPath)
    else
      local stringValue = tostring(v)

      if stringFind(stringLower(tostring(k)), stringLower(query), 1, true) or
         stringFind(stringLower(stringValue), stringLower(query), 1, true) then
        results[currentPath] = stringValue
      end
    end
  end
end

---@param t table
---@param query string
---@return table
function search.filter(t, query)
  local results = {}

  filterTable(t, query, results)

  return results
end


return search