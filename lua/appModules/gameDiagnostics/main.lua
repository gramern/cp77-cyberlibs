local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

local sortedModsResources  = {
    filtered = {},
    parsed = {}
}

local mods = {}

local reports = {}

-- local function mapDirectory(relativePath)
--     relativePath = utils.normalizePath(relativePath)
--     local items = GameDiagnostics.ListDirectory(relativePath)

--     if not items then
--         return nil
--     end

--     local result = {}

--     for _, item in ipairs(items) do
--         if item.name ~= "__folder_managed_by_vortex" and item.name ~= ".stub" then
--             if item.type == "file" then
--                 result[item.name] = {
--                     type = "file"
--                 }
--             elseif item.type == "dir" then
--                 local subPath

--                 if relativePath == "" then
--                     subPath = item.name
--                 else
--                     subPath = relativePath .. "/" .. item.name
--                 end

--                 result[item.name] = {
--                     type = "dir",
--                     contents = mapDirectory(subPath)
--                 }
--             end
--         end
--     end

--     return result
-- end

-- local function getPaths(dirMap, currentPath, result)
--     result = result or {}
--     currentPath = currentPath or ""

--     for name, item in pairs(dirMap) do
--         local path = currentPath == "" and name or currentPath .. "/" .. name

--         if item.type == "file" then
--             table.insert(result, path)
--         elseif item.type == "dir" and item.contents then
--             getPaths(item.contents, path, result)
--         end
--     end

--     if currentPath == "" then
--         table.sort(result)

--         return result
--     end
-- end

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
    local taggedModulesSet = {}

    for _, module in ipairs(taggedModules) do
        for _, tag in ipairs(module.tags) do
            if tag == "red4ext" then
                local dirName =  utils.getLastDirectoryName(module.normalizedPath)
                module.version = Cyberlibs.GetVersion(module.normalizedPath)

                if string.sub(dirName, 1, 3) == string.lower(string.sub(module.fileName, 1, 3)) then
                    taggedModulesSet[dirName] = module
                else
                    taggedModulesSet[module.normalizedPath] = module
                end

                break
            end
        end
    end

    local red4extPath = "red4ext/plugins"
    local red4extDir = GameDiagnostics.ListDirectory(red4extPath)

    for _, item in ipairs(red4extDir) do
        local normalizedName = string.lower(item.name)

        if item.type == "dir" and taggedModulesSet[normalizedName] then
            local kbName = getModsResourceName(taggedModulesSet[normalizedName].normalizedPath)

            if kbName then
                taggedModulesSet[normalizedName].kbName = kbName
            end

            table.insert(mods.red4ext.enabled, taggedModulesSet[normalizedName])

            taggedModulesSet[normalizedName] = nil
        end
    end

    for _, item in ipairs(red4extDir) do
        local normalizedName = string.lower(item.name)

        if item.type == "dir" then
            item.normalizedPath = red4extPath .. "/".. normalizedName

            for k, module in pairs(taggedModulesSet) do

                if string.find(k, item.normalizedPath) then
                    table.insert(mods.red4ext.enabled, module)

                    taggedModulesSet[k] = nil

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
            if framework == name then
                local isLoaded = GameModules.IsLoaded(utils.getFileName(relativePath))
                local version = Cyberlibs.GetVersion(utils.getFileName(relativePath))

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
    reports.mods = {
        inculdeCurrentLogs = true
    }
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

    if reports.mods.inculdeCurrentLogs then
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

    if reports.mods.inculdeCurrentLogs then
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

local function drawScanModsRequest()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local infoText = "To start, please press the button below."
    local infoTextWidth = ImGui.CalcTextSize(infoText)

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
    ImGuiExt.AlignNextItemToCenter(infoTextWidth, contentRegionAvailX)
    ImGuiExt.TextAlt(infoText, true)
    ImGui.Text("")
    ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    if ImGui.Button("Scan Mods", 300, 0) then
       scanMods()
    end

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
end

local function draw()
    if not next(mods) then
        drawScanModsRequest()

        return
    end

    local windowWidth = ImGui.GetWindowWidth()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local windowPaddingX = ImGui.GetStyle().WindowPadding.x
    local itemWidth = windowWidth - 2 * windowPaddingX
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

    reports.mods.inculdeCurrentLogs = ImGuiExt.Checkbox("Include current RED4ext and Redscript logs", reports.mods.inculdeCurrentLogs)

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

local events = {}

function events.onInit()
    initalizeModsReportSettings()
end

return {
    __NAME = "Game Diagnostics",
    __ICON = IconGlyphs.Stethoscope,
    -- appApi = {
    --     getPaths = getPaths,
    --     mapDirectory = mapDirectory
    -- },
    draw = draw,
    events = events,
    -- inputs = {
    --     { id = "generateModsReport", description = "Generate Mods Report", keyPressCallback = generateModsReport }
    -- },
    openOnStart = true
}