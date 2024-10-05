-- logger.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local logger = {
  __VERSION = { 0, 2, 0 },
}

local var = {
  isDebug = false,
  modName = "logger"
}

local function bracketizer(contents)
  return "[" .. tostring(contents) .. "]"
end

local function printer(contents, forceLog, debug)
  contents = tostring(contents)

  if not debug then
    print(contents)
  else
    if not var.isDebug then return end
    print(contents)
  end

  if forceLog then
    spdlog.error(contents)
  else
    if not var.isDebug then return end
    spdlog.error(contents)
  end
end

local function parser(type, ...)
  local contents = {...}

  if #contents == 0 then
    local parsed = bracketizer(var.modName) .. " " .. bracketizer(type) .." " .. "No data found."
    printer(parsed, true)

    return
  end

  for i, v in ipairs(contents) do
    contents[i] = tostring(v)
  end

  return bracketizer(var.modName) .. " " .. bracketizer(type) .. " " .. table.concat(contents, " ")
end

function logger.debug(...)
  printer(parser("debug", ...), false, true)
end

function logger.error(...)
  printer(parser("error", ...), true)
end

function logger.info(...)
  printer(parser("info", ...))
end

function logger.warning(...)
  printer(parser("warning", ...))
end

---@param bracketizeParameter number
---@param forceLog boolean
---@param ... any
function logger.custom(bracketizeParameter, forceLog, ...)
  local contents = {...}

  if #contents == 0 then
    logger.info()

    return
  end

  for i, v in ipairs(contents) do
    if i <= bracketizeParameter then
      contents[i] = bracketizer(tostring(v))
    else
      contents[i] = tostring(v)
    end
  end

  local formattedContents = bracketizer(var.modName) .. " " .. table.concat(contents, " ")

  printer(formattedContents, forceLog)
end

---@param isDebug boolean
function logger.setDebug(isDebug)
  var.isDebug = isDebug
end

---@param name string
function logger.setModName(name)
  var.modName = name
end

return logger