local style = {
    __VERSION = { 0, 2, 0 },
}

local logger = require("globals/logger")

local var = {
    stylize = true,
}

---@param title string
---@param forceLog boolean
function style.formatHeader(title, forceLog)
    if style.isEnabled() then
        logger.custom(true, forceLog, 0, "|----------------------------------------------------------------------------------")
        logger.custom(true, forceLog, 0, "| DATA EXTRACTION: " .. string.upper(title))
        logger.custom(true, forceLog, 0, "|----------------------------------------------------------------------------------")
    else
        logger.custom(false, forceLog, 0, title)
        logger.custom(false, forceLog, 0, "----------------------------------------------------------------------------------")
    end
end

---@param forceLog boolean
---@param ... any
function style.formatEntry(forceLog, ...)
    if style.isEnabled() then
        logger.custom(true, forceLog, 0, "|", ...)
    else
        logger.custom(false, forceLog, 0, ...)
    end
end

---@param itemsNumber number
---@param forceLog boolean
function style.formatFooter(itemsNumber, forceLog)
    if style.isEnabled() then
        logger.custom(true, forceLog, 0, "|----------------------------------------------------------------------------------")
        logger.custom(true, forceLog, 1, " DATA EXTRACTION COMPLETE ")
        logger.custom(true, forceLog, 1, string.format(" Extracted %d data packets ", itemsNumber))
    else
        logger.custom(false, forceLog, 0, "Items:", itemsNumber)
    end
end

---@param title string
---@param forceLog boolean
function style.formatFailHeader(title, forceLog)
    if style.isEnabled() then
        logger.custom(true, forceLog, 0, "|----------------------------------------------------------------------------------")
        logger.custom(true, forceLog, 0, "| DATA EXTRACTION FAILED: " .. string.upper(title))
        logger.custom(true, forceLog, 0, "|----------------------------------------------------------------------------------")
        logger.custom(true, forceLog, 1, " No data found in memory. Initialize databank first. ")
    else
        logger.custom(false, forceLog, 0, "Failed to print.")
    end
end

---@param isEnabled boolean
function style.setEnabled(isEnabled)
    var.stylize = isEnabled
end

---@return boolean
function style.isEnabled()
    return var.stylize
end

return style