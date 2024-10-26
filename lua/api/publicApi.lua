local publicApi = {
    __VERSION = { 0, 2, 0 },
}

local logger = require("globals/logger")
local search = require("globals/search")
local style = require("globals/custom/style")
local utils = require("globals/utils")

function publicApi.Version()
    local versionAddendum = Cyberlibs.__VERSION_STATUS and ("-" .. Cyberlibs.__VERSION_STATUS)

    if versionAddendum then
        versionAddendum = (Cyberlibs.__VERSION_SUFFIX and Cyberlibs.__VERSION_SUFFIX .. versionAddendum) or versionAddendum
    else
        versionAddendum = Cyberlibs.__VERSION_SUFFIX
    end

    if versionAddendum then
        return table.concat(Cyberlibs.__VERSION, ".") .. versionAddendum
    else
        return table.concat(Cyberlibs.__VERSION, ".")
    end
end

function publicApi.SetPrintingStyle(isEnabled)
    style.setEnabled(isEnabled, 'print')
    logger.info("Printing in style:", isEnabled)
end

local function printHelpTopics(t, forceLog)
    for i, v in ipairs(t) do
        logger.custom(false, forceLog, 0, style.formatEntry(i .. " " .. v))
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

        logger.custom(false, forceLog, 0, style.formatHeader("HELP FILES"))
    else
        logger.custom(false, forceLog, 0, style.formatFailHeader("HELP FILES"))
        logger.custom(false, forceLog, 1, ' Type Cyberlibs.Help() to start ')
    
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
                    logger.custom(false, forceLog, 0, style.formatEntry(line))
                end
            else
                itemsNumber = 1

                logger.custom(false, forceLog, 0, style.formatEntry(v))
            end
        end
    else
        printHelpTopics(contents, false, forceLog)
    end

    logger.custom(false, forceLog, 0, style.formatFooter(itemsNumber))
    logger.custom(false, forceLog, 0, "")

    if not isTopic then
        logger.custom(false, forceLog, 1, " File not found in databank. ")
        logger.custom(false, forceLog, 1, ' Type Cyberlibs.Help() to return ')
    end

    logger.custom(false, forceLog, 1, ' Type Cyberlibs.Help(number) to open file ')
end

function publicApi.GetVersion(fileNameOrPath)
    local versions = require("knowledgeBase/versions")
    search.setBrowseInstance('getVersion', versions.getTable())
    local fileName = utils.getFileName(fileNameOrPath)
    local isData = search.followBrowseItem('getVersion', fileName)
    local version

    if isData then
        version = search.getBrowseTable('getVersion')[GameModules.GetTimeDateStamp(fileNameOrPath)]
    end

    if not version then
        version = GameModules.GetVersion(fileNameOrPath)
    end

    return version
end

function publicApi.PrintAttribute(fileNameOrPath, attribute, forceLog)
    local attributes = {
        ["CompanyName"] = function() return GameModules.GetCompanyName(fileNameOrPath) end,
        ["Description"] = function() return GameModules.GetDescription(fileNameOrPath) end,
        ["EntryPoint"] = function() return GameModules.GetEntryPoint(fileNameOrPath) end,
        ["FilePath"] = function() return GameModules.GetFilePath(fileNameOrPath) end,
        ["FileSize"] = function() return GameModules.GetFileSize(fileNameOrPath) end,
        ["FileType"] = function() return GameModules.GetFileType(fileNameOrPath) end,
        ["LoadAddress"] = function() return GameModules.GetLoadAddress(fileNameOrPath) end,
        ["MappedSize"] = function() return GameModules.GetMappedSize(fileNameOrPath) end,
        ["TimeDateStamp"] = function() return GameModules.GetTimeDateStamp(fileNameOrPath) end,
        ["Version"] = function() return GameModules.GetVersion(fileNameOrPath) end,
    }

    local arrays = {
        ["Export"] = function() return publicApi.PrintExport(fileNameOrPath, forceLog) end,
        ["Import"] = function() return publicApi.PrintImport(fileNameOrPath, forceLog) end,
    }

    if attributes[attribute] ~= nil then
        logger.custom(false, forceLog, 0, attributes[attribute]())
    elseif arrays[attribute] ~= nil then
        arrays[attribute]()
    else
        logger.custom(false, false, 1, " Attribute not found in databank. ")
    end
end

function publicApi.PrintExport(fileNameOrPath, forceLog)

    if not GameModules.IsLoaded(fileNameOrPath) then
        logger.custom(false, false, 1, " Module not found in databank. ")

        return
    end

    local exportArray = GameModules.GetExport(fileNameOrPath)

    if #exportArray == 0 then
        logger.info()

        return
    end

    logger.custom(false, forceLog, 0, style.formatHeader("EXPORTS"))
    logger.custom(false, forceLog, 0, style.formatEntry("TARGET MODULE:"))

    local forwarder

    for i, export in ipairs(exportArray) do
        forwarder = nil

        if export.forwarderName ~= "" then
            forwarder = "Forwarder: " .. export.forwarderName
        end

        logger.custom(false, forceLog, 0, style.formatEntry("Entry" .. tostring(i) .. ": " .. export.entry ..
                        "Ordinal: " .. export.ordinal .. "RVA: " .. export.rva .. forwarder))
    end

    logger.custom(false, forceLog, 0, style.formatFooter(#exportArray))
end

function publicApi.PrintImport(fileNameOrPath, forceLog)

    if not GameModules.IsLoaded(fileNameOrPath) then
        logger.custom(false, false, 1, " Module not found in databank. ")

        return
    end

    local importArray = GameModules.GetImport(fileNameOrPath)

    if #importArray == 0 then
        logger.info()

        return
    end

    logger.custom(false, forceLog, 0, style.formatHeader("IMPORTS"))
    logger.custom(false, forceLog, 0, style.formatEntry("TARGET MODULE:" .. fileNameOrPath))

    for i, import in ipairs(importArray) do
        logger.custom(false, forceLog, 0, style.formatEntry("+ Module" .. tostring(i) .. ": " .. import.fileName))
        for j, entry in ipairs(import.entries) do
            logger.custom(false, forceLog, 0, style.formatEntry("|- Entry " .. tostring(j) .. ": " .. entry))
        end
    end

    logger.custom(false, forceLog, 0, style.formatFooter(#importArray))
end

function publicApi.PrintIsLoaded(fileNameOrPath, forceLog)
    logger.custom(false, forceLog, 0, GameModules.IsLoaded(fileNameOrPath))
end

function publicApi.PrintLoadedModules(forceLog)
    local modulesArray = GameModules.GetLoadedModules()

    if #modulesArray == 0 then
        logger.info()

        return
    end

    logger.custom(false, forceLog, 0, style.formatHeader("LOADED MODULES"))

    for _, module in ipairs(modulesArray) do
        logger.custom(false, forceLog, 0, utils.getFileName(module))
    end

    logger.custom(false, forceLog, 0, style.formatFooter(#modulesArray))
end

function publicApi.PrintTimeDateStamp(fileNameOrPath, forceLog)
    logger.custom(false, forceLog, 0, GameModules.GetTimeDateStamp(fileNameOrPath))
end

function publicApi.PrintVersion(fileNameOrPath, forceLog)
    logger.custom(false, forceLog, 0, GameModules.GetVersion(fileNameOrPath))
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