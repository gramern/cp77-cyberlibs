local publicApi = {
    __VERSION = { 0, 2, 0 },
}

local logger = require("globals/logger")
local search = require("globals/search")
local style = require("globals/custom/style")
local utils = require("globals/utils")

function publicApi.Version()
    return table.concat(Cyberlibs.__VERSION, ".")
end

function publicApi.SetPrintingStyle(isEnabled)
    style.setEnabled('print', isEnabled)
    logger.info("Printing in style:", isEnabled)
end

local function printHelpTopics(t, forceLog)
    for i, v in ipairs(t) do
        style.formatEntry(forceLog, i, v)
    end
end

function publicApi.Help(query, forceLog)
    local help = require("knowledgeBase/help")
    local isTopic, itemType

    if not query or query == 0 then
        search.setBrowseInstance('help', help.getTable())
    end

    local contents, itemsNumber = search.getBrowseContents('help')

    if contents then
        if query and query ~= 0 then
            isTopic, itemType = search.followBrowseItem('help', query)
        else
            isTopic = true
            itemType = "table"
        end

        style.formatHeader("HELP FILES", forceLog)
    else
        style.formatFailHeader("HELP FILES", forceLog)
        logger.custom(1, forceLog, ' Type Cyberlibs.Help() to start ')
    
        return
    end

    if isTopic then
        contents, itemsNumber = search.getBrowseContents('help')

        if itemType == "table" then
            printHelpTopics(contents, forceLog)
        else
            local v = search.getBrowseItem('help', query)

            if type(v) == "string" then
                local text = utils.indentString(v, -20, true)
                local lines = utils.parseMultiline(text)
                itemsNumber = #lines

                for _, line in ipairs(lines) do
                    style.formatEntry(forceLog, line)
                end
            else
                itemsNumber = 1

                style.formatEntry(forceLog, v)
            end
        end
    else
        printHelpTopics(contents, forceLog)
    end

    style.formatFooter(itemsNumber, forceLog)
    logger.custom(0, forceLog, "")

    if not isTopic then
        logger.custom(1, forceLog, " File not found in databank. ")
        logger.custom(1, forceLog, ' Type Cyberlibs.Help() to return ')
    end

    logger.custom(1, forceLog, ' Type Cyberlibs.Help(number) to open file ')
end

function publicApi.GetVersion(fileNameOrPath)
    local versions = require("knowledgeBase/versions")
    search.setBrowseInstance('getVersion', versions.getTable())
    local fileName = utils.getFileName(fileNameOrPath)
    local isData = search.followBrowseItem('getVersion', fileName)
    local version

    if isData then
        version = search.getBrowseTable('getVersion')[GameModule.GetTimeDateStamp(fileNameOrPath)]
    end

    if not version then
        version = GameModule.GetVersion(fileNameOrPath)
    end

    return version
end

function publicApi.PrintAttribute(fileNameOrPath, attribute, forceLog)
    local attributes = {
        ["CompanyName"] = function() return GameModule.GetCompanyName(fileNameOrPath) end,
        ["Description"] = function() return GameModule.GetDescription(fileNameOrPath) end,
        ["EntryPoint"] = function() return GameModule.GetEntryPoint(fileNameOrPath) end,
        ["FilePath"] = function() return GameModule.GetFilePath(fileNameOrPath) end,
        ["FileSize"] = function() return GameModule.GetFileSize(fileNameOrPath) end,
        ["FileType"] = function() return GameModule.GetFileType(fileNameOrPath) end,
        ["LoadAddress"] = function() return GameModule.GetLoadAddress(fileNameOrPath) end,
        ["MappedSize"] = function() return GameModule.GetMappedSize(fileNameOrPath) end,
        ["TimeDateStamp"] = function() return GameModule.GetTimeDateStamp(fileNameOrPath) end,
        ["Version"] = function() return GameModule.GetVersion(fileNameOrPath) end,
    }

    local arrays = {
        ["Export"] = function() return publicApi.PrintExport(fileNameOrPath, forceLog) end,
        ["Import"] = function() return publicApi.PrintImport(fileNameOrPath, forceLog) end,
    }

    if attributes[attribute] ~= nil then
        logger.custom(0, forceLog, attributes[attribute]())
    elseif arrays[attribute] ~= nil then
        arrays[attribute]()
    else
        logger.custom(1, false, " Attribute not found in databank. ")
    end
end

function publicApi.PrintExport(fileNameOrPath, forceLog)

    if not GameModule.IsLoaded(fileNameOrPath) then
        logger.custom(1, false, " Module not found in databank. ")

        return
    end

    local exportArray = GameModule.GetExport(fileNameOrPath)

    if #exportArray == 0 then
        logger.info()

        return
    end

    style.formatHeader("EXPORTS", forceLog)
    style.formatEntry(forceLog, "TARGET MODULE:", fileNameOrPath)

    local forwarder

    for i, export in ipairs(exportArray) do
        forwarder = nil

        if export.forwarderName ~= "" then
            forwarder = "Forwarder: " .. export.forwarderName
        end

        style.formatEntry(forceLog, "Entry", tostring(i) .. ":", export.entry, "Ordinal:", export.ordinal, "RVA:", export.rva, forwarder)
    end

    style.formatFooter(#exportArray, forceLog)
end

function publicApi.PrintImport(fileNameOrPath, forceLog)

    if not GameModule.IsLoaded(fileNameOrPath) then
        logger.custom(1, false, " Module not found in databank. ")

        return
    end

    local importArray = GameModule.GetImport(fileNameOrPath)

    if #importArray == 0 then
        logger.info()

        return
    end

    style.formatHeader("IMPORTS", forceLog)
    style.formatEntry(forceLog, "TARGET MODULE:", fileNameOrPath)

    for i, import in ipairs(importArray) do
        style.formatEntry(forceLog, "+", "Module", tostring(i) .. ":", import.fileName)
        for j, entry in ipairs(import.entries) do
            style.formatEntry(forceLog, "|- Entry", tostring(j) .. ":", entry)
        end
    end

    style.formatFooter(#importArray, forceLog)
end

function publicApi.PrintIsLoaded(fileNameOrPath, forceLog)
    logger.custom(0, forceLog, GameModule.IsLoaded(fileNameOrPath))
end

function publicApi.PrintLoadedModules(forceLog)
    local modulesArray = GameModule.GetLoadedModules()

    if #modulesArray == 0 then
        logger.info()

        return
    end

    style.formatHeader("LOADED MODULES", forceLog)

    for _, module in ipairs(modulesArray) do
        logger.custom(0, forceLog, utils.getFileName(module))
    end

    style.formatFooter(#modulesArray, forceLog)
end

function publicApi.PrintTimeDateStamp(fileNameOrPath, forceLog)
    logger.custom(0, forceLog, GameModule.GetTimeDateStamp(fileNameOrPath))
end

function publicApi.PrintVersion(fileNameOrPath, forceLog)
    logger.custom(0, forceLog, GameModule.GetVersion(fileNameOrPath))
end

function publicApi.onInit()
    Observe('Cyberlibs', 'Version', function()
        GetMod('Cyberlibs').Version()
    end)

    Observe('Cyberlibs', 'SetPrintingStyle', function(isEnabled)
        GetMod('Cyberlibs').SetPrintingStyle(isEnabled)
    end)

    Observe('Cyberlibs', 'Help', function(number, forceLog)
        GetMod('Cyberlibs').Help(number, forceLog)
    end)

    Override('Cyberlibs', 'GetVersion', function(fileNameOrPath)
        return GetMod('Cyberlibs').GetVersion(fileNameOrPath)
    end)

    Observe('Cyberlibs', 'PrintAttribute', function(fileNameOrPath, attribute, forceLog)
        GetMod('Cyberlibs').PrintAttribute(fileNameOrPath, attribute, forceLog)
    end)

    Observe('Cyberlibs', 'PrintExport', function(fileNameOrPath, forceLog)
        GetMod('Cyberlibs').PrintExport(fileNameOrPath, forceLog)
    end)

    Observe('Cyberlibs', 'PrintImport', function(fileNameOrPath, forceLog)
        GetMod('Cyberlibs').PrintImport(fileNameOrPath, forceLog)
    end)

    Observe('Cyberlibs', 'PrintIsLoaded', function(fileNameOrPath, forceLog)
        GetMod('Cyberlibs').PrintIsLoaded(fileNameOrPath, forceLog)
    end)

    Observe('Cyberlibs', 'PrintLoadedModules', function(forceLog)
        GetMod('Cyberlibs').PrintLoadedModules(forceLog)
    end)

    Observe('Cyberlibs', 'PrintVersion', function(fileNameOrPath, forceLog)
        GetMod('Cyberlibs').PrintVersion(fileNameOrPath, forceLog)
    end)

    Observe('Cyberlibs', 'PrintTimeDateStamp', function(fileNameOrPath, forceLog)
        GetMod('Cyberlibs').PrintTimeDateStamp(fileNameOrPath, forceLog)
    end)
end

return publicApi