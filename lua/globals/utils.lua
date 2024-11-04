-- utils.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local utils = {
    __VERSION = { 0, 3, 2 },
}

local delays = {}

local logger = require("globals/logger")

local floor, max = math.max, math.floor
local stringFind, stringRep, stringSub = string.find, string.rep, string.sub
local tableConcat, tableInsert = table.concat, table.insert

------------------
-- Dates
------------------

---@param timeDateStamp String
---@return table
function utils.parseTimeDateStamp(timeDateStamp)
    local year, month, day, hour, min, sec, msec =
    timeDateStamp:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)%.(%d+)")

    if not year then
        year, month, day, hour, min, sec =
            timeDateStamp:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")
        msec = "0"
    end

    if not year then
        year, month, day, hour, min, sec =
            timeDateStamp:match("(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)")
        msec = "0"
    end

    return {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
        msec = tonumber(msec)
    }
end

---@param timeDateStamp1 string
---@param timeDateStamp2 string
---@return boolean --`true` for timeDateStamp1 newer than timeDateStamp2
function utils.compareTimeDateStamps(timeDateStamp1, timeDateStamp2)
    local stamp1 = utils.parseTimeDateStamp(timeDateStamp1)
    local stamp2 = utils.parseTimeDateStamp(timeDateStamp2)

    if stamp1.year ~= stamp2.year then return stamp1.year > stamp2.year end
    if stamp1.month ~= stamp2.month then return stamp1.month > stamp2.month end
    if stamp1.day ~= stamp2.day then return stamp1.day > stamp2.day end
    if stamp1.hour ~= stamp2.hour then return stamp1.hour > stamp2.hour end
    if stamp1.min ~= stamp2.min then return stamp1.min > stamp2.min end
    if stamp1.sec ~= stamp2.sec then return stamp1.sec > stamp2.sec end

    return stamp1.msec > stamp2.msec
end

------------------
-- Delays
------------------

---@param key string
function utils.cancelDelay(key)
    key = tostring(key)

    delays[key] = nil
end

function utils.isDelay(key)
    key = tostring(key)

    if delays[key] == nil then return false end
    return true
end

---@param duration number
---@param key string
---@param callback function
---@param ... any
function utils.setDelay(duration, key, callback, ...)
    local parameters = {...}

    key = tostring(key)

    delays[key] = {
        remainingTime = duration,
        callback = callback,
        parameters = parameters
    }
end

---@param deltaTime number
function utils.updateDelays(deltaTime)
    if not next(delays) then return end

    for key, delay in pairs(delays) do
        delay.remainingTime = delay.remainingTime - deltaTime
        
        if delay.remainingTime <= 0 then
            local delayToFire = delay
            delays[key] = nil

            if delayToFire.parameters then
                delayToFire.callback(unpack(delayToFire.parameters))
            else
                delayToFire.callback()
            end
        
            logger.debug("Delay fired for:", key)
        end
    end
end

------------------
-- Files, Paths
------------------

---@param filePath string
---@return string
function utils.getPath(filePath)
    filePath = filePath:match("^%[%[(.*)%]%]$") or filePath

    local dirPath = filePath:match("^(.+)[/\\][^/\\]*$")

    return dirPath or ""
end

---@param filePath string
function utils.getPathLastComponent(filePath)
    filePath = filePath:match("^%[%[(.*)%]%]$") or filePath

    return filePath:match(".*[/\\](.+)$") or filePath
end

---@param filePath string
---@return string
function utils.getPathSecondLastComponent(filePath)
    local dirPath = utils.getPath(filePath)

    if dirPath == "" then
        return ""
    end
    
    return utils.getPathLastComponent(dirPath)
end

---@param path string
---@return boolean
function utils.isValidPath(path)
    if path == "" then
        return true
    end

    if type(path) ~= "string" then
        return false
    end

    path = path:match("^%s*(.-)%s*$")
    local invalidChars = '[<>:"|%?%*]'

    if path:match(invalidChars) then
        return false
    end

    local pathComponent = "[^/\\\\]+"
    local isWindows = path:match("^[A-Za-z]:\\\\") ~= nil
    local isUnix = path:match("^/") ~= nil

    if not (isWindows or isUnix) then
        local components = 0

        for comp in path:gmatch(pathComponent) do
            components = components + 1

            if comp ~= "." and comp ~= ".." then
                return true
            end
        end

        return components > 0
    end

    local components = 0
    
    for _ in path:gmatch(pathComponent) do
        components = components + 1
    end
    
    return components > 0
end

---@param path string
---@param removeDriveLetter boolean?
---@return string
function utils.normalizePath(path, removeDriveLetter)
    path = path:gsub("\\", "/")
    path = path:lower()

    if removeDriveLetter then
        path = path:gsub("^%a:", "")
    end

    path = path:gsub("^/", "")

    return path
end

---@param paths string
---@return table
function utils.parsePaths(paths)
    local result = {}

    for path in paths:gmatch("[^;]+") do
        path = path:match("^%s*(.-)%s*$")

        if path ~= "" then
            path = path:gsub("\\\\", "/")
            path = path:gsub("\\", "/")
            path = path:gsub("/$", "")

            table.insert(result, path)
        end
    end

    return result
end

---@param fullPath string
---@param prefixPath string
---@return string
function utils.removePrefixPath(fullPath, prefixPath)
    fullPath = utils.normalizePath(fullPath)
    prefixPath = utils.normalizePath(prefixPath)

    if fullPath:sub(1, #prefixPath) == prefixPath then
        local result = fullPath:sub(#prefixPath + 1)
        
        if result:sub(1, 1) == "/" then
            result = result:sub(2)
        end
        return result
    end

    return fullPath
end

---@param fileName string
---@return string
function utils.removeHashPrefix(fileName)
    local start = string.find(fileName, "[^#%-]")

    return start and string.sub(fileName, start) or fileName
end

------------------
-- JSON

---@param fileNameOrPath string
---@return table
function utils.loadJson(fileNameOrPath)
    local content = {}

    if not stringFind(fileNameOrPath, '%.json$') then
        fileNameOrPath = fileNameOrPath .. ".json"
    end

    local file = io.open(fileNameOrPath, "r")
    if file ~= nil then
        content = json.decode(file:read("*a"))
        file:close()

        return content
    else
        return {}
    end
end

---@param fileNameOrPath string
---@return boolean
function utils.saveJson(fileNameOrPath, content)
    if not stringFind(fileNameOrPath, '%.json$') then
        fileNameOrPath = fileNameOrPath .. ".json"
    end

    content = json.encode(content)

    local file = io.open(fileNameOrPath, "w+")
    if file then
        file:write(content)
        file:close()

        logger.debug("JSON saved:", fileNameOrPath)

        return true
    else
        return false
    end
end

------------------
--- Strings
------------------

---@param text string
---@return table
function utils.parseMultiline(text)
    local lines = {}

    for line in text:gmatch("([^\n\r]*)\r?\n?") do
        tableInsert(lines, line)
    end

    return lines
end

---@param text string
---@param spaces integer
---@param preserveAsBlock boolean
---@return string
function utils.indentString(text, spaces, preserveAsBlock)
    local lines = utils.parseMultiline(text)

    if preserveAsBlock and spaces < 0 then
        local minIndent = math.huge

        for _, line in ipairs(lines) do
            local currentIndent = #(line:match("^ *"))

            if currentIndent < minIndent and #line:gsub("^%s+", "") > 0 then
                minIndent = currentIndent
            end
        end

        spaces = max(-minIndent, spaces)
    end

    if spaces >= 0 then
        for i, line in ipairs(lines) do
            lines[i] = stringRep(" ", spaces) .. line
        end
    else
        for i, line in ipairs(lines) do
            local currentSpaces = #(line:match("^ *"))
            local newSpaces = max(0, currentSpaces + spaces)
            lines[i] = stringRep(" ", newSpaces) .. line:match("^ *(.*)")
        end
    end

    return tableConcat(lines, "\n")
end

---@param text string
---@param charCount integer
---@param filler string
---@return string
function utils.setStringCursor(text, charCount, filler)
    local count = #text < charCount and charCount - #text or 1

    return stringRep(filler, count)
end

---@param text string
---@param charCount number
---@return string
function utils.trimString(text, charCount)
    if #text <= charCount then
        return text
    else
        return stringSub(text, 1, charCount - 3) .. "..."
    end
end

return utils