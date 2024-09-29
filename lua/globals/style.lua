local style = {
  __VERSION = { 0, 2, 0 },
}

local logger = require("globals/logger")

local var = {
  print = true
}

function style.formatHeader(title, forceLog)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(0, forceLog, "| DATA EXTRACTION: " .. string.upper(title))
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
  else
    logger.custom(0, forceLog, title)
  end
end

function style.formatEntry(forceLog, ...)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|", ...)
  else
    logger.custom(0, forceLog, ...)
  end
end

function style.formatFooter(itemsNumber, forceLog)
  if style.isEnabled('print') then
    logger.custom(0, forceLog, "|----------------------------------------------------------------------------------")
    logger.custom(1, forceLog, " DATA EXTRACTION COMPLETE ")
    logger.custom(1, forceLog, string.format(" Extracted %d data packets ", itemsNumber))
  else
    logger.custom(0, forceLog, "Found items:", itemsNumber)
  end
end

function style.setEnabled(variable, isEnabled)
  var[variable] = isEnabled
end

function style.isEnabled(variable)
  return var[variable]
end

return style