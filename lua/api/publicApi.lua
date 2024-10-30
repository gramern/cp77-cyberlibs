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

local function canBeParsed(fileNameOrPath)
    if type(GameModules) == "nil" then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return false
    end

    if fileNameOrPath then
        local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)

        if not GameModules.IsLoaded(normalizedNameOrPath) and not utils.isValidPath(normalizedNameOrPath) then
            logger.warning("Module not found.")

            return false
        end
    end

    return true
end

function publicApi.GetVersion(fileNameOrPath)
    if not canBeParsed(fileNameOrPath) then return end

    local versions = require("knowledgeBase/versions")
    search.setBrowseInstance('getVersion', versions.getTable())
    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)
    local fileName = utils.getFileName(fileNameOrPath)
    local isData = search.followBrowseItem('getVersion', fileName)
    local version

    if isData then
        version = search.getBrowseTable('getVersion')[GameModules.GetTimeDateStamp(normalizedNameOrPath)]
    end

    if not version then
        version = GameModules.GetVersion(normalizedNameOrPath)
    end

    return version
end

local function parseAttribute(fileNameOrPath, attribute)
    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)

    local attributes = {
        ["CompanyName"] = function() return GameModules.GetCompanyName(normalizedNameOrPath) end,
        ["Description"] = function() return GameModules.GetDescription(normalizedNameOrPath) end,
        ["EntryPoint"] = function() return GameModules.GetEntryPoint(normalizedNameOrPath) end,
        ["FilePath"] = function() return GameModules.GetFilePath(normalizedNameOrPath) end,
        ["FileSize"] = function() return GameModules.GetFileSize(normalizedNameOrPath) end,
        ["FileType"] = function() return GameModules.GetFileType(normalizedNameOrPath) end,
        ["LoadAddress"] = function() return GameModules.GetLoadAddress(normalizedNameOrPath) end,
        ["MappedSize"] = function() return GameModules.GetMappedSize(normalizedNameOrPath) end,
        ["TimeDateStamp"] = function() return GameModules.GetTimeDateStamp(normalizedNameOrPath) end,
        ["Version"] = function() return GameModules.GetVersion(normalizedNameOrPath) end,
    }

    if not attributes[attribute] then return end
    
    return attributes[attribute]()
end

--- Available attributes: `CompanyName`, `Description`, `EntryPoint`, `Export`,
--- `FilePath`, `FileSize`, `FileType`, `Import`, `LoadAddress`, `MappedSize`, 
--- `TimeDateStamp`, `Version`
---@param fileNameOrPath string
---@param attribute string
---@param dump boolean?
function publicApi.PrintAttribute(fileNameOrPath, attribute, dump)
    if not canBeParsed(fileNameOrPath) then return end

    local result = parseAttribute(fileNameOrPath, attribute)

    if result then
        if not dump then
            logger.custom(false, false, 0, result)
        else
            local fileName = utils.getFileName(fileNameOrPath)

            GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-" .. attribute .. ".txt", result)
            logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
        end

        return
    end

    local arrays = {
        ["Export"] = function() return publicApi.PrintExport(fileNameOrPath, dump) end,
        ["Import"] = function() return publicApi.PrintImport(fileNameOrPath, dump) end,
    }

    if arrays[attribute] ~= nil then
        arrays[attribute]()
    else
        logger.waring("Attribute not found.")
    end
end

local function parseExport(fileNameOrPath)
    if not canBeParsed(fileNameOrPath) then return end

    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)
    local exportArray = GameModules.GetExport(normalizedNameOrPath)

    if #exportArray == 0 then
        logger.info("Export: Nothing to print.")

        return ""
    end

    local fileName = utils.getFileName(fileNameOrPath)
    local result = style.formatHeader(fileName .. "EXPORT")

    local forwarder

    for i, export in ipairs(exportArray) do
        forwarder = ""

        if export.forwarderName ~= "" then
            forwarder = "Forwarder: " .. export.forwarderName
        end

        result = result .. "\n" .. style.formatEntry("Entry" .. tostring(i) .. ": " .. export.entry ..
                                                ", Ordinal: " .. export.ordinal .. ", RVA: " .. export.rva .. forwarder)
    end

    return result .. "\n" .. style.formatFooter(#exportArray)
end

function publicApi.PrintExport(fileNameOrPath, dump)
    local result = parseExport(fileNameOrPath)

    if result == "" then return end

    if not dump then
        logger.custom(false, false, 0, result)
    else
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-Export.txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
    end
end

local function parseImport(fileNameOrPath)
    if not canBeParsed(fileNameOrPath) then return end

    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)
    local importArray = GameModules.GetImport(normalizedNameOrPath)

    if #importArray == 0 then
        logger.info("Import: Nothing to print.")

        return ""
    end

    local fileName = utils.getFileName(fileNameOrPath)
    local result = style.formatHeader(fileName .. "IMPORT")

    for i, import in ipairs(importArray) do
        result = result .. "\n" .. style.formatEntry("+ Module" .. tostring(i) .. ": " .. import.fileName)
        for j, entry in ipairs(import.entries) do
            result = result .. "\n" .. style.formatEntry("|- Entry " .. tostring(j) .. ": " .. entry)
        end
    end

    return result .. "\n" .. style.formatFooter(#importArray)
end

function publicApi.PrintImport(fileNameOrPath, dump)
    local result = parseImport(fileNameOrPath)

    if result == "" then return end

    if not dump then
        logger.custom(false, false, 0, result)
    else
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-Import.txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
    end
end

local function parseIsLoaded(fileNameOrPath)
    if not canBeParsed(fileNameOrPath) then return end

    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)

    return GameModules.IsLoaded(normalizedNameOrPath)
end

function publicApi.PrintIsLoaded(fileNameOrPath, dump)
    local result = parseIsLoaded(fileNameOrPath)

    if not result then return end

    if not dump then
        logger.custom(false, false, 0, result)
    else
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-IsLoaded-" .. GameDiagnostics.GetCurrentTimeDate(true) .. ".txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
    end
end

local function parseLoadedModules()
    if not canBeParsed() then return end

    local modulesArray = GameModules.GetLoadedModules()

    if #modulesArray == 0 then
        logger.info("Loaded Modules: Nothing to print.")

        return ""
    end

    local result = style.formatHeader("LOADED MODULES")

    for _, module in ipairs(modulesArray) do
        result = result .. "\n" .. style.formatEntry(module)
    end

    return result .. "\n" .. style.formatFooter(#modulesArray)
end

function publicApi.PrintLoadedModules(dump)
    local result = parseLoadedModules()

    if not result then return end

    if not dump then
        logger.custom(false, false, 0, result)
    else
        GameDiagnostics.WriteToOutput("_PARSED_DATA/LoadedModules-" .. GameDiagnostics.GetCurrentTimeDate(true) .. ".txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA")
    end
end

local function parseVersion(fileNameOrPath)
    if not canBeParsed(fileNameOrPath) then return end

    local normalizedNameOrPath = utils.normalizePath(fileNameOrPath)

    return GameModules.GetVersion(normalizedNameOrPath)
end

function publicApi.PrintVersion(fileNameOrPath, dump)
    local result = parseVersion(fileNameOrPath)

    if not result then return end

    if not dump then
        logger.custom(false, dump, 0, result)
    else
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-Version.txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
    end
end

function publicApi.PrintModuleInfo(fileNameOrPath, dump)
    if not canBeParsed(fileNameOrPath) then return end

    local result = utils.getFileName(fileNameOrPath)
    result = result .. "\n" .. parseAttribute(fileNameOrPath, "FilePath")
    result = result .. "\nVersion: " .. parseVersion(fileNameOrPath)
    result = result .. "\nTimeDateStamp: " .. parseAttribute(fileNameOrPath, "TimeDateStamp")
    result = result .. "\nDescription: " .. parseAttribute(fileNameOrPath, "Description")
    result = result .. "\nCompany Name: " .. parseAttribute(fileNameOrPath, "CompanyName")
    result = result .. "\nFile Type: " .. parseAttribute(fileNameOrPath, "FileType")
    result = result .. "\nFile Size: " .. parseAttribute(fileNameOrPath, "FileSize")
    result = result .. "\nMapped Size: " .. parseAttribute(fileNameOrPath, "MappedSize")
    result = result .. "\nEntry Point: " .. parseAttribute(fileNameOrPath, "EntryPoint")
    result = result .. "\nLoad Address: " .. parseAttribute(fileNameOrPath, "LoadAddress")

    if parseIsLoaded(fileNameOrPath) then
        result = result .. "\n\nLoaded by the game during parsing process on " .. GameDiagnostics.GetCurrentTimeDate()
    end

    result = result .. "\n\n" .. parseExport(fileNameOrPath)
    result = result .. "\n\n" .. parseImport(fileNameOrPath)

    if not result then return end

    if not dump then
        logger.custom(false, dump, 0, result)
    else
        local fileName = utils.getFileName(fileNameOrPath)

        GameDiagnostics.WriteToOutput("_PARSED_DATA/" .. fileName .. "/" .. fileName .. "-ModuleInfo.txt", result)
        logger.info("Requested data dumped to ..\\_PARSED_DATA\\" .. fileName)
    end
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

    Observe('Cyberlibs', 'PrintModuleInfo', function(fileNameOrPath, dump)
        GetMod('Cyberlibs').PrintModuleInfo(fileNameOrPath, dump)
    end)
end

return publicApi