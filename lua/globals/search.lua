-- search.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local search = {
    __VERSION = { 0, 2, 0 },
}

local tables = require("globals/tables")

local browse = {
    instances = {}
}

local filter = {
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
    if browse[instanceName] ~= nil then
        return browse[instanceName].table
    else
        return nil
    end
end

local function setTable(instanceName, t)
    browse[instanceName].table = tables.deepcopy(tables.retrieveTable(t, 8))
end

local function getContents(instanceName)
    if browse[instanceName] ~= nil then
        return browse[instanceName].contents
    else
        return nil
    end
end

local function setContents(instanceName, t)
    local contents = tables.retrieveTable(t, 8)

    if tables.getTableType(contents) == "array" then
        browse[instanceName].contents = contents
    else
        browse[instanceName].contents = tables.assignKeysOrder(contents)
    end
end

local function initailize(instanceName)
    local newInstance = {
        contents = {},
        table = {},
    }

    browse[instanceName] = newInstance
end

---@param instanceName string
---@return boolean
function search.isBrowseInstance(instanceName)
    return browse[instanceName] ~= nil
end

---@param instanceName string
---@param t table
function search.setBrowseInstance(instanceName, t)
    if browse[instanceName] == nil then
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
    local item = search.getBrowseItem(instanceName, query)

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

    if browse[instanceName] ~= nil then
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

    if browse[instanceName] then
        t = getTable(instanceName)
    end

    return t
end

---@param instanceName string?
function search.flushBrowse(instanceName)
    if instanceName then
        browse[instanceName] = nil
    else
        browse = {}
    end
end

------------------
-- Filter
------------------

---@return boolean
function search.isFiltering()
    return filter.states.isFiltering
end

---@param isEnabled boolean
function search.setFiltering(isEnabled)
    filter.states.isFiltering = isEnabled
end

---@return table
function search.getActiveFilter()
    return filter.activeFilter
end

---@param instanceName string
---@return unknown
function search.getFilterQuery(instanceName)
    if filter.instances[instanceName] ~= nil then
        return filter.instances[instanceName].query
    else
        return ""
    end
end

---@param instanceName string
function search.initializeFilterInstance(instanceName)
    filter.instances[instanceName] = {
        label = instanceName,
        results = {},
        query = ""
    }
end

---@param instanceName string
---@return boolean
function search.isFilterInstance(instanceName)
    if filter.instances[instanceName] ~= nil then
        return true
    else
        return false
    end
end

---@param instanceName string
function search.setActiveFilterInstance(instanceName)
    filter.activeFilter = filter.instances[instanceName]
end

---@param instanceName string
function search.updateFilterInstance(instanceName)
    if not search.isFilterInstance(instanceName) then
        search.initializeFilterInstance(instanceName)
    end

    search.setActiveFilterInstance(instanceName)
end

local function filterElements(k, v, query)
    return string.find(string.lower(tostring(k)), string.lower(query), 1, true) or
            string.find(string.lower(tostring(v)), string.lower(query), 1, true)
end

local function filterTable(t, query, results)
    for k, v in pairs(t) do
        local matches = false
        local subResults = {}
        
        if type(v) == "table" then
            if type(next(v)) == "string" and type(k) ~= "string" then
                for subK, subV in pairs(v) do
                    if filterElements(subK, subV, query) then
                        matches = true
                        break
                    end
                end
            else
                filterTable(v, query, subResults)
            end

            if next(subResults) then
                matches = true
            end
        else
            if filterElements(k, v, query) then
                matches = true
            end
        end

        if matches then
            if type(k) == "number" then
                if next(subResults) ~= nil then
                    table.insert(results, subResults)
                else
                    table.insert(results, v)
                end
            else
                if next(subResults) ~= nil then
                    results[k] = subResults
                else
                    results[k] = v
                end
            end
        end
    end
end

---@param instanceName string
---@param t table
---@param query string
---@return table
function search.filter(instanceName, t, query)
    local results = {}

    if filter.states.isFiltering then
        filterTable(t, query, results)

        filter.instances[instanceName].results = results
    end

    return filter.instances[instanceName].results
end

---@param instanceName string?
function search.flushFilter(instanceName)
        if instanceName then
            filter.instances[instanceName] = nil
        else
            filter.instances = {}
        end
end


return search