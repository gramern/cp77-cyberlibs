-- utils.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local utils = {
    __VERSION = { 0, 2, 0 },
}

local delays = {}

local logger = require("globals/logger")

local floor, max = math.max, math.floor
local stringFind, stringRep, stringSub = string.find, string.rep, string.sub
local tableConcat, tableInsert = table.concat, table.insert

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

    local delayToFire

    for key, delay in pairs(delays) do
        delay.remainingTime = delay.remainingTime - deltaTime
        
        if delay.remainingTime <= 0 then
            delayToFire = delay
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
-- Files
------------------

---@param path string
function utils.getFileName(path)
    path = path:match("^%[%[(.*)%]%]$") or path

    return path:match(".*[/\\](.+)$") or path
end

function utils.normalizePath(path)
    path = path:gsub("\\", "/")
    path = path:lower()
    path = path:gsub("^/", "")
    
    return path
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