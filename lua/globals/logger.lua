local logger = {
  __VERSION = { 0, 2, 0 },
}

local var = {
  isDebug = false
}

local function bracketizer(contents)
  return "[" .. tostring(contents) .. "]"
end

local function printer(contents, forceLog)
  contents = tostring(contents)
  print(contents)

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
    local parsed = bracketizer(Cyberlibs.__NAME) .. " " .. bracketizer(type) .." " .. "No data found."
    printer(parsed, true)

    return
  end

  for i, v in ipairs(contents) do
    contents[i] = tostring(v)
  end

  return bracketizer(Cyberlibs.__NAME) .. " " .. bracketizer(type) .. " " .. table.concat(contents, " ")
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

  local formattedContents = bracketizer(Cyberlibs.__NAME) .. " " .. table.concat(contents, " ")

  printer(formattedContents, forceLog)
end

function logger.setDebug(isDebug)
  var.isDebug = isDebug
end

return logger