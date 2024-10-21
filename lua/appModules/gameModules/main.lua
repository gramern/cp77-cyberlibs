local app = ...

local gameModules = {
    __NAME = "Game Modules",
    __ICON = IconGlyphs.Bookshelf,
    __VERSION = { 0, 2, 0},
    __TITLE = ""
}

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local settings = require("globals/settings")
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

local widgetState = {}

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
        ["Import"] = {},
        ["Load Address"] = GameModule.GetLoadAddress(filePath),
        ["Mapped Size"] = GameModule.GetMappedSize(filePath),
        ["TimeDateStamp"] = GameModule.GetTimeDateStamp(filePath),
        ["Version"] = Cyberlibs.GetVersion(filePath)
    }
    
    local exportStruct = GameModule.GetExport(filePath)

    if next(exportStruct) then
        for i, export in ipairs(exportStruct) do
            moduleData["Export"][i] = {
                entry = export.entry,
                ordinal = export.ordinal,
                rva = export.rva,
                forwarderName = export.forwarderName
            }
        end
    end

    local importStruct = GameModule.GetImport(filePath)

    if next(importStruct) then
        for i, import in ipairs(importStruct) do
            moduleData["Import"][import.fileName] = {}

            for j, entry in ipairs(import.entries) do
                moduleData["Import"][import.fileName][j] = entry
            end
        end
    end

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

    if ImGui.BeginPopupContextItem(label, ImGuiPopupFlags.MouseButtonRight) then
        ImGuiExt.MenuItemCopyValue(value, "Value")
        ImGui.EndPopup()
    end

    ImGui.EndGroup()
end

local function drawPopupContextExportTable(exportLabel, popupLabel, copyValue, copyValueLabel)
    if ImGui.IsPopupOpen(popupLabel) then
        widgetState[exportLabel].isContextPopup = true
    else
        widgetState[exportLabel].isContextPopup = false
    end

    if ImGui.BeginPopupContextWindow(popupLabel, ImGuiPopupFlags.MouseButtonRight) then
        ImGuiExt.MenuItemCopyValue(copyValue, copyValueLabel)

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.ArrowUp .. " " .. "Jump To Start") then
            widgetState[exportLabel].jumpToHeader = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.ArrowCollapseUp .. " " .. "Collapse Export") then
            widgetState[exportLabel].open = false
        end

        ImGui.EndPopup()
    end
end

local function drawExportTable(exportLabel, export, itemWidth)
    local entryColumnWidth = itemWidth / 2.5
    local detailColumnWidth = entryColumnWidth / 3

    ImGui.Columns(5, exportLabel)
    ImGui.SetColumnWidth(0, 20 * ImGuiExt.GetResolutionFactor())
    ImGui.SetColumnWidth(1, entryColumnWidth)
    ImGui.SetColumnWidth(2, detailColumnWidth)
    ImGui.SetColumnWidth(3, detailColumnWidth)
    ImGui.Separator()
    ImGuiExt.TextAlt("#")
    ImGui.NextColumn()
    ImGuiExt.TextAlt("Entry")
    ImGui.NextColumn()
    ImGuiExt.TextAlt("Ordinal")
    ImGui.NextColumn()
    ImGuiExt.TextAlt("RVA")
    ImGui.NextColumn()
    ImGuiExt.TextAlt("Forwarder")
    ImGui.NextColumn()

    for i, entry in ipairs(export) do
        local entryName = tostring(entry.entry)
        local ordinal = tostring(entry.ordinal)
        local rva = tostring(entry.rva)
        local forwarder = tostring(entry.forwarderName)
        local summary = entryName .. ", Ordinal:" .. ordinal .. ", RVA: " .. rva .. ", Forwarder: " .. forwarder

        ImGui.Separator()
        ImGuiExt.TextAltScale(tostring(i), 0.85, true)

        local summaryPos = ImVec2.new()
        summaryPos.x, summaryPos.y = ImGui.GetCursorScreenPos()
        summaryPos.y = summaryPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
        local summarySize  = ImVec2.new(summaryPos.x + ImGui.GetColumnWidth(),
                                        summaryPos.y + ImGui.GetTextLineHeight() + 10)

        if ImGuiExt.IsMouseHoverOverRegion(summaryPos, summarySize) then
            widgetState[exportLabel].hovered = summary

            if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                widgetState[exportLabel].clicked = summary
            end
        end

        ImGui.NextColumn()
        ImGuiExt.TextAltScale(entryName, 0.85)

        if entryName then
            local entryPos = ImVec2.new()
            entryPos.x, entryPos.y = ImGui.GetCursorScreenPos()
            entryPos.y = entryPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
            local entrySize  = ImVec2.new(entryPos.x + ImGui.GetColumnWidth(),
                                            entryPos.y + ImGui.GetTextLineHeight() + 10)

            if ImGuiExt.IsMouseHoverOverRegion(entryPos, entrySize) then
                widgetState[exportLabel].hovered = entryName

                if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                    widgetState[exportLabel].clicked = entryName
                end
            end
        end

        ImGui.NextColumn()
        ImGuiExt.TextAltScale(ordinal, 0.85)

        if ordinal then
            local ordinalPos = ImVec2.new()
            ordinalPos.x, ordinalPos.y = ImGui.GetCursorScreenPos()
            ordinalPos.y = ordinalPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
            local ordinalSize  = ImVec2.new(ordinalPos.x + ImGui.GetColumnWidth(),
                                            ordinalPos.y + ImGui.GetTextLineHeight() + 10)

            if ImGuiExt.IsMouseHoverOverRegion(ordinalPos, ordinalSize) then
                widgetState[exportLabel].hovered = ordinal

                if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                    widgetState[exportLabel].clicked = ordinal
                end
            end
        end

        ImGui.NextColumn()
        ImGuiExt.TextAltScale(rva, 0.85)

        if rva then
            local rvaPos = ImVec2.new()
            rvaPos.x, rvaPos.y = ImGui.GetCursorScreenPos()
            rvaPos.y = rvaPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
            local rvaSize  = ImVec2.new(rvaPos.x + ImGui.GetColumnWidth(),
                                        rvaPos.y + ImGui.GetTextLineHeight() + 10)

            if ImGuiExt.IsMouseHoverOverRegion(rvaPos, rvaSize) then
                widgetState[exportLabel].hovered = rva

                if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                    widgetState[exportLabel].clicked = rva
                end
            end
        end

        ImGui.NextColumn()
        ImGuiExt.TextAltScale(forwarder, 0.85)

        if forwarder then
            local forwarderPos = ImVec2.new()
            forwarderPos.x, forwarderPos.y = ImGui.GetCursorScreenPos()
            forwarderPos.y = forwarderPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
            local forwarderSize  = ImVec2.new(forwarderPos.x + ImGui.GetColumnWidth(),
                                                forwarderPos.y + ImGui.GetTextLineHeight() + 10)

            if ImGuiExt.IsMouseHoverOverRegion(forwarderPos, forwarderSize) then
                widgetState[exportLabel].hovered = forwarder

                if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                    widgetState[exportLabel].clicked = forwarder
                end
            end
        end

        ImGui.NextColumn()
    end

    ImGui.Columns(1)

    if not widgetState[exportLabel].isContextPopup then
        ImGuiExt.SetStatusBar(widgetState[exportLabel].hovered)
    end
end

local function drawPopupContextImportTreeNode(importLabel, popupLabel, copyValue, copyValueLabel)
    if ImGui.IsPopupOpen(popupLabel) then
        widgetState[importLabel].isContextPopup = true
    else
        widgetState[importLabel].isContextPopup = false
    end

    if ImGui.BeginPopupContextWindow(popupLabel, ImGuiPopupFlags.MouseButtonRight) then
        ImGuiExt.MenuItemCopyValue(copyValue, copyValueLabel)

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.ArrowTopLeft .. " " .. "Jump To Selection") then
            widgetState[importLabel].commands.jumpToSelected = true
        end

        if ImGui.MenuItem(IconGlyphs.ArrowUp .. " " .. "Jump To Start") then
            widgetState[importLabel].commands.jumpToHeader = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.MinusBoxMultipleOutline .. " " .. "Collapse Others") then
            widgetState[importLabel].commands.collapseOther = true
        end

        if ImGui.MenuItem(IconGlyphs.CollapseAllOutline .. " " .. "Collapse All") then
            widgetState[importLabel].commands.collapseAll = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.ArrowCollapseUp .. " " .. "Collapse Import") then
            widgetState[importLabel].open = false
        end

        ImGui.EndPopup()
    end
end

local function drawImportTreeNode(node, importName, importLabel)
    local flags = ImGuiTreeNodeFlags.SpanFullWidth
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('textAlt')
    local shouldOpen

    if not widgetState[importLabel].isContextPopup then
        local rectPos = ImVec2.new()
        rectPos.x, rectPos.y = ImGui.GetCursorScreenPos()
        local rectSize = ImVec2.new(rectPos.x + contentRegionAvailX, rectPos.y + ImGui.GetTextLineHeight() - 10)

        if ImGuiExt.IsMouseHoverOverRegion(rectPos, rectSize) then
            widgetState[importLabel].hovered = importName

            if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
                widgetState[importLabel].clicked = importName
            end
        end
    end

    ImGui.PushStyleColor(ImGuiCol.Text, textRed, textGreen, textBlue, textAlpha)

    if importName == widgetState[importLabel].selected then
        flags = flags + ImGuiTreeNodeFlags.Selected
        shouldOpen = true
        textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
    end

    if widgetState[importLabel].commands.jumpToSelected and importName == widgetState[importLabel].selected then
        ImGui.SetScrollHereY()
    end

    if shouldOpen then
        if widgetState[importLabel].commands.jumpToSelected or widgetState[importLabel].commands.collapseOther then
            ImGui.SetNextItemOpen(true)
        elseif widgetState[importLabel].commands.collapseAll then
            ImGui.SetNextItemOpen(false)
        end
    else
        if widgetState[importLabel].commands.collapseOther or widgetState[importLabel].commands.collapseAll then
            ImGui.SetNextItemOpen(false)
        elseif widgetState[importLabel].commands.openAll then
            ImGui.SetNextItemOpen(true)
        end
    end

    local isOpen = ImGui.TreeNodeEx(importName, flags)

    if ImGui.IsItemClicked() then
        widgetState[importLabel].selected = importName
    end

    if isOpen then
        if type(node) == "table" then
            ImGui.Columns(2, importLabel .. tostring(node))
            ImGui.SetColumnWidth(0, 20 * ImGuiExt.GetResolutionFactor())
            ImGui.Separator()
            ImGuiExt.TextAlt("#")
            ImGui.NextColumn()
            ImGuiExt.TextAlt("Entry")
            ImGui.NextColumn()

            for i, entry in ipairs(node) do
                ImGui.Separator()
                ImGuiExt.TextAltScale(tostring(i), 0.85)
                ImGui.NextColumn()

                local entryName = tostring(entry)

                ImGuiExt.TextAltScale(entryName, 0.85)

                if entryName then
                    local entryPos = ImVec2.new()
                    entryPos.x, entryPos.y = ImGui.GetCursorScreenPos()
                    entryPos.y = entryPos.y - ImGui.GetTextLineHeight() - (3 * ImGuiExt.GetResolutionFactor())
                    local entrySize  = ImVec2.new(entryPos.x + ImGui.GetColumnWidth(),
                                                    entryPos.y + ImGui.GetTextLineHeight() + 10)

                    if ImGuiExt.IsMouseHoverOverRegion(entryPos, entrySize) then
                        widgetState[importLabel].hovered = entryName

                        if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                            widgetState[importLabel].clicked = entryName
                        end
                    end
                end

                ImGui.NextColumn()
            end

            ImGui.Columns(1)
        else
            ImGui.Spacing()
            ImGuiExt.AlignNextItemToCenter(ImGui.CalcTextSize("Nothing to show."), contentRegionAvailX, 0)
            ImGuiExt.TextAlt("Nothing to show.")
            ImGui.Spacing()
        end

        ImGui.TreePop()
    end

    ImGui.PopStyleColor()

    if not widgetState[importLabel].isContextPopup then
        ImGuiExt.SetStatusBar(widgetState[importLabel].hovered)
    end
end

local function setFiltering(typeLabel, isEnabled)
    widgetState[typeLabel].filtering = isEnabled
end

local function handleFiltering(searchInstanceName, export, import, exportLabel, importLabel)
    if search.getFilterQuery(searchInstanceName) == "" then
        widgetState[exportLabel].pool = export
        widgetState[importLabel].pool = import
    else
        local exportNotCollapsed = widgetState[exportLabel].notCollapsed
        local importNotCollpased = widgetState[importLabel].notCollapsed
        local activeFilter = search.getActiveFilter()

        if exportNotCollapsed then
            setFiltering(importLabel, false)

            if not widgetState[exportLabel].filtering and not ImGuiExt.IsSearchInputTyped(activeFilter.label) then
                search.setFiltering(true)
                utils.SetDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
                setFiltering(exportLabel, true)
            end

            if ImGuiExt.IsSearchInputTyped(activeFilter.label) then
                search.setFiltering(true)
            end

            widgetState[exportLabel].pool = search.filter(searchInstanceName, export, search.getFilterQuery(searchInstanceName))
        elseif importNotCollpased then
            setFiltering(exportLabel, false)

            if not widgetState[importLabel].filtering and not ImGuiExt.IsSearchInputTyped(activeFilter.label) then
                search.setFiltering(true)
                utils.SetDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
                setFiltering(importLabel, true)

                widgetState[importLabel].commands.openAll = true
            end

            if ImGuiExt.IsSearchInputTyped(activeFilter.label) then
                search.setFiltering(true)

                widgetState[importLabel].commands.openAll = true
            end

            widgetState[importLabel].pool = search.filter(searchInstanceName, import, search.getFilterQuery(searchInstanceName))
        elseif not exportNotCollapsed or not importNotCollpased then
            setFiltering(exportLabel, false)
            setFiltering(importLabel, false)
        end
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
    local searchInstanceName = "GameModules.Module." .. onScreenName

    search.updateFilterInstance(searchInstanceName)

    if moduleData == nil then
        ImGui.Dummy(100, 120)
        local failInfo = "Can't open open module: " .. fileName
        ImGuiExt.AlignNextItemToCenter(ImGui.CalcTextSize(failInfo), windowWidth, windowPadding.x)
        ImGuiExt.TextAlt(failInfo)
        ImGui.Dummy(100, 120)
        return
    end

    local moduleTabLabel = "GameModules.ModuleTab." .. onScreenName

    ImGui.BeginChildFrame(ImGui.GetID(moduleTabLabel),
                            itemWidth,
                            656 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)

    local opened = modules.data[onScreenName] or {}
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local labelWidth = ImGui.CalcTextSize("TimeDateStamp (UTC)") + 6 * ImGuiExt.GetResolutionFactor()
    local buttonWidth = (contentRegionAvailX - ImGui.GetStyle().ItemSpacing.x) / 2

    if not ImGuiExt.IsSearchInputActive(search.getActiveFilter().label) and
        search.getFilterQuery(searchInstanceName) == "" then

        drawViewerRow("Version", opened["Version"], contentRegionAvailX, labelWidth)
        drawViewerRow("Description", opened["Description"], contentRegionAvailX, labelWidth)
        drawViewerRow("Company Name", opened["Company Name"], contentRegionAvailX, labelWidth)
        drawViewerRow("TimeDateStamp (UTC)", opened["TimeDateStamp"], contentRegionAvailX, labelWidth)
        ImGui.Separator()
        drawViewerRow("File Type", opened["File Type"], contentRegionAvailX, labelWidth)
        drawViewerRow("File Path", opened["File Path"], contentRegionAvailX, labelWidth)
        drawViewerRow("File Size", opened["File Size"], contentRegionAvailX, labelWidth)
        ImGui.Separator()
        drawViewerRow("Entry Point", opened["Entry Point"], contentRegionAvailX, labelWidth)
        drawViewerRow("Load Address", opened["Load Address"], contentRegionAvailX, labelWidth)
        drawViewerRow("Mapped Size", opened["Mapped Size"], contentRegionAvailX, labelWidth)
        ImGui.Separator()
        ImGui.Spacing()
    end

    local exportLabel = onScreenName .. ".Export"
    local importLabel = onScreenName .. ".Import"

    if widgetState[exportLabel] == nil then
        widgetState[exportLabel] = {
            clicked = "",
            filtering = false,
            hovered = "",
            isContextPopup = false,
            jumpToHeader = false,
            notCollapsed = false,
            open = false,
            pool = {}
        }

        widgetState[importLabel] = {
            clicked = "",
            commands = {},
            filtering = false,
            hovered = "",
            isContextPopup = false,
            notCollapsed = false,
            open = false,
            pool = {},
            selected = ""
        }
    end

    handleFiltering(searchInstanceName,  opened["Export"], opened["Import"], exportLabel, importLabel)

    if widgetState[exportLabel].hovered == "" and
        widgetState[importLabel].hovered == "" and
        not widgetState[exportLabel].isContextPopup and
        not widgetState[importLabel].isContextPopup then
            
        ImGuiExt.ResetStatusBar()
    end

    widgetState[exportLabel].hovered = ""
    widgetState[importLabel].hovered = ""

    if not widgetState[exportLabel].open then
        ImGui.SetNextItemOpen(false)
    else
        ImGui.SetNextItemOpen(true)
    end

    widgetState[exportLabel].notCollapsed = ImGui.CollapsingHeader("Export", ImGuiTreeNodeFlags.Selected)
    widgetState[exportLabel].open = widgetState[exportLabel].notCollapsed

    if widgetState[exportLabel].jumpToHeader then
        ImGui.SetScrollHereY()

        widgetState[exportLabel].jumpToHeader = false
    end

    if widgetState[exportLabel].notCollapsed then
        widgetState[importLabel].open = false
        local export = widgetState[exportLabel].pool

        if next(export) then
            ImGui.BeginGroup()
            drawExportTable(exportLabel, export, itemWidth)
            ImGui.EndGroup()
            drawPopupContextExportTable(exportLabel,
                                        widgetState[exportLabel].clicked,
                                        widgetState[exportLabel].clicked,
                                        "Value")
            ImGui.Spacing()

            if ImGui.Button(IconGlyphs.ArrowUp .. " " .. "Jump To Start", buttonWidth, 0) then
                widgetState[exportLabel].jumpToHeader = true
            end

            ImGui.SameLine()

            if ImGui.Button(IconGlyphs.ArrowCollapseUp .. " " .. "Collapse Export", buttonWidth, 0) then
                widgetState[exportLabel].open = false
            end
        else
            ImGui.BeginGroup()
            ImGui.Spacing()
            ImGuiExt.AlignNextItemToCenter(ImGui.CalcTextSize("Nothing to show."), contentRegionAvailX, 0)
            ImGuiExt.TextAlt("Nothing to show.")
            ImGui.Spacing()
            ImGui.EndGroup()
        end

        ImGui.Spacing()
    end

    if not widgetState[importLabel].open then
        ImGui.SetNextItemOpen(false)
    else
        ImGui.SetNextItemOpen(true)
    end

    widgetState[importLabel].notCollapsed = ImGui.CollapsingHeader("Import", ImGuiTreeNodeFlags.Selected)
    widgetState[importLabel].open = widgetState[importLabel].notCollapsed

    if widgetState[importLabel].commands.jumpToHeader then
        ImGui.SetScrollHereY()

        widgetState[importLabel].commands.jumpToHeader = false
    end

    if widgetState[importLabel].notCollapsed then
        widgetState[exportLabel].open = false
        local import = widgetState[importLabel].pool

        if next(import) then
            ImGui.BeginGroup()

            local sortedKeys = tables.assignKeysOrder(import)

            for _, k in ipairs(sortedKeys) do
                local v = import[k]

                drawImportTreeNode(v, tostring(k), importLabel)
            end

            if ImGui.Button(IconGlyphs.ArrowUp .. " " .. "Jump To Start", buttonWidth, 0) then
                widgetState[importLabel].commands.jumpToHeader = true
            end

            ImGui.SameLine()

            if ImGui.Button(IconGlyphs.ArrowCollapseUp .. " " .. "Collapse Import", buttonWidth, 0) then
                widgetState[importLabel].open = false
            end

            ImGui.EndGroup()
        
            widgetState[importLabel].commands.jumpToSelected = false
            widgetState[importLabel].commands.collapseOther = false
            widgetState[importLabel].commands.collapseAll = false
            widgetState[importLabel].commands.openAll = false

            drawPopupContextImportTreeNode(importLabel,
                                            widgetState[importLabel].clicked,
                                            widgetState[importLabel].clicked,
                                            "Value")
        else
            ImGui.BeginGroup()
            ImGui.Spacing()
            ImGuiExt.AlignNextItemToCenter(ImGui.CalcTextSize("Nothing to show."), contentRegionAvailX, 0)
            ImGuiExt.TextAlt("Nothing to show.")
            ImGui.Spacing()
            ImGui.EndGroup()
        end
    end

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

    search.updateFilterInstance("GameModules.Root")

    if search.getFilterQuery("GameModules.Root") == "" then
        modules.filtered = modules.loaded
    else
        if ImGuiExt.IsSearchInputTyped(search.getActiveFilter().label) then
            search.setFiltering(true)
        end

        modules.filtered = search.filter("GameModules.Root", modules.loaded, search.getFilterQuery("GameModules.Root"))
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