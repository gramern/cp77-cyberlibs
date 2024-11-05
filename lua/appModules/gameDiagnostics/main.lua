local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local style = require("globals/custom/style")
local settings = require("globals/settings")
local tables = require("globals/tables")
local utils = require("globals/utils")

local sortedModsResources  = {
    filtered = {},
    parsed = {}
}

local mods = {}

local output = {}

local function getModsResourceName(filePath)
    local modsResources = require("knowledgeBase/modsResources")
    local modsResourcesTable = modsResources.getTable()

    filePath = utils.normalizePath(filePath)

    for name, relativePath in pairs(modsResourcesTable) do
        if string.find(filePath, "%" .. relativePath:lower() .. "$") then
            return name
        end
    end

    return nil
end

local function ensureIsVersion(filePath, version)
    filePath = utils.normalizePath(filePath)

    if version == "Rate limit exceed" then
        version = Cyberlibs.GetVersion(filePath)
    end

    return version
end

local function scanArchiveMods()
    if not mods.archive then
        mods.archive = {
            enabled = {}
        }
    end

    local archivePath = "archive/pc/mod"
    local archiveDir = GameDiagnostics.ListDirectory(archivePath)
    local archives = {}

    for _, item in ipairs(archiveDir) do
        if item.type == "file" then
            local baseName = item.name
            local isXl = string.find(item.name, "%.archive%.xl$")

            if isXl then
                baseName = string.gsub(item.name, "%.xl$", "")
            end

            if string.find(baseName, "%.archive$") then
                if not archives[baseName] then
                    archives[baseName] = {}
                end

                item.normalizedPath = utils.normalizePath(archivePath .. "/" .. item.name)
                item.tags = {}

                if isXl then
                    archives[baseName].xl = item
                else
                    local kbName = getModsResourceName(item.normalizedPath)

                    if kbName then
                        table.insert(item.tags, "mods resource")
                        item.kbName = kbName
                    end

                    archives[baseName].regular = item
                end
            end
        end
    end

    for baseName, files in pairs(archives) do
        if files.regular and files.xl then
            table.insert(files.regular.tags, "archive")
            table.insert(files.regular.tags, "archiveXl")
            table.insert(mods.archive.enabled, files.regular)
        elseif files.regular then
            table.insert(files.regular.tags, "archive")
            table.insert(mods.archive.enabled, files.regular)
        elseif files.xl then
            table.insert(files.xl.tags, "archiveXl")
            table.insert(mods.archive.enabled, files.xl)
        end
    end
end

local function scanCetMods()
    if not mods.cet then
        mods.cet = {
            enabled = {},
            disabled = {}
        }
    end

    local cetPath = "bin/x64/plugins/cyber_engine_tweaks/mods"
    local cetDir = GameDiagnostics.ListDirectory(cetPath)

    for _, item in ipairs(cetDir) do
        if item.type == "dir" then
            item.tags = { "cet" }
            item.normalizedPath = utils.normalizePath(cetPath .. "/" .. item.name)
            local initPath = item.normalizedPath .. "/init.lua"
            local kbName = getModsResourceName(initPath)

            if kbName then
                table.insert(item.tags, "mods resource")
                item.kbName = kbName
            end

            if GameDiagnostics.IsFile(initPath) then
                table.insert(mods.cet.enabled, item)
            else
                table.insert(mods.cet.disabled, item)
            end
        end
    end
end

local function scanRed4extMods()
    if not app.isAppModule("gameModules") then
        logger.warning("Install \"Game Modules\" AppModule.")

        return
    end

    if not mods.red4ext then
        mods.red4ext = {
            enabled = {},
            disabled = {}
        }
    end

    local taggedModules = app.getTaggedModules()
    local red4extModulesSet = {}
    mods.other = {}

    for _, module in ipairs(taggedModules) do
        for _, tag in ipairs(module.tags) do
            if tag == "red4ext" then
                local dirName =  utils.getPathSecondLastComponent(module.normalizedPath)
                module.version = Cyberlibs.GetVersion(module.normalizedPath)

                if string.sub(dirName, 1, 3) == string.lower(string.sub(module.fileName, 1, 3)) then
                    red4extModulesSet[dirName] = module
                else
                    red4extModulesSet[module.normalizedPath] = module
                end

                break
            elseif tag == "unknown" then
                module.version = Cyberlibs.GetVersion(module.normalizedPath)

                table.insert(mods.other, module)
                
                break
            end
        end
    end

    local red4extPath = "red4ext/plugins"
    local red4extDir = GameDiagnostics.ListDirectory(red4extPath)

    for _, item in ipairs(red4extDir) do
        local normalizedName = string.lower(item.name)

        if item.type == "dir" and red4extModulesSet[normalizedName] then
            local kbName = getModsResourceName(red4extModulesSet[normalizedName].normalizedPath)

            if kbName then
                red4extModulesSet[normalizedName].kbName = kbName
            end

            table.insert(mods.red4ext.enabled, red4extModulesSet[normalizedName])

            red4extModulesSet[normalizedName] = nil
        end
    end

    for _, item in ipairs(red4extDir) do
        local normalizedName = string.lower(item.name)

        if item.type == "dir" then
            item.normalizedPath = red4extPath .. "/".. normalizedName

            for k, module in pairs(red4extModulesSet) do

                if string.find(k, item.normalizedPath) then
                    table.insert(mods.red4ext.enabled, module)

                    red4extModulesSet[k] = nil

                    break
                end
            end
        end
    end

    for _, item in ipairs(red4extDir) do
        local normalizedName = string.lower(item.name)

        if item.type == "dir" then
            item.tags = { "red4ext" }
            item.normalizedPath = red4extPath .. "/".. normalizedName

            table.insert(mods.red4ext.disabled, item)
        end
    end
end

local function scanRedscriptMods()
    if not mods.redscript then
        mods.redscript = {
            enabled = {},
            disabled = {}
        }
    end

    local redscriptPath = "r6/scripts"
    local redscriptDir = GameDiagnostics.ListDirectory(redscriptPath)

    for _, item in ipairs(redscriptDir) do
        if item.type == "dir" then
            item.tags = { "redscript" }
            item.normalizedPath = utils.normalizePath(redscriptPath .. "/" .. item.name)
            local modDir = GameDiagnostics.ListDirectory(item.normalizedPath)

            if next(modDir) then
                local scriptPaths = {}

                for _, subItem in ipairs(modDir) do
                    if string.find(subItem.name, "%.reds$") then
                        table.insert(scriptPaths, item.normalizedPath .. "/" .. subItem.name)
                    end
                end

                if next(scriptPaths) then
                    for _, scriptPath in ipairs(scriptPaths) do
                        local kbName = getModsResourceName(scriptPath)

                        if kbName then
                            table.insert(item.tags, "mods resource")
                            item.kbName = kbName

                            break
                        end
                    end

                    table.insert(mods.redscript.enabled, item)
                else
                    table.insert(mods.redscript.disabled, item)
                end
            else
                table.insert(mods.redscript.disabled, item)
            end
        elseif item.type == "file" and string.find(item.name, "%.reds$") then
            item.tags = { "redscript" }
            item.normalizedPath = utils.normalizePath(redscriptPath .. "/" .. item.name)
            local kbName = getModsResourceName(item.normalizedPath)

            if kbName then
                table.insert(item.tags, "mods resource")
                item.kbName = kbName
            end

            table.insert(mods.redscript.enabled, item)
        end
    end
end

local function scanTweaks()
    if not mods.tweaks then
        mods.tweaks = {
            enabled = {},
            disabled = {}
        }
    end

    local tweaksPath = "r6/tweaks"
    local tweaksDir = GameDiagnostics.ListDirectory(tweaksPath)

    for _, item in ipairs(tweaksDir) do
        if item.type == "dir" then
            item.tags = { "tweaks" }
            item.normalizedPath = utils.normalizePath(tweaksPath .. "/" .. item.name)
            local modDir = GameDiagnostics.ListDirectory(item.normalizedPath)

            if next(modDir) then
                for _, tweak in ipairs(modDir) do
                    if string.find(tweak.name, "%.yaml$") then
                        table.insert(mods.tweaks.enabled, item)

                        break
                    end
                end

                table.insert(mods.tweaks.disabled, item)
            else
                table.insert(mods.tweaks.disabled, item)
            end
        elseif item.type == "file" and string.find(item.name, "%.yaml$") then
            item.tags = { "tweaks" }
            item.normalizedPath = utils.normalizePath(tweaksPath .. "/" .. item.name)

            table.insert(mods.tweaks.enabled, item)
        end
    end

    table.sort(mods.tweaks.enabled, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    table.sort(mods.tweaks.disabled, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
end

local function setModsResourceStatus(state, mod, result)
    for _, tag in ipairs(mod.tags) do
        if tag == "mods resource" and tostring(state) == "enabled" then
            if mod.version then
                mod.version = ensureIsVersion(mod.filePath, mod.version)
            end

            if mod.version == "Unknown" or not mod.version then
                result[mod.kbName] = "Installed, version unknown"
            else
                result[mod.kbName] = mod.version
            end
        end
    end
end

local function getModsResourcesStatus()
    local modsResources = require("knowledgeBase/modsResources")
    local modsResourcesTable = modsResources.getTable()
    local coreFrameworks = {
        "Cyber Engine Tweaks",
        "cybercmd",
        "RED4ext",
        "RED4ext Loader",
        "Redscript",
        "Ultimate ASI Loader",
    }
    local result = {}

    for name, relativePath in pairs(modsResourcesTable) do
        result[name] = "NOT INSTALLED"

        for _, framework in ipairs (coreFrameworks) do
            if framework == name 
            then
                local isLoaded = GameModules.IsLoaded(utils.getPathLastComponent(relativePath))
                local version = Cyberlibs.GetVersion(utils.getPathLastComponent(relativePath))

                if isLoaded and version == "Unknown" then
                    result[name] = "Installed, version unknown"
                elseif isLoaded and version then
                    result[name] = version
                end
            end
        end
    end

    for _, states in pairs(mods) do
        for state, items in pairs(states) do
            for _, mod in ipairs(items) do
                setModsResourceStatus(state, mod, result)
            end
        end
    end

    return result
end

local function sortModsResources(t)
    local contents = tables.assignKeysOrder(t)

    table.sort(contents, function(a, b)
        return a:lower() < b:lower()
    end)

    for _, name in ipairs(contents) do
        table.insert(sortedModsResources.parsed, { name = name, version = t[name] })
    end
end

local function scanMods()
    ImGuiExt.SetNotification(0, "Scanning mods, please wait...")

    if not next(mods) then
        scanArchiveMods()
        scanCetMods()
        scanRed4extMods()
        scanRedscriptMods()
        scanTweaks()
    end

    if not next(sortedModsResources.parsed) then
        sortModsResources(getModsResourcesStatus())
    end

    ImGuiExt.SetNotification(2, "Mods scanning complete.")
end

local function initalizeModsReportSettings()
    output.mods = {
        inculdeCurrentLogs = true,
    }
end

local function isModsReport(fileName)
    if not fileName then return end

    if GameDiagnostics.IsFile("_DIAGNOSTICS/_REPORTS/" .. fileName) then
        output.mods.isReport = true
        output.mods.reportName = fileName
        output.mods.current = GameDiagnostics.GetGamePath() .. "\\_DIAGNOSTICS\\_REPORTS"

        return true
    else
        output.mods.isReport = false
        output.mods.reportName = nil
    end
end

local function getModsReport()
    local reportsDir = "_REPORTS"
    local fileName = "Mods-" .. GameDiagnostics.GetCurrentTimeDate(true) .. ".txt"
    local filePath = reportsDir .. "/" .. fileName

    local text = "Mods Report\nGenerated in Cyberlibs on " .. GameDiagnostics.GetCurrentTimeDate()
    text = text .. "\nGame version: " .. GameModules.GetVersion("Cyberpunk2077.exe")
    text = text .. "\n\n\n" .. style.formatHeader("Mods Resources")

    local modsResourceAmount = 0

    for _, module in ipairs(sortedModsResources.parsed) do
        text = text .. "\n" .. style.formatEntry(module.name ..
                                                    utils.setStringCursor(module.name, 40, " ") ..
                                                    "Version: " ..
                                                    module.version)

        if module.version ~= "NOT INSTALLED" then
            modsResourceAmount = modsResourceAmount + 1
        end
    end

    text = text ..  "\n" .. style.formatFooter(modsResourceAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Enabled RED4ext Mods")

    local red4extAmount = 0
    local red4extMods = {}

    for _, mod in ipairs(mods.red4ext.enabled) do
        for _, tag in ipairs(mod.tags) do
            if tag == "mod" then
                mod.version = ensureIsVersion(mod.filePath, mod.version)

                table.insert(red4extMods, mod)
            end
        end
    end

    table.sort(red4extMods, function(a, b)
        return string.lower(a.filePath) < string.lower(b.filePath)
    end)

    for _, mod in ipairs(red4extMods) do
        text = text .. "\n" .. style.formatEntry(mod.filePath ..
                                                    utils.setStringCursor(mod.filePath, 108, " ") ..
                                                    "Version: " ..
                                                    mod.version)

        red4extAmount = red4extAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(red4extAmount)

    if output.mods.inculdeCurrentLogs then
        text = text ..  "\n\n\n" .. style.formatHeader("RED4ext Current Log")

        local red4extLogsPath = "red4ext/logs"
        local red4extDir = GameDiagnostics.ListDirectory(red4extLogsPath)
        local red4extLogs = {}
        local red4extLog

        for i, item in ipairs(red4extDir) do
            if item.type == "file" and string.find(item.name, "^red4ext")then
                item.date = GameDiagnostics.GetTimeDateStamp(red4extLogsPath .. "/" .. item.name, true)

                table.insert(red4extLogs, item)
            end
        end

        local lastDate = red4extLogs[1].date
        local lastLog = red4extLogs[1]

        for i = 2, #red4extLogs do
            local currentDate = red4extLogs[i].date

            if utils.compareTimeDateStamps(currentDate, lastDate) then
                lastDate = red4extLogs[i].date
                lastLog = red4extLogs[i]
            end
        end

        red4extLog = GameDiagnostics.ReadTextFile(red4extLogsPath .. "/" .. lastLog.name)
        text = text .. "\n\n" .. red4extLog
        text = text .. "\n" .. style.formatFooter()
    end

    text = text ..  "\n\n\n" .. style.formatHeader("Enabled Redscript Mods")

    local redscriptAmount = 0

    table.sort(mods.redscript.enabled, function(a, b)
        if a.type ~= b.type then
            return a.type == "dir"
        end

        return string.lower(a.name) < string.lower(b.name)
    end)

    for _, mod in ipairs(mods.redscript.enabled) do
        text = text .. "\n" .. style.formatEntry(mod.name)

        redscriptAmount = redscriptAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(redscriptAmount)

    if output.mods.inculdeCurrentLogs then
        text = text ..  "\n\n\n" .. style.formatHeader("RedScript Current Log")

        local redscriptLog = GameDiagnostics.ReadTextFile("r6/logs/redscript_rCURRENT.log")

        text = text .. "\n\n" .. redscriptLog
        text = text .. "\n" .. style.formatFooter()
    end

    text = text ..  "\n\n\n" .. style.formatHeader("Enabled CET Mods")

    local cetAmount = 0

    for _, mod in ipairs(mods.cet.enabled) do
        text = text .. "\n" .. style.formatEntry(mod.name)

        cetAmount = cetAmount + 1
    end
    

    text = text .. "\n" .. style.formatFooter(cetAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Archives")

    local archiveAmount = 0

    table.sort(mods.archive.enabled, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    for _, mod in ipairs(mods.archive.enabled) do
        text = text .. "\n" .. style.formatEntry(mod.name)

        for _, tag in ipairs(mod.tags) do
            if tag == "archiveXl" then
                text = text .. " (found a corresponding \".xl\" file)"
            end
        end

        archiveAmount = archiveAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(archiveAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Enabled Tweaks")

    local tweaksAmount = 0

    table.sort(mods.tweaks.enabled, function(a, b)
        if a.type ~= b.type then
            return a.type == "dir"
        end
        
        return string.lower(a.name) < string.lower(b.name)
    end)

    for _, mod in ipairs(mods.tweaks.enabled) do
        text = text .. "\n" .. style.formatEntry(mod.name)

        tweaksAmount = tweaksAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(tweaksAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Other loaded")

    local otherAmount = 0

    table.sort(mods.other, function(a, b)
        return string.lower(a.filePath) < string.lower(b.filePath)
    end)

    for _, mod in ipairs(mods.other) do
        mod.version = ensureIsVersion(mod.filePath, mod.version)

        text = text .. "\n" .. style.formatEntry(mod.filePath ..
                                                    utils.setStringCursor(mod.filePath, 108, " ") ..
                                                    "Version: " ..
                                                    mod.version)

        otherAmount = otherAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(otherAmount)

    text = text .. "\n\nEnd of Report."

    GameDiagnostics.WriteToOutput(filePath, text)

    return fileName
end

local function generateModsReport()
    ImGuiExt.SetNotification(0, "Generating Mods Report...")

    local fileName = getModsReport()

    if fileName and isModsReport(fileName) then
        ImGuiExt.SetStatusBar("Mods Report is ready.")
        ImGuiExt.SetNotification(2, "Mods Report is ready.")
    else
        ImGuiExt.SetNotification(2, "Couldn't generate Mods Report")
    end
end

local function initalizeGetPathsSettings()
    output.paths = {
        asPaths = false,
        includeLogs = false,
        requestedLocations = ""
    }
end

local function isIgnoredFile(fileName, includeLogs)
    fileName = string.lower(fileName)

    local ignoredFiles = {
        [".stub"] = true,
        ["__folder_managed_by_vortex"] = true,
        ["db.sqlite3"] = true,
        ["vortex_placeholder.txt"] = true,
        ["vortexdeployment.json"] = true,
    }

    if ignoredFiles[fileName] or string.find(fileName, "%.vortex_backup$") then
        return true
    end

    if not includeLogs and string.find(fileName, "%.log$") then
        return true
    end

    return false
end

local function mapDirectory(relativePath, includeLogs)
    relativePath = utils.normalizePath(relativePath)
    local items = GameDiagnostics.ListDirectory(relativePath)

    if not items then
        return nil
    end

    local result = {}

    for _, item in ipairs(items) do
        if not isIgnoredFile(item.name, includeLogs) then
            if item.type == "file" then
                result[item.name] = {
                    type = "file"
                }
            elseif item.type == "dir" then
                local subPath

                if relativePath == "" then
                    subPath = item.name
                else
                    subPath = relativePath .. "/" .. item.name
                end

                result[item.name] = {
                    type = "dir",
                    contents = mapDirectory(subPath, includeLogs)
                }
            end
        end
    end

    return result
end

local function getPaths(dirMap, currentPath, result)
    result = result or {}
    currentPath = currentPath or ""

    for name, item in pairs(dirMap) do
        local path = currentPath == "" and name or currentPath .. "/" .. name

        if item.type == "file" then
            table.insert(result, path)
        elseif item.type == "dir" and item.contents then
            getPaths(item.contents, path, result)
        end
    end

    if currentPath == "" then
        table.sort(result)

        return result
    end
end

local function generatePaths(location, includeLogs)
    local gamePath = GameDiagnostics.GetGamePath()
    location = utils.removePrefixPath(location, gamePath)
    local result = getPaths(mapDirectory(location, includeLogs))
    local pathsString = ""

    for i, line in ipairs(result) do
        if location ~= "" then
            pathsString = pathsString .. location .. "/" .. line
        else
            pathsString = pathsString .. line
        end

        if i < #result then
            pathsString = pathsString .. "\n"
        end
    end

    return pathsString
end

local function drawInvalidLocationInfo(invalidLocations)
    local screenWidth, screenHeight = GetDisplayResolution()
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    local windowWidth = 480

    ImGui.SetNextWindowPos((screenWidth - windowWidth) / 2, screenHeight / 2 - 120)
    ImGui.SetNextWindowSize(windowWidth, 0)

    if ImGui.Begin("Invalid Path", ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.None) then
        ImGui.Spacing()
        ImGui.Spacing()
        ImGui.Indent(itemSpacing.x)
        ImGuiExt.TextAlt("The requested path(s): ")

        for _, location in ipairs(invalidLocations) do
            ImGuiExt.TextColor(location, 1, 0, 0, 1, true)
        end
        
        ImGuiExt.TextAlt("is(are) not valid relative path(s) to locations within the game's base directory.", true)
        ImGui.Indent(- itemSpacing.x)
        ImGui.Spacing()

        local button_width = 120
        local contentRegionAvailX = ImGui.GetContentRegionAvail()

        ImGuiExt.AlignNextItemToCenter(button_width, contentRegionAvailX)

        if ImGui.Button("Ok", button_width, 0) then
            output.paths.invalidLocations = nil
            output.paths.isInvalidLocationsPopup = false

            app.disableRootWindow(output.paths.isInvalidLocationsPopup)
        end

        ImGui.Spacing()
        ImGui.Spacing()
    end

    ImGui.End()
end

local function isModLocation(locationPath)
    locationPath = utils.removePrefixPath(locationPath, GameDiagnostics.GetGamePath())

    local modDirectoriesPaths = {
        "archive/pc/mod",
        "bin/x64/plugins/cyber_engine_tweaks/mods",
        "red4ext/plugins",
        "r6/scripts",
        "r6/tweaks"
    }

    for _, dirPath in ipairs(modDirectoriesPaths) do
        if string.find(locationPath, dirPath) then
            return true
        end
    end

    return false
end

local function dumpPaths(requestedLocations)
    ImGuiExt.SetNotification(0, "Generating Paths...")

    local fileName = ""

    if #requestedLocations == 1 and requestedLocations[1] ~= "" then
        fileName = string.gsub(utils.getPathLastComponent(requestedLocations[1]), "[/\\]+", "")
    elseif #requestedLocations == 1 then
        fileName = "Cyberpunk 2077"
    else
        fileName = "requested"
    end

    fileName = fileName .. (not output.paths.asPaths and "-paths" or "") .. "-" .. GameDiagnostics.GetCurrentTimeDate(true)
    local extension = not output.paths.asPaths and ".txt" or ".paths"
    local filePath = "_PATHS\\" .. fileName .. extension
    local result = ""

    for i, location in ipairs(requestedLocations) do
        if not output.paths.asPaths then
            result = result .. style.formatHeader(location) .. "\n"
        end

        result = result .. generatePaths(location, output.paths.includeLogs)

        if i < #requestedLocations then
            result = result .. "\n"
        end
    end

    GameDiagnostics.WriteToOutput(filePath, result)
    ImGuiExt.SetNotification(2, "Requested Paths Are Ready.")
end

local function drawGetPathsConfirmation(nonStandardLocations)
    local screenWidth, screenHeight = GetDisplayResolution()
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    local windowWidth = 480

    ImGui.SetNextWindowPos((screenWidth - windowWidth) / 2, screenHeight / 2 - 120)
    ImGui.SetNextWindowSize(windowWidth, 0)

    if ImGui.Begin("Confirm Locations", ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.None) then
        ImGui.Spacing()
        ImGui.Spacing()
        ImGui.Indent(itemSpacing.x)
        ImGuiExt.TextAlt("The requested location(s): ")

        for _, location in ipairs(nonStandardLocations) do
            ImGuiExt.TextAlt(location, true)
        end

        ImGuiExt.TextAlt("is(are) not standard mod's location(s). Are you sure?")
        ImGui.Indent(- itemSpacing.x)
        ImGui.Spacing()

        local button_width = 120
        local contentRegionAvailX = ImGui.GetContentRegionAvail()

        ImGuiExt.AlignNextItemToCenter((button_width * 2) + itemSpacing.x, contentRegionAvailX)

        if ImGui.Button("No", button_width, 0) then
            output.paths.nonStandardLocations = nil
            output.paths.requestedLocationsTable = nil
            output.paths.isConfirmationPopup = false

            app.disableRootWindow(output.paths.isConfirmationPopup)
        end

        ImGui.SameLine()

        if ImGui.Button("Yes", button_width, 0) then
            output.paths.nonStandardLocations = nil
            output.paths.isConfirmationPopup = false

            app.disableRootWindow(output.paths.isConfirmationPopup)
            dumpPaths(output.paths.requestedLocationsTable)

            output.paths.requestedLocationsTable = nil
        end

        ImGui.Spacing()
        ImGui.Spacing()
    end

    ImGui.End()
end

local function parseRequestedLocations()
    output.paths.invalidLocations = {}
    output.paths.nonStandardLocations = {}
    local requestedLocations = {}

    if output.paths.requestedLocations ~= "" then
        requestedLocations = utils.parsePaths(output.paths.requestedLocations)
    else
        requestedLocations = { "" }
    end

    for _, location in ipairs(requestedLocations) do
        print(location)

        if not utils.isValidPath(location) or not GameDiagnostics.IsDirectory(location) then
            table.insert(output.paths.invalidLocations, location)
        end
    end

    if next(output.paths.invalidLocations) then
        output.paths.isInvalidLocationsPopup = true

        ImGuiExt.SetStatusBar("Enter valid relative path(s) to location(s) within the game's base directory.")

        return
    end

    output.paths.requestedLocationsTable = requestedLocations

    for _, location in ipairs(requestedLocations) do
        if not isModLocation(location) then
            if location == "" then
                location = "The game's base directory"
            end

            table.insert(output.paths.nonStandardLocations, location)
        end
    end

    if next(output.paths.nonStandardLocations) then
        output.paths.isConfirmationPopup = true

        return
    end

    dumpPaths(output.paths.requestedLocationsTable)
end

local function drawScanModsRequest()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    local infoText = "To start, please press the button below."
    local infoTextWidth = ImGui.CalcTextSize(infoText)
    local scanModsButtonWidth = ImGui.CalcTextSize("Scan Mods") + 8 * itemSpacing.x

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
    ImGuiExt.AlignNextItemToCenter(infoTextWidth, contentRegionAvailX)
    ImGuiExt.TextAlt(infoText, true)
    ImGui.Text("")
    ImGuiExt.AlignNextItemToCenter(scanModsButtonWidth, contentRegionAvailX)

    if ImGui.Button("Scan Mods", scanModsButtonWidth, 0) then
       scanMods()
    end

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
end


local function draw()
    if not app.isAppModule("gameModules") then
        ImGuiExt.SetStatusBar("Missing \"Game Modules\" AppModule. Presented data will be inaccurate.")
    end

    if not next(mods) then
        drawScanModsRequest()

        return
    end

    local windowWidth = ImGui.GetWindowWidth()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local windowPaddingX = ImGui.GetStyle().WindowPadding.x
    local itemWidth = windowWidth - 2 * windowPaddingX
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    local scrollbarSize = ImGui.GetStyle().ScrollbarSize
    local textRed, textGreen, textBlue, textAlpha

    search.updateFilterInstance("GameDiagnostics.Root")

    if search.getFilterQuery("GameDiagnostics.Root") == "" then
        sortedModsResources.filtered = sortedModsResources.parsed
    else
        if ImGuiExt.IsSearchInputTyped(search.getActiveFilter().label) then
            search.setFiltering(true)
        end

        sortedModsResources.filtered = search.filter("GameDiagnostics.Root",
                                                        sortedModsResources.parsed,
                                                        search.getFilterQuery("GameDiagnostics.Root"))
    end

    local itemColumnWidth = itemWidth / 2 + (scrollbarSize / 2)

    ImGui.Columns(2, "##GameDiagnostics.ModsResource.ListHeader")
    ImGui.SetColumnWidth(0, itemColumnWidth)
    ImGui.Separator()
    ImGuiExt.TextTitle("Mods Resource", 1, true)
    ImGui.NextColumn()
    ImGuiExt.TextTitle("Version / Status", 1, true)
    ImGui.NextColumn()
    ImGui.Separator()
    ImGui.Columns(1)

    ImGui.BeginChildFrame(ImGui.GetID("GameDiagnostics.ModsResource.List"),
                            itemWidth,
                            300 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)


    ImGui.Columns(2, "##GameDiagnostics.ModsResource.List")
    ImGui.SetColumnWidth(0, itemColumnWidth - windowPaddingX)

    for _, mod in ipairs(sortedModsResources.filtered) do
        ImGuiExt.TextAlt(mod.name)
        ImGui.NextColumn()

        if mod.version ~= "NOT INSTALLED" then
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("textAlt")
        else
            textRed, textGreen, textBlue, textAlpha = 1, 0.863, 0, 1
        end

        ImGui.PushStyleColor(ImGuiCol.Text, textRed, textGreen, textBlue, textAlpha)
        ImGui.Text(mod.version)
        ImGui.PopStyleColor()
        ImGui.NextColumn()
    end

    ImGui.Columns(1)
    ImGui.EndChildFrame()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.BeginChildFrame(ImGui.GetID("GameDiagnostics.Features"),
                            itemWidth,
                            360 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)

    ImGui.Separator()
    ImGuiExt.TextTitle("Mods Report", 0.9, true)
    ImGui.Spacing()

    output.mods.inculdeCurrentLogs = ImGuiExt.Checkbox("Include current RED4ext and Redscript logs", output.mods.inculdeCurrentLogs)

    ImGui.Text("")

    local generateReportButtonWidth = ImGui.CalcTextSize("Generate Mods Report") + 8 * itemSpacing.x

    ImGuiExt.AlignNextItemToCenter(generateReportButtonWidth, contentRegionAvailX)

    if ImGui.Button("Generate Mods Report", generateReportButtonWidth, 0) then
        generateModsReport()
    end

    if output.mods.isReport then
        local reportInfo = "Report \"" .. output.mods.reportName .. "\" is available in\n"
        local reportInfoWidth = ImGui.CalcTextSize(reportInfo)
        local pathWidth = ImGui.CalcTextSize(output.mods.current)

        ImGui.Spacing()
        ImGuiExt.AlignNextItemToCenter(reportInfoWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(reportInfo, true)
        ImGuiExt.AlignNextItemToCenter(pathWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(output.mods.current, true)
        ImGui.Spacing()
    end

    ImGui.Text("")
    ImGui.Separator()
    ImGuiExt.TextTitle("Get Paths", 0.9, true)
    ImGui.Spacing()

    if output.paths.asPaths then
        ImGui.BeginDisabled()
        output.paths.includeLogs = false
    end

    output.paths.includeLogs = ImGuiExt.Checkbox("Include logs", output.paths.includeLogs)

    if output.paths.asPaths then
        ImGui.EndDisabled()
    end

    if settings.getModSetting("developerTools") then
        output.paths.asPaths = ImGuiExt.Checkbox("Save as \".paths\" file", output.paths.asPaths)
    end

    ImGui.Text("")
    ImGuiExt.TextAlt("Add relative paths to locations within the game's base directory separated by semicolon (\";\"):", true)

    output.paths.requestedLocations = ImGui.InputTextMultiline("##FileName",
                                                                output.paths.requestedLocations,
                                                                32768,
                                                                contentRegionAvailX,
                                                                4 * ImGui.GetTextLineHeightWithSpacing())

    local getPathsButtonWidth = ImGui.CalcTextSize("Get Paths") + 8 * itemSpacing.x

    ImGui.Spacing()
    ImGuiExt.AlignNextItemToCenter(getPathsButtonWidth, contentRegionAvailX)

    if ImGui.Button("Get Paths", getPathsButtonWidth, 0) then
        parseRequestedLocations()
    end

    ImGui.Text("")
    ImGui.EndChildFrame()

    if output.paths.isConfirmationPopup then
        app.disableRootWindow(output.paths.isConfirmationPopup)
        ImGui.EndDisabled()
        drawGetPathsConfirmation(output.paths.nonStandardLocations)
    end

    if output.paths.isInvalidLocationsPopup then
        app.disableRootWindow(output.paths.isInvalidLocationsPopup)
        ImGui.EndDisabled()
        drawInvalidLocationInfo(output.paths.invalidLocations)
    end
end

local events = {}

function events.onInit()
    initalizeModsReportSettings()
    initalizeGetPathsSettings()
end

function events.onOverlayClose()
    output.paths.isConfirmationPopup = false
    output.paths.isInvalidLocationsPopup = false
end

local function getFileHashAsync(filePath)
    local query = Game.GetCyberlibsAsyncHelper():GetFileHash(filePath)

    return query
end

local function getHashTest()
    local result = getFileHashAsync("archive/pc/content/audio_2_soundbanks.archive")

    if result.isCalculating then
        utils.setDelay(1, "getHashTest", getHashTest)
        print(result.hash)
    else
        print(result.hash)
    end
end

local function verifyPathsAsync(filePath)
    local query = Game.GetCyberlibsAsyncHelper():VerifyPaths(filePath)

    return query
end

local function verifyPathsTest()
    local result = verifyPathsAsync("bin/x64/plugins/cyber_engine_tweaks/mods/Cyberlibs/knowledgeBase/modsResources/Cyber Engine Tweaks.paths")

    if result.isCalculating then
        utils.setDelay(1, "verifyPathsTest", verifyPathsTest)
        print("Calculating...")
    else
        print(result.isValid)
    end
end

return {
    __NAME = "Game Diagnostics",
    __ICON = IconGlyphs.Stethoscope,
    draw = draw,
    events = events,
    inputs = {
        { id = "getHash", description = "Get Hash Test", keyReleaseCallback = getHashTest },
        { id = "verifyPaths", description = "Verify Paths Test", keyReleaseCallback = verifyPathsTest }
    },
    openOnStart = true
}