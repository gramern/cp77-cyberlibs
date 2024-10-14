local style = {
  __VERSION = { 0, 2, 0 },
}

local logger = require("globals/logger")

local var = {
  print = true
}

---@param title string
---@param forceLog boolean
function style.formatHeader(title, forceLog)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(0, forceLog, "| DATA EXTRACTION: " .. string.upper(title))
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
  else
    logger.custom(0, forceLog, title)
  end
end

---@param forceLog boolean
---@param ... any
function style.formatEntry(forceLog, ...)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|", ...)
  else
    logger.custom(0, forceLog, ...)
  end
end

---@param itemsNumber number
---@param forceLog boolean
function style.formatFooter(itemsNumber, forceLog)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(1, forceLog, " DATA EXTRACTION COMPLETE ")
    logger.custom(1, forceLog, string.format(" Extracted %d data packets ", itemsNumber))
  else
    logger.custom(0, forceLog, "Found items:", itemsNumber)
  end
end

---@param title string
---@param forceLog boolean
function style.formatFailHeader(title, forceLog)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(0, forceLog, "| DATA EXTRACTION FAILED: " .. string.upper(title))
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(1, forceLog, " No data found in memory. Initialize databank first. ")
  else
    logger.custom(0, forceLog, "No table found in memory. Initialize a table first.")
  end
end

---@param variable string
---@param isEnabled boolean
function style.setEnabled(variable, isEnabled)
  var[variable] = isEnabled
end

---@param variable string
---@return boolean
function style.isEnabled(variable)
  return var[variable]
end

return style