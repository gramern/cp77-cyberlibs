local app = ...

local gameModules = {
    __NAME = "Game Modules",
    __ICON = IconGlyphs.LibraryShelves,
    __VERSION = { 0, 2, 0},
    __TITLE = ""
}

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local settings = require("globals/settings")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

local modsResources = require("knowledgeBase/modsResources")
local native = require("knowledgeBase/native")
local redmod = require("knowledgeBase/redmod")

local modules = {
    count = {},
    data = {},
    filtered = {},
    loaded = {},
    selected = {}
}

local function drawViewerRow(label, value, rowWidth, labelWidth)
    ImGui.BeginGroup()
    ImGuiExt.TextAlt(tostring(label))
    ImGui.SameLine()
    ImGui.SetCursorPosX(labelWidth)
    ImGui.SetNextItemWidth(rowWidth - labelWidth)

    if value == nil then
        value = "-"
    end

    ImGui.InputText('##' .. label, tostring(value), 256)
    ImGui.EndGroup()
end

local function isNativeModule(filePath, nativeSet)
    for nativePath in pairs(nativeSet) do
        if filePath:sub(-#nativePath) == nativePath then
            return true
        end
    end

    return false
end

local function intializeCategoriesCount()
    modules.count = {
        all = 0,
        ["mod / unknown"] = 0,
        ["mods resource"] = 0,
        ["native"] = 0,
        ["redmod"] = 0,
        ["system"] = 0
    }
end

local function categorizeLoadedModules(loadedModules)
    local modsResourcesTable = modsResources.getTable()
    local nativeTable = native.getTable()
    local redmodTable = redmod.getTable()
    local modsResourcesSet = {}
    local nativeSet = {}
    local redmodSet = {}

    intializeCategoriesCount()

    modules.count.all = #loadedModules

    for _, v in ipairs(modsResourcesTable) do modsResourcesSet[v:lower()] = true end
    for _, v in ipairs(nativeTable) do nativeSet[utils.normalizePath(v)] = true end
    for _, v in ipairs(redmodTable) do redmodSet[utils.normalizePath(v)] = true end
  
    for _, module in ipairs(loadedModules) do
        local lowerFileName = module.fileName:lower()
        
        if module.normalizedPath:find("windows") then
            module.category = "system"
            modules.count["system"] = modules.count["system"] + 1
        elseif isNativeModule(module.normalizedPath, nativeSet) then
            module.category = "native"
            modules.count["native"] = modules.count["native"] + 1
        elseif isNativeModule(module.normalizedPath, redmodSet) then
            module.category = "redmod"
            modules.count["redmod"] = modules.count["redmod"] + 1
        elseif modsResourcesSet[lowerFileName] then
            module.category = "mods resource"
            modules.count["mods resource"] = modules.count["mods resource"] + 1
        else
            module.category = "mod / unknown"
            modules.count["mod / unknown"] = modules.count["mod / unknown"] + 1
        end
    end
    
    logger.debug(modules.count.all, "modules loaded and categorized.")

    return loadedModules
end

local function getLoadedModules()
    local loadedPaths = GameModule.GetLoadedModules()
    local loadedModules = {}
    local fileNameCount = {}

    for i, filePath in ipairs(loadedPaths) do
        local fileName = utils.getFileName(filePath)
        local onScreenName = fileName
        fileNameCount[fileName] = (fileNameCount[fileName] or 0) + 1
        
        if fileNameCount[fileName] > 1 then
            onScreenName = fileName .. " (" .. fileNameCount[fileName] .. ")"
        end

        loadedModules[i] = {
            fileName = fileName,
            filePath = filePath,
            normalizedPath = utils.normalizePath(filePath),
            onScreenName = onScreenName
        }
    end

    return loadedModules
end

local function refreshLoadedModules()
    modules.data = {}
    modules.loaded = categorizeLoadedModules(getLoadedModules())
end

local function getModule(onScreenName)
    if modules.data[onScreenName] == nil then return nil end

    return modules.data[onScreenName]
end

local function openModule(onScreenName, fileName, filePath)
    if getModule(onScreenName) ~= nil then
        return
    else
        modules.data[onScreenName] = {}
    end

    local moduleData = {
        ["Company Name"] = GameModule.GetCompanyName(filePath),
        ["Description"] = GameModule.GetDescription(filePath),
        ["Entry Point"] = GameModule.GetEntryPoint(filePath),
        ["Export"] = GameModule.GetExport(filePath),
        ["File Name"] = fileName,
        ["File Path"] = filePath,
        ["File Size"] = GameModule.GetFileSize(filePath),
        ["File Type"] = GameModule.GetFileType(filePath),
        ["Import"] = GameModule.GetImport(filePath),
        ["Load Address"] = GameModule.GetLoadAddress(filePath),
        ["Mapped Size"] = GameModule.GetMappedSize(filePath),
        ["TimeDateStamp"] = GameModule.GetTimeDateStamp(filePath),
        ["Version"] = Cyberlibs.GetVersion(filePath)
    }

    modules.data[onScreenName] = tables.deepcopy(moduleData)

    logger.debug("Opened module:", filePath, "On-screen name:", onScreenName)
end

local function selectModule(onScreenName, fileName, filePath)
    for selectableModule, _ in pairs(modules.selected) do
        modules.selected[selectableModule] = (selectableModule == onScreenName)
    end
    
    if modules.selected[onScreenName] then
        openModule(onScreenName, fileName, filePath)
        modules.previewed = onScreenName
    end
end

local function drawModuleTab(onScreenName, fileName, filePath)
    if getModule(onScreenName) == nil then
        openModule(onScreenName, fileName, filePath)
    end

    local moduleData = getModule(onScreenName)
    local windowWidth = ImGui.GetWindowWidth()
    local windowPadding = ImGui.GetStyle().WindowPadding
    local itemWidth = windowWidth - 2 * windowPadding.x

    if moduleData == nil then
        ImGui.Dummy(100, 120)
        local failInfo = "Can't open open module: " .. tostring(fileName)
        ImGuiExt.AlignNextItemToWindowCenter(ImGui.CalcTextSize(failInfo), windowWidth, windowPadding.x)
        ImGuiExt.TextAlt(failInfo)
        ImGui.Dummy(100, 120)
        return
    end

    ImGui.BeginChildFrame(ImGui.GetID("GameModules.ModuleTab." .. tostring(fileName)),
                            itemWidth,
                            564 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)

    local opened = modules.data[onScreenName] or {}
    local contentRegionAvail = ImGui.GetContentRegionAvail()
    local labelWidth = ImGui.CalcTextSize("TimeDateStamp (UTC)") + 6 * ImGuiExt.GetResolutionFactor()

    drawViewerRow("Version", opened["Version"], contentRegionAvail, labelWidth)
    drawViewerRow("Description", opened["Description"], contentRegionAvail, labelWidth)
    drawViewerRow("Company Name", opened["Company Name"], contentRegionAvail, labelWidth)
    drawViewerRow("TimeDateStamp (UTC)", opened["TimeDateStamp"], contentRegionAvail, labelWidth)
    ImGui.Separator()
    drawViewerRow("File Type", opened["File Type"], contentRegionAvail, labelWidth)
    drawViewerRow("File Path", opened["File Path"], contentRegionAvail, labelWidth)
    drawViewerRow("File Size", opened["File Size"], contentRegionAvail, labelWidth)
    ImGui.Separator()
    drawViewerRow("Entry Point", opened["Entry Point"], contentRegionAvail, labelWidth)
    drawViewerRow("Load Address", opened["Load Address"], contentRegionAvail, labelWidth)
    drawViewerRow("Mapped Size", opened["Mapped Size"], contentRegionAvail, labelWidth)
    ImGui.EndChildFrame()
end

local function addModuleTab(onScreenName, fileName, filePath)
    if getModule(onScreenName) == nil then
        openModule(onScreenName, fileName, filePath)
    end

    ImGuiExt.AddTab("RootWindow.TabBar", onScreenName, "", drawModuleTab, onScreenName, fileName, filePath)
end

local function drawSelectedModuleContextMenu(onScreenName, fileName, filePath)
    ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor('text'))

    if ImGui.BeginPopup("GameModules.SelectedModule.PopupMenu") then
        if ImGui.MenuItem(IconGlyphs.OpenInNew .. " " .. "Show in new tab") then
            addModuleTab(onScreenName, fileName, filePath)
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.ContentCopy .. " " .. "Copy File Name") then
            ImGui.SetClipboardText(fileName)
        end

        if ImGui.MenuItem(IconGlyphs.ContentCopy .. " " .. "Copy File Path") then
            ImGui.SetClipboardText(filePath)
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.Refresh .. " " .. "Refresh List") then
            refreshLoadedModules()

            ImGuiExt.SetStatusBar("Refreshed the list.")
        end

        ImGui.EndPopup()
    end

    ImGui.PopStyleColor()
end

local function handleHoveredModule(regionPos, regionSize, onScreenName, fileName, filePath)
    if ImGuiExt.IsMouseClickOverRegion(regionPos, regionSize, ImGuiMouseButton.Right) then
        selectModule(onScreenName, fileName, filePath)
        ImGui.OpenPopup("GameModules.SelectedModule.PopupMenu")
    end
end

local function handleSelectedModule(regionPos, regionSize, onScreenName, fileName, filePath)
    if ImGuiExt.IsMouseClickOverRegion(regionPos, regionSize, ImGuiMouseButton.Left) then
        addModuleTab(onScreenName, fileName, filePath)
    elseif ImGuiExt.IsMouseClickOverRegion(regionPos, regionSize, ImGuiMouseButton.Right) then
        ImGui.OpenPopup("GameModules.SelectedModule.PopupMenu")
    end

    drawSelectedModuleContextMenu(onScreenName, fileName, filePath)
end

function gameModules.draw()
    local resolutionFactor = ImGuiExt.GetResolutionFactor()
    local scaleFactor = ImGuiExt.GetScaleFactor()
    local windowWidth = ImGui.GetWindowWidth()
    local windowPaddingX = ImGui.GetStyle().WindowPadding.x
    local itemWidth = windowWidth - 2 * windowPaddingX
    local regionPos = {}

    if search.getFilterQuery("Game Modules") == "" then
        modules.filtered = modules.loaded
    else
        if search.isFiltering() then
            modules.filtered = search.filter(modules.loaded, search.getFilterQuery("Game Modules"))
        end
    end

    local headerColumnWidth = itemWidth / 2

    ImGui.Columns(2, "##GameModules.LoadedModules.ListHeader")
    ImGui.SetColumnWidth(0, headerColumnWidth)
    ImGui.Separator()
    ImGuiExt.TextAlt("Module")
    ImGui.NextColumn()
    ImGuiExt.TextAlt("Category")
    ImGui.NextColumn()
    ImGui.Separator()
    ImGui.Columns(1)
    ImGui.BeginChildFrame(ImGui.GetID("GameModules.LoadedModules.List"), itemWidth,
                                                                        320 * scaleFactor,
                                                                        ImGuiWindowFlags.NoBackground)
    ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor('textAlt'))
    ImGui.Columns(2, "##GameModules.LoadedModules.List")
    ImGui.SetColumnWidth(0, headerColumnWidth - windowPaddingX)

    for _, module in ipairs(modules.filtered) do
        if modules.selected[module.onScreenName] == nil then
            modules.selected[module.onScreenName] = false
        end

        regionPos.x, regionPos.y = ImGui.GetCursorScreenPos()

        if ImGui.Selectable(module.onScreenName, modules.selected[module.onScreenName],
                                                ImGuiSelectableFlags.SpanAllColumns) then
            selectModule(module.onScreenName, module.fileName, module.filePath)
        end

        ImGui.NextColumn()
        ImGui.Text(module.category)
        ImGui.NextColumn()

        local regionSize = ImVec2.new(windowWidth, 7 * resolutionFactor)

        if modules.selected[module.onScreenName] == true then
            handleSelectedModule(regionPos, regionSize, module.onScreenName, module.fileName, module.filePath)
        else
            handleHoveredModule(regionPos, regionSize, module.onScreenName, module.fileName, module.filePath)
        end
    end

    ImGui.Columns(1)
    ImGui.PopStyleColor()
    ImGui.EndChildFrame()
    ImGui.Separator()
    ImGui.Spacing()
    ImGui.Indent(6)

    if next(modules.count) then
        ImGuiExt.TextAlt(modules.count.all .. " modules, system: " .. modules.count["system"] ..
                                            ", native: " .. modules.count["native"] ..
                                            ", redmod: " .. modules.count["redmod"] ..
                                            ", mods resource: " .. modules.count["mods resource"] ..
                                            ", mod / unknown: " .. modules.count["mod / unknown"], true)
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    local previewed = modules.data[modules.previewed] or {}
    local previewRegionAvail = ImGui.GetContentRegionAvail()
    local labelWidth = ImGui.CalcTextSize("TimeDateStamp (UTC)") + 6 * ImGuiExt.GetResolutionFactor() + windowPaddingX

    drawViewerRow("File Name", previewed["File Name"], previewRegionAvail, labelWidth)
    drawViewerRow("Version", previewed["Version"], previewRegionAvail, labelWidth)
    drawViewerRow("Description", previewed["Description"], previewRegionAvail, labelWidth)
    drawViewerRow("File Path", previewed["File Path"], previewRegionAvail, labelWidth)
    drawViewerRow("Entry Point", previewed["Entry Point"], previewRegionAvail, labelWidth)
    drawViewerRow("Load Address", previewed["Load Address"], previewRegionAvail, labelWidth)
    drawViewerRow("Mapped Size", previewed["Mapped Size"], previewRegionAvail, labelWidth)
    ImGui.Indent(-6)
    ImGui.Spacing()

    if next(modules.loaded) ~= nil then return end
    refreshLoadedModules()
end

return gameModules