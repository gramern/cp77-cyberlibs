-- utils.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local utils = {
  __VERSION = { 0, 2, 0 },
}

local delays = {}

local logger = require("globals/logger")

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
function utils.SetDelay(duration, key, callback, ...)
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

  local delaysToRemove = {}

  for key, delay in pairs(delays) do
    delay.remainingTime = delay.remainingTime - deltaTime
    
    if delay.remainingTime <= 0 then
      if delay.parameters then
        delay.callback(unpack(delay.parameters))
      else
        delay.callback()
      end
    
      table.insert(delaysToRemove, key)
      logger.debug("Delay fired for:", key)
    end
  end

  for _, key in ipairs(delaysToRemove) do
    delays[key] = nil
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

------------------
-- JSON

---@param fileNameOrPath string
---@return table
function utils.loadJson(fileNameOrPath)
  local content = {}

  if not string.find(fileNameOrPath, '%.json$') then
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
  if not string.find(fileNameOrPath, '%.json$') then
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
---@param charCount number
---@return string
function utils.trimString(text, charCount)
  if #text <= charCount then
    return text
  else
    return string.sub(text, 1, charCount - 3) .. "..."
  end
end

return utils