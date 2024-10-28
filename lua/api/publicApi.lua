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

local function printHelpTopics(t)
    for i, v in ipairs(t) do
        logger.custom(false, false, 0, style.formatEntry(i .. " " .. v))
    end
end

function publicApi.Help(query)
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

        logger.custom(false, false, 0, style.formatHeader("HELP FILES"))
    else
        logger.custom(false, false, 0, style.formatFailHeader("HELP FILES"))
        logger.custom(false, false, 1, ' Type Cyberlibs.Help() to start ')
    
        return
    end

    if isTopic then
        contents, itemsNumber = search.getBrowseContents('help')

        if itemType == "table" then
            printHelpTopics(contents)
        else
            local v = search.getBrowseItem('help', query)

            if type(v) == "string" then
                local text = utils.indentString(v, -20, true)
                local lines = utils.parseMultiline(text)
                itemsNumber = #lines

                for _, line in ipairs(lines) do
                    logger.custom(false, false, 0, style.formatEntry(line))
                end
            else
                itemsNumber = 1

                logger.custom(false, false, 0, style.formatEntry(v))
            end
        end
    else
        printHelpTopics(contents)
    end

    logger.custom(false, false, 0, style.formatFooter(itemsNumber))
    logger.custom(false, false, 0, "")

    if not isTopic then
        logger.custom(false, false, 1, " File not found in databank. ")
        logger.custom(false, false, 1, ' Type Cyberlibs.Help() to return ')
    end

    logger.custom(false, false, 1, ' Type Cyberlibs.Help(number) to open file ')
end

function publicApi.GetVersion(fileNameOrPath)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

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

--- Available attributes: `CompanyName`, `Description`, `EntryPoint`, `Export`,
--- `FilePath`, `FileSize`, `FileType`, `Import`, `LoadAddress`, `MappedSize`, 
--- `TimeDateStamp`, `Version`
---@param fileNameOrPath string
---@param attribute string
---@param dump boolean?
function publicApi.PrintAttribute(fileNameOrPath, attribute, dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local result

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
        ["Export"] = function() return publicApi.PrintExport(fileNameOrPath, dump) end,
        ["Import"] = function() return publicApi.PrintImport(fileNameOrPath, dump) end,
    }

    if attributes[attribute] ~= nil then
        result = attributes[attribute]()

        logger.custom(false, false, 0, result)

        if not dump then return end
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "-" .. attribute .. ".txt", result)
    elseif arrays[attribute] ~= nil then
        arrays[attribute]()
    else
        logger.custom(false, false, 1, " Attribute not found in databank. ")
    end
end

function publicApi.PrintExport(fileNameOrPath, dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local result

    if not GameModules.IsLoaded(fileNameOrPath) then
        logger.custom(false, false, 1, " Module not found in databank. ")

        return
    end

    local exportArray = GameModules.GetExport(fileNameOrPath)

    if #exportArray == 0 then
        logger.info()

        return
    end

    result = style.formatHeader("EXPORTS")
    result = result .. "\n" .. style.formatEntry("TARGET MODULE: " .. fileNameOrPath)

    local forwarder

    for i, export in ipairs(exportArray) do
        forwarder = ""

        if export.forwarderName ~= "" then
            forwarder = "Forwarder: " .. export.forwarderName
        end

        result = result .. "\n" .. style.formatEntry("Entry" .. tostring(i) .. ": " .. export.entry ..
                                                "Ordinal: " .. export.ordinal .. "RVA: " .. export.rva .. forwarder)
    end

    result = result .. "\n" .. style.formatFooter(#exportArray)

    logger.custom(false, false, 0, result)

    if not dump then return end
    local fileName = utils.getFileName(fileNameOrPath)

    GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "-Export.txt", result)
end

function publicApi.PrintImport(fileNameOrPath, dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local result

    if not GameModules.IsLoaded(fileNameOrPath) then
        logger.custom(false, false, 1, " Module not found in databank. ")

        return
    end

    local importArray = GameModules.GetImport(fileNameOrPath)

    if #importArray == 0 then
        logger.info()

        return
    end

    result = style.formatHeader("IMPORTS")
    result = result .. "\n" .. style.formatEntry("TARGET MODULE:" .. fileNameOrPath)

    for i, import in ipairs(importArray) do
        result = result .. "\n" .. style.formatEntry("+ Module" .. tostring(i) .. ": " .. import.fileName)
        for j, entry in ipairs(import.entries) do
            result = result .. "\n" .. style.formatEntry("|- Entry " .. tostring(j) .. ": " .. entry)
        end
    end

    result = result .. "\n" .. style.formatFooter(#importArray)

    logger.custom(false, false, 0, result)

    if not dump then return end
    local fileName = utils.getFileName(fileNameOrPath)

    GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "-Import.txt", result)
end

function publicApi.PrintIsLoaded(fileNameOrPath, dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local result = GameModules.IsLoaded(fileNameOrPath)

    logger.custom(false, false, 0, result)

    if not dump then return end
    local fileName = utils.getFileName(fileNameOrPath)

    GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "-IsLoaded-" .. GameDiagnostics.GetTimeDateStamp(true) .. ".txt", result)
end

function publicApi.PrintLoadedModules(dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local modulesArray = GameModules.GetLoadedModules()

    if #modulesArray == 0 then
        logger.info()

        return
    end

    local result = style.formatHeader("LOADED MODULES")

    for _, module in ipairs(modulesArray) do
        result = result .. "\n" .. style.formatEntry(module)
    end

    result = result .. "\n" .. style.formatFooter(#modulesArray)

    logger.custom(false, false, 0, result)

    if not dump then return end

    GameDiagnostics.WriteToOutput("_PARSED_DATA/LoadedModules-" .. GameDiagnostics.GetTimeDateStamp(true) .. ".txt", result)
end

function publicApi.PrintVersion(fileNameOrPath, dump)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return
    end

    local result = GameModules.GetVersion(fileNameOrPath)

    logger.custom(false, dump, 0, result)

    if not dump then return end
    local fileName = utils.getFileName(fileNameOrPath)

    GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "-Version.txt", result)
end

function publicApi.onInit()
    Observe('Cyberlibs', 'Version', function()
        GetMod('Cyberlibs').Version()
    end)

    Observe('Cyberlibs', 'SetPrintingStyle', function(isEnabled)
        GetMod('Cyberlibs').SetPrintingStyle(isEnabled)
    end)

    Observe('Cyberlibs', 'Help', function(number)
        GetMod('Cyberlibs').Help(number)
    end)

    Override('Cyberlibs', 'GetVersion', function(fileNameOrPath)
        return GetMod('Cyberlibs').GetVersion(fileNameOrPath)
    end)

    Observe('Cyberlibs', 'PrintAttribute', function(fileNameOrPath, attribute, dump)
        GetMod('Cyberlibs').PrintAttribute(fileNameOrPath, attribute, dump)
    end)

    Observe('Cyberlibs', 'PrintExport', function(fileNameOrPath, dump)
        GetMod('Cyberlibs').PrintExport(fileNameOrPath, dump)
    end)

    Observe('Cyberlibs', 'PrintImport', function(fileNameOrPath, dump)
        GetMod('Cyberlibs').PrintImport(fileNameOrPath, dump)
    end)

    Observe('Cyberlibs', 'PrintIsLoaded', function(fileNameOrPath, dump)
        GetMod('Cyberlibs').PrintIsLoaded(fileNameOrPath, dump)
    end)

    Observe('Cyberlibs', 'PrintLoadedModules', function(dump)
        GetMod('Cyberlibs').PrintLoadedModules(dump)
    end)

    Observe('Cyberlibs', 'PrintVersion', function(fileNameOrPath, dump)
        GetMod('Cyberlibs').PrintVersion(fileNameOrPath, dump)
    end)
end

return publicApi