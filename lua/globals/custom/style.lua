local style = {
    __VERSION = { 0, 2, 0 },
}

local isStyle = true

---@param title string
---@return string
function style.formatHeader(title)
    local header

    if isStyle then
        header = "|----------------------------------------------------------------------------------" ..
                    "\n| DATA EXTRACTION: " .. string.upper(title) ..
                    "\n|----------------------------------------------------------------------------------"
    else
        header = title ..
                    "\n----------------------------------------------------------------------------------"
    end

    return header
end

---@param text string
---@return string
function style.formatEntry(text)
    local entry

    if isStyle then
        entry = "| " .. text
    else
        entry = text
    end

    return entry
end

---@param itemsNumber number
---@return string
function style.formatFooter(itemsNumber)
    local footer

    if isStyle then
        footer = "|----------------------------------------------------------------------------------" ..
                    "\n[ DATA EXTRACTION COMPLETE ]\n" ..
                    string.format("[ Extracted %d data packets. ]", itemsNumber)
    else
        footer = "Items: " .. itemsNumber
    end

    return footer
end

---@param title string
function style.formatFailHeader(title)
    local header

    if isStyle then
        header = "|----------------------------------------------------------------------------------" ..
                    "\n| DATA EXTRACTION FAILED: " .. string.upper(title) ..
                    "\n|----------------------------------------------------------------------------------" ..
                    "\n[ No data found in memory. ]"
    else
        header = "Nothing to print."
    end

    return header
end

---@param isEnabled boolean
function style.setEnabled(isEnabled)
    isStyle = isEnabled
end

---@return boolean
function style.isEnabled()
    return isStyle
end

return style