local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

local installedModsResources  = {
    filtered = {},
    parsed = {}
}

-- local modsFiles = {
--     archive = {},
--     cet = {},
--     red4ext = {},
--     redscript = {},
--     tweaks = {}
-- }

local reports = {
    mods = {}
}

local function sortModsResources(installed)
    local coreFrameworks = {
        "Cyber Engine Tweaks",
        "RED4ext",
        "RED4ext Loader",
        "Redscript",
        "Ultimate ASI Loader",
    }

    for i, name in ipairs(coreFrameworks) do
        if installed[name] then
            installedModsResources.parsed[i] = {
                name = name,
                version = installed[name]
            }
        end

        installed[name] = nil
    end

    local coreFrameworksCount = #coreFrameworks
    local installedContents = tables.assignKeysOrder(installed)

    table.sort(installedContents, function(a, b)
        return a:lower() < b:lower()
    end)

    for i, name in ipairs(installedContents) do
        installedModsResources.parsed[i + coreFrameworksCount] = {
            name = name,
            version = installed[name]
        }
    end
end

local function checkModsResources()
    if not app.isAppModule("gameModules") then
        logger.warning("Install \"Game Modules\" app module to browse installed mods resources.")

        return {}
    end

    local categorizedModules = app.getCategorizedModules()

    if not next(categorizedModules) then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return {}
    end

    local modsResources = require("knowledgeBase/modsResources")
    local modsResourcesTable = modsResources.getTable()
    local installed = {}

    for name in pairs(modsResourcesTable) do
        installed[name] = "NOT INSTALLED"
    end

    for _, module in ipairs(categorizedModules) do
        if module.category == "mods resource" then
            local normalizedPath = module.normalizedPath:lower()
            
            for name, path in pairs(modsResourcesTable) do
                local relativePath = utils.normalizePath(path):lower()
                
                if normalizedPath:sub(-#relativePath) == relativePath then
                    local version = Cyberlibs.GetVersion(module.filePath)

                    if version == "Unknown" then
                        version = "Installed, version unknown"
                    end

                    installed[name] = version
                    break
                end
            end
        end
    end

    return installed
end

local function mapDirectory(relativePath)
    relativePath = utils.normalizePath(relativePath)
    local items = GameDiagnostics.ListDirectory(relativePath)

    if not items then
        return nil
    end

    local result = {}

    for _, item in ipairs(items) do
        if item.name ~= "__folder_managed_by_vortex" and item.name ~= ".stub" then
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
                    contents = mapDirectory(subPath)
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

local function collectModsResourcesData()
    if not next(installedModsResources.parsed) then
        sortModsResources(checkModsResources())
    end
end

local function isModsReport(fileName)
    if not fileName then return end

    if GameDiagnostics.IsFile("_DIAGNOSTICS/_REPORTS/" .. fileName) then
        reports.mods.isReport = true
        reports.mods.reportName = fileName
        reports.mods.path = GameDiagnostics.GetGamePath() .. "\\_DIAGNOSTICS\\_REPORTS"

        return true
    else
        reports.mods.isReport = false
        reports.mods.reportName = nil
    end
end

local function dumpMods()
    if not app.isAppModule("gameModules") then
        logger.warning("Install \"Game Modules\" app module to create reports.")

        return
    end

    collectModsResourcesData()
    local modules = app.getCategorizedModules()

    if not next(modules) then
        logger.warning("Install Cyberlibs RED4ext Plugin.")
        logger.warning("No loaded modules found. Can't prepare a report.")

        return
    end

    local reportsDir = "_REPORTS"
    local fileName = "Mods-" .. GameDiagnostics.GetCurrentTimeDate(true) .. ".txt"
    local filePath = reportsDir .. "/" .. fileName

    local text = "Mods Report\nGenerated in Cyberlibs on " .. GameDiagnostics.GetCurrentTimeDate()
    text = text .. "\nGame version: " .. GameModules.GetVersion("Cyberpunk2077.exe")
    text = text .. "\n\n\n" .. style.formatHeader("Mods Resources")

    local modsResourceAmount = 0

    for _, module in ipairs(installedModsResources.parsed) do
        text = text .. "\n" .. style.formatEntry(module.name ..
                                                    utils.setStringCursor(module.name, 40, " ") ..
                                                    "Version: " ..
                                                    module.version)

        if module.version ~= "NOT INSTALLED" then
            modsResourceAmount = modsResourceAmount + 1
        end
    end

    text = text ..  "\n" .. style.formatFooter(modsResourceAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("RED4ext Mods / Unknown")

    local modAmount = 0
    local mods = {}

    for _, module in ipairs(modules) do
        if module.category == "mod / unknown" then
            table.insert(mods, module)
        end
    end

    table.sort(mods, function(a, b)
        return string.lower(a.filePath) < string.lower(b.filePath)
    end)

    for _, mod in ipairs(mods) do
        text = text .. "\n" .. style.formatEntry(mod.filePath ..
                                                    utils.setStringCursor(mod.filePath, 128, " ") ..
                                                    "Version: " ..
                                                    Cyberlibs.GetVersion(mod.filePath))

        modAmount = modAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(modAmount)
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
    text = text ..  "\n\n\n" .. style.formatHeader("RedScript Current Log")

    local redscriptLog = GameDiagnostics.ReadTextFile("r6/logs/redscript_rCURRENT.log")

    text = text .. "\n\n" .. redscriptLog
    text = text .. "\n" .. style.formatFooter()
    text = text ..  "\n\n\n" .. style.formatHeader("Installed CET Mods")

    local cetAmount = 0
    local cetModsPath = "bin/x64/plugins/cyber_engine_tweaks/mods"
    local cetModsDir = GameDiagnostics.ListDirectory(cetModsPath)

    for _, item in ipairs(cetModsDir) do
        if item.type == "dir" and GameDiagnostics.IsFile(cetModsPath .. "/" .. item.name .. "/init.lua") then
            text = text .. "\n" .. style.formatEntry(item.name)

            cetAmount = cetAmount + 1
        end
    end

    text = text .. "\n" .. style.formatFooter(cetAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Disabled CET Mods (Missing init.lua)")

    local missingCetAmount = 0

    for _, item in ipairs(cetModsDir) do
        if item.type == "dir" and not GameDiagnostics.IsFile(cetModsPath .. "/" .. item.name .. "/init.lua") then
            text = text .. "\n" .. style.formatEntry(item.name)

            missingCetAmount  = missingCetAmount  + 1
        end
    end

    text = text .. "\n" .. style.formatFooter(missingCetAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Archives")

    local archiveAmount = 0
    local archiveModsPath = "archive/pc/mod"
    local archiveModsDir = GameDiagnostics.ListDirectory(archiveModsPath)

    for _, item in ipairs(archiveModsDir) do
        if item.type == "file" and item.name ~= "__folder_managed_by_vortex" then
            text = text .. "\n" .. style.formatEntry(item.name)

            archiveAmount = archiveAmount + 1
        end
    end

    text = text .. "\n" .. style.formatFooter(archiveAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("Tweaks")

    local tweaksAmount = 0
    local tweaksPath = "r6\\tweaks"
    local tweaksPaths = getPaths(mapDirectory(tweaksPath))

    for _, path in ipairs(tweaksPaths) do
        text = text .. "\n" .. style.formatEntry(path)
        tweaksAmount = tweaksAmount + 1
    end

    text = text .. "\n" .. style.formatFooter(tweaksAmount)
    text = text ..  "\n\n\n" .. style.formatHeader("RedMods")

    local redmodAmount = 0
    local redmodPath = "mods"
    local redmodPaths = getPaths(mapDirectory(redmodPath))

    for _, path in ipairs(redmodPaths) do
        text = text .. "\n" .. style.formatEntry(path)
        redmodAmount = redmodAmount  + 1
    end

    text = text .. "\n" .. style.formatFooter(redmodAmount)

    text = text .. "\n\nEnd of Report."

    GameDiagnostics.WriteToOutput(filePath, text)

    return fileName
end

local function generateModsReport()
    ImGuiExt.SetNotification(0, "Generating Mods Report...")

    local fileName = dumpMods()

    if fileName and isModsReport(fileName) then
        ImGuiExt.SetStatusBar("Mods Report is ready.")
        ImGuiExt.SetNotification(2, "Mods Report is ready.")
    else
        ImGuiExt.SetNotification(2, "Couldn't generate Mods Report")
    end
end

-- local function drawModsExplorer()
--     ImGuiExt.TextAlt("In works...")
-- end

local function draw()
    local windowWidth = ImGui.GetWindowWidth()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local windowPaddingX = ImGui.GetStyle().WindowPadding.x
    local itemWidth = windowWidth - 2 * windowPaddingX
    local scrollbarSize = ImGui.GetStyle().ScrollbarSize
    local textRed, textGreen, textBlue, textAlpha

    search.updateFilterInstance("GameDiagnostics.Root")

    if search.getFilterQuery("GameDiagnostics.Root") == "" then
        installedModsResources.filtered = installedModsResources.parsed
    else
        if ImGuiExt.IsSearchInputTyped(search.getActiveFilter().label) then
            search.setFiltering(true)
        end

        installedModsResources.filtered = search.filter("GameDiagnostics.Root",
                                                        installedModsResources.parsed,
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

    for _, mod in ipairs(installedModsResources.filtered) do
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
    ImGui.Text("")

    ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    if ImGui.Button("Generate Mods Report", 300, 0) then
        generateModsReport()
    end

    if reports.mods.isReport then
        local reportInfo = "Report \"" .. reports.mods.reportName .. "\" is available in\n"
        local reportInfoWidth = ImGui.CalcTextSize(reportInfo)
        local pathWidth = ImGui.CalcTextSize(reports.mods.path)

        ImGui.Spacing()
        ImGuiExt.AlignNextItemToCenter(reportInfoWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(reportInfo, true)
        ImGuiExt.AlignNextItemToCenter(pathWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(reports.mods.path, true)
        ImGui.Spacing()
    end

    ImGui.Text("")
    -- ImGui.Separator()
    -- ImGui.Text("")
    -- ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    -- if ImGui.Button("Browse Mods Files", 300, 0) then
    --     ImGuiExt.AddTab("RootWindow.TabBar", "Mods Explorer", "", drawModsExplorer)
    -- end

    -- ImGui.Text("")
end

local function test()
    print(Game.GetGameDiagnostics():IsFile("Cyberpunk2077.exe"))
end

local events = {}

function events.onOverlayOpen()
    collectModsResourcesData()
end

return {
    __NAME = "Game Diagnostics",
    __ICON = IconGlyphs.Stethoscope,
    appApi = {
        getPaths = getPaths,
        mapDirectory = mapDirectory
    },
    draw = draw,
    events = events,
    inputs = {
        { id = "generateModsReport", description = "Generate Mods Report", keyPressCallback = generateModsReport },
        { id = "gettingTest", description = "testing", keyPressCallback = test }
    },
    openOnStart = true
}