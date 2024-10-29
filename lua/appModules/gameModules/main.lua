local app = ...

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

local widgetState = {
    __global = {
        exportTableItemsPerPage = function()
            return settings.getUserSetting("gameModules", "exportTableItemsPerPage") or 500
        end,
        importNodesCharThreshold = function()
            return settings.getUserSetting("gameModules", "importNodesCharThreshold") or 3
        end,
    },
    modulesList = {
        regionPos = {}
    }
}

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

local function isModsResource(normalizedPath, modsResourcesSet)
    for resourcePath in pairs(modsResourcesSet) do
        if normalizedPath:sub(-#resourcePath) == resourcePath then
            return true
        end
    end

    return false
end

local function isNativeModule(normalizedPath, nativeSet)
    for nativePath in pairs(nativeSet) do
        if normalizedPath:sub(-#nativePath) == nativePath then
            return true
        end
    end

    return false
end

local function categorizeModules(loadedModules)
    if loadedModules == nil then return {} end

    local modsResourcesTable = modsResources.getTable()
    local nativeTable = native.getTable()
    local redmodTable = redmod.getTable()
    local modsResourcesSet = {}
    local nativeSet = {}
    local redmodSet = {}

    intializeCategoriesCount()

    modules.count.all = #loadedModules

    for _, v in ipairs(nativeTable) do nativeSet[utils.normalizePath(v)] = true end
    for _, v in ipairs(redmodTable) do redmodSet[utils.normalizePath(v)] = true end

    for _, path in pairs(modsResourcesTable) do
        modsResourcesSet[utils.normalizePath(path):lower()] = true
    end
  
    for _, module in ipairs(loadedModules) do
        local normalizedPath = module.normalizedPath:lower()
        
        if module.normalizedPath:find("windows") then
            module.category = "system"
            modules.count["system"] = modules.count["system"] + 1
        elseif isNativeModule(normalizedPath, nativeSet) then
            module.category = "native"
            modules.count["native"] = modules.count["native"] + 1
        elseif isNativeModule(normalizedPath, redmodSet) then
            module.category = "redmod"
            modules.count["redmod"] = modules.count["redmod"] + 1
        elseif isModsResource(normalizedPath, modsResourcesSet) then
            module.category = "mods resource"
            modules.count["mods resource"] = modules.count["mods resource"] + 1
        else
            module.category = "mod / unknown"
            modules.count["mod / unknown"] = modules.count["mod / unknown"] + 1
        end
    end
    
    logger.debug(modules.count.all, "Categorized loaded modules.")

    return loadedModules
end

local function getModules()
    local loadedPaths = GameModules and GameModules.GetLoadedModules() or nil

    if not loadedPaths then
        logger.warning("Install Cyberlibs RED4ext Plugin.")

        return {}
    end

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

local function getCategorizedModules()
    return categorizeModules(getModules())
end

local function refreshLoadedModules()
    modules.data = {}
    modules.loaded = getCategorizedModules()
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
        ["Company Name"] = GameModules.GetCompanyName(filePath),
        ["Description"] = GameModules.GetDescription(filePath),
        ["Entry Point"] = GameModules.GetEntryPoint(filePath),
        ["Export"] = {},
        ["File Name"] = fileName,
        ["File Path"] = filePath,
        ["File Size"] = GameModules.GetFileSize(filePath),
        ["File Type"] = GameModules.GetFileType(filePath),
        ["Import"] = {},
        ["Load Address"] = GameModules.GetLoadAddress(filePath),
        ["Mapped Size"] = GameModules.GetMappedSize(filePath),
        ["TimeDateStamp"] = GameModules.GetTimeDateStamp(filePath),
        ["Version"] = Cyberlibs.GetVersion(filePath)
    }
    
    local exportStruct = GameModules.GetExport(filePath)

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

    local importStruct = GameModules.GetImport(filePath)

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

    value = value or "-"
    
    ImGui.InputText("##" .. label, tostring(value), 256)

    if ImGui.BeginPopupContextItem(label, ImGuiPopupFlags.MouseButtonRight) then
        ImGuiExt.MenuItemCopyValue(value, "Value")
        ImGui.EndPopup()
    end

    ImGui.EndGroup()
end

local function drawTableCellTooltip(text)
    ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor("text"))
    ImGuiExt.SetTooltip(text)
    ImGui.PopStyleColor()
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

        local pages = widgetState[exportLabel].pages

        ImGui.BeginDisabled(pages.currentPage <= 0)

        if ImGui.MenuItem(ImGuiExt.TextIcon("Previous Page", IconGlyphs.ArrowLeft)) then
            if pages.currentPage > 0 then
                pages.currentPage = pages.currentPage - 1
            end
    
            print(pages.currentPage)
        end

        ImGui.EndDisabled()
        ImGui.BeginDisabled(pages.currentPage >= pages.count - 1)

        if ImGui.MenuItem(ImGuiExt.TextIcon("Next Page", IconGlyphs.ArrowRight)) then
            if pages.currentPage < pages.count - 1 then
                pages.currentPage = pages.currentPage + 1
            end
    
            print(pages.currentPage)
        end

        ImGui.EndDisabled()
        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Jump To Start", IconGlyphs.ArrowUp)) then
            widgetState[exportLabel].jumpToHeader = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse Export", IconGlyphs.ArrowCollapseUp)) then
            widgetState[exportLabel].open = false
        end

        ImGui.EndPopup()
    end
end

local function drawPaginationButtonsExportTable(exportLabel, buttonWidth, occurenceNumber)
    local pages = widgetState[exportLabel].pages
    occurenceNumber = occurenceNumber - 1
    local dummySpaces = string.rep(" ", occurenceNumber)

    ImGui.BeginGroup()
    ImGui.BeginDisabled(pages.currentPage <= 0)

    if ImGui.Button(dummySpaces .. IconGlyphs.ArrowLeft .. " " .. "Previous Page" .. dummySpaces, buttonWidth, 0) then
        if pages.currentPage > 0 then
            pages.currentPage = pages.currentPage - 1
        end
    end

    ImGui.EndDisabled()
    ImGui.SameLine()
    ImGui.BeginDisabled(pages.currentPage >= pages.count - 1)

    if ImGui.Button(dummySpaces .. IconGlyphs.ArrowRight .. " " .. "Next Page" .. dummySpaces, buttonWidth, 0) then
        if pages.currentPage < pages.count - 1 then
            pages.currentPage = pages.currentPage + 1
        end
    end

    ImGui.EndDisabled()
    ImGui.EndGroup()
end

local function drawExportTable(exportLabel, export, startPos, itemWidth)
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

    for _, entry in ipairs(export) do
        local entryName = tostring(entry.entry)
        local ordinal = tostring(entry.ordinal)
        local rva = tostring(entry.rva)
        local forwarder = tostring(entry.forwarderName)
        local summary = entryName .. ", Ordinal: " .. ordinal .. ", RVA: " .. rva .. ", Forwarder: " .. forwarder

        ImGui.Separator()
        ImGuiExt.TextAltScale(tostring(startPos), 0.85, true)
        local itemSpacing = ImGui.GetStyle().ItemSpacing
        local textHeight = ImGui.GetTextLineHeight()
        local cellHeight = textHeight + itemSpacing.y

        startPos = startPos + 1

        local summaryPos = ImVec2.new()
        summaryPos.x, summaryPos.y = ImGui.GetCursorScreenPos()
        summaryPos.y = summaryPos.y - cellHeight
        local summarySize  = ImVec2.new(summaryPos.x + ImGui.GetColumnWidth(),
                                        summaryPos.y + cellHeight)

        if ImGuiExt.IsMouseHoverOverRegion(summaryPos, summarySize) then
            widgetState[exportLabel].hovered = summary

            drawTableCellTooltip(summary)

            if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                widgetState[exportLabel].clicked = summary
            end
        end

        ImGui.NextColumn()
        ImGuiExt.TextAltScale(entryName, 0.85)

        if entryName then
            local entryPos = ImVec2.new()
            entryPos.x, entryPos.y = ImGui.GetCursorScreenPos()
            entryPos.y = entryPos.y - cellHeight
            local entrySize  = ImVec2.new(entryPos.x + ImGui.GetColumnWidth(),
                                            entryPos.y + cellHeight)

            if ImGuiExt.IsMouseHoverOverRegion(entryPos, entrySize) then
                widgetState[exportLabel].hovered = entryName

                drawTableCellTooltip(entryName)

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
            ordinalPos.y = ordinalPos.y - cellHeight
            local ordinalSize  = ImVec2.new(ordinalPos.x + ImGui.GetColumnWidth(),
                                            ordinalPos.y + cellHeight)

            if ImGuiExt.IsMouseHoverOverRegion(ordinalPos, ordinalSize) then
                widgetState[exportLabel].hovered = ordinal

                drawTableCellTooltip(ordinal)

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
            rvaPos.y = rvaPos.y - cellHeight
            local rvaSize  = ImVec2.new(rvaPos.x + ImGui.GetColumnWidth(),
                                        rvaPos.y + cellHeight)

            if ImGuiExt.IsMouseHoverOverRegion(rvaPos, rvaSize) then
                widgetState[exportLabel].hovered = rva

                drawTableCellTooltip(rva)

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
            forwarderPos.y = forwarderPos.y - cellHeight
            local forwarderSize  = ImVec2.new(forwarderPos.x + ImGui.GetColumnWidth(),
                                                forwarderPos.y + cellHeight)

            if ImGuiExt.IsMouseHoverOverRegion(forwarderPos, forwarderSize) then
                widgetState[exportLabel].hovered = forwarder

                drawTableCellTooltip(forwarder)

                if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                    widgetState[exportLabel].clicked = forwarder
                end
            end
        end

        ImGui.NextColumn()
    end

    ImGui.Columns(1)

    local dummyPos = ImVec2.new()
    dummyPos.x, dummyPos.y = ImGui.GetCursorScreenPos()
    local dummySize  = ImVec2.new(dummyPos.x + itemWidth,
                                        dummyPos.y + 10)

    if ImGuiExt.IsMouseHoverOverRegion(dummyPos, dummySize) then
        widgetState[exportLabel].hovered = ""

        if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
            widgetState[exportLabel].clicked = ""
        end
    end

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

        if ImGui.MenuItem(ImGuiExt.TextIcon("Jump To Selection", IconGlyphs.ArrowTopLeft)) then
            widgetState[importLabel].commands.jumpToSelected = true
        end

        if ImGui.MenuItem(ImGuiExt.TextIcon("Jump To Start", IconGlyphs.ArrowUp)) then
            widgetState[importLabel].commands.jumpToHeader = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse Others", IconGlyphs.MinusBoxMultipleOutline)) then
            widgetState[importLabel].commands.collapseOther = true
        end

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse All", IconGlyphs.CollapseAllOutline)) then
            widgetState[importLabel].commands.collapseAll = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse Import", IconGlyphs.ArrowCollapseUp)) then
            widgetState[importLabel].open = false
        end

        ImGui.EndPopup()
    end
end

local function drawImportTreeNode(node, importName, importLabel)
    local flags = ImGuiTreeNodeFlags.SpanFullWidth
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("textAlt")
    local shouldOpen

    if not widgetState[importLabel].isContextPopup then
        local rectPos = ImVec2.new()
        rectPos.x, rectPos.y = ImGui.GetCursorScreenPos()
        local rectSize = ImVec2.new(rectPos.x + contentRegionAvailX, rectPos.y + ImGui.GetTextLineHeight() - 10)

        if ImGuiExt.IsMouseHoverOverRegion(rectPos, rectSize) then
            widgetState[importLabel].hovered = importName

            if ImGui.IsMouseClicked(ImGuiMouseButton.Right) then
                textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("text")
                widgetState[importLabel].clicked = importName
            end
        end
    end

    ImGui.PushStyleColor(ImGuiCol.Text, textRed, textGreen, textBlue, textAlpha)

    if importName == widgetState[importLabel].selected then
        flags = flags + ImGuiTreeNodeFlags.Selected
        shouldOpen = true
        textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("text")
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

                        drawTableCellTooltip(entryName)

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
                utils.setDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
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
                utils.setDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
                setFiltering(importLabel, true)
                local openNodesCharThershold = widgetState.__global.importNodesCharThreshold()

                if #search.getFilterQuery(searchInstanceName) > openNodesCharThershold then
                    widgetState[importLabel].commands.openAll = true
                else
                    widgetState[importLabel].commands.collapseAll = true
                end
            end

            if ImGuiExt.IsSearchInputTyped(activeFilter.label) then
                search.setFiltering(true)
                local openNodesCharThershold = widgetState.__global.importNodesCharThreshold()

                if #search.getFilterQuery(searchInstanceName) > openNodesCharThershold then
                    widgetState[importLabel].commands.openAll = true
                else
                    widgetState[importLabel].commands.collapseAll = true
                end
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
            pages = {
                allItems = 0,
                count = 1,
                currentPage = 0,
                startPos = 1,
            },
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
        local pages = widgetState[exportLabel].pages

        if next(export) then
            local itemsPerPage = widgetState.__global.exportTableItemsPerPage()
            pages.allItems = #export
            pages.count = math.floor((pages.allItems / itemsPerPage) + 0.5)
            pages.startPos = pages.currentPage * itemsPerPage + 1
            local exportShowed = {}
            local itemsExtracted = math.min(itemsPerPage, pages.allItems - pages.startPos + 1)
            
            for i = 1, itemsExtracted do
                exportShowed[i] = export[pages.startPos + i - 1]
            end

            if pages.count > 1 then
                drawPaginationButtonsExportTable(exportLabel, buttonWidth, 1)
            end

            ImGui.BeginGroup()
            drawExportTable(exportLabel, exportShowed, pages.startPos, itemWidth)
            ImGui.EndGroup()
            drawPopupContextExportTable(exportLabel,
                                        widgetState[exportLabel].clicked,
                                        widgetState[exportLabel].clicked,
                                        "Value")
            ImGui.Spacing()

            if pages.count > 1 then
                drawPaginationButtonsExportTable(exportLabel, buttonWidth, 2)
                ImGui.Spacing()
            end

            if ImGui.Button(ImGuiExt.TextIcon("Jump To Start", IconGlyphs.ArrowUp), buttonWidth, 0) then
                widgetState[exportLabel].jumpToHeader = true
            end

            ImGui.SameLine()

            if ImGui.Button(ImGuiExt.TextIcon("Collapse Export", IconGlyphs.ArrowCollapseUp), buttonWidth, 0) then
                widgetState[exportLabel].open = false
            end

            ImGui.Spacing()
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

            if ImGui.Button(ImGuiExt.TextIcon("Jump To Start", IconGlyphs.ArrowUp), buttonWidth, 0) then
                widgetState[importLabel].commands.jumpToHeader = true
            end

            ImGui.SameLine()

            if ImGui.Button(ImGuiExt.TextIcon("Collapse Import", IconGlyphs.ArrowCollapseUp), buttonWidth, 0) then
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
    if ImGui.IsPopupOpen("GameModules.SelectedModule.PopupMenu") then
        widgetState.__global.isContextPopup = true
    else
        widgetState.__global.isContextPopup = false
    end

    ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor("text"))

    if ImGui.BeginPopup("GameModules.SelectedModule.PopupMenu") then
        if ImGui.MenuItem(ImGuiExt.TextIcon("Show in new tab", IconGlyphs.OpenInNew)) then
            addModuleTab(onScreenName, fileName, filePath)
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Copy File Name", IconGlyphs.ContentCopy)) then
            ImGui.SetClipboardText(fileName)
        end

        if ImGui.MenuItem(ImGuiExt.TextIcon("Copy File Path", IconGlyphs.ContentCopy)) then
            ImGui.SetClipboardText(filePath)
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Refresh List", IconGlyphs.Refresh)) then
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

local function draw()
    local scaleFactor = ImGuiExt.GetScaleFactor()
    local textHeight = ImGui.GetTextLineHeight()
    local windowWidth = ImGui.GetWindowWidth()
    local windowPaddingX = ImGui.GetStyle().WindowPadding.x
    local framePaddingX = ImGui.GetStyle().FramePadding.x
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    local scrollbarSize = ImGui.GetStyle().ScrollbarSize
    local itemWidth = windowWidth - 2 * windowPaddingX
    local cellHeight = textHeight + itemSpacing.y
    local regionPos = {} -- widgetState.modulesList.regionPos

    search.updateFilterInstance("GameModules.Root")

    if search.getFilterQuery("GameModules.Root") == "" then
        modules.filtered = modules.loaded
    else
        if ImGuiExt.IsSearchInputTyped(search.getActiveFilter().label) then
            search.setFiltering(true)
        end

        modules.filtered = search.filter("GameModules.Root", modules.loaded, search.getFilterQuery("GameModules.Root"))
    end

    local itemColumnWidth = itemWidth / 2 + (scrollbarSize / 2)

    ImGui.Columns(2, "##GameModules.LoadedModules.ListHeader")
    ImGui.SetColumnWidth(0, itemColumnWidth)
    ImGui.Separator()
    ImGuiExt.TextTitle("Module", 1, true)
    ImGui.NextColumn()
    ImGuiExt.TextTitle("Category", 1, true)
    ImGui.NextColumn()
    ImGui.Separator()
    ImGui.Columns(1)
    ImGui.BeginChildFrame(ImGui.GetID("GameModules.LoadedModules.List"), itemWidth,
                                                                        320 * scaleFactor,
                                                                        ImGuiWindowFlags.NoBackground)

    ImGui.Columns(2, "##GameModules.LoadedModules.List")
    ImGui.SetColumnWidth(0, itemColumnWidth - windowPaddingX)

    for _, module in ipairs(modules.filtered) do
        if modules.selected[module.onScreenName] == nil then
            modules.selected[module.onScreenName] = false
        end

        regionPos.x, regionPos.y = ImGui.GetCursorScreenPos()
        regionPos.y = regionPos.y - (itemSpacing.y / 2)
        local regionSize = ImVec2.new(itemWidth, cellHeight)

        if modules.selected[module.onScreenName] == true or
            not widgetState.__global.isContextPopup and ImGuiExt.IsMouseHoverOverRegion(regionPos, regionSize) then

            ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor("text"))
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImGuiExt.GetActiveThemeColor("textAlt"))
        end

        if ImGui.Selectable(module.onScreenName, modules.selected[module.onScreenName],
                                                ImGuiSelectableFlags.SpanAllColumns) then
            selectModule(module.onScreenName, module.fileName, module.filePath)
        end

        ImGui.NextColumn()
        ImGui.Text(module.category)
        ImGui.NextColumn()
        ImGui.PopStyleColor()

        if modules.selected[module.onScreenName] == true then
            handleSelectedModule(regionPos, regionSize, module.onScreenName, module.fileName, module.filePath)
        else
            handleHoveredModule(regionPos, regionSize, module.onScreenName, module.fileName, module.filePath)
        end
    end

    ImGui.Columns(1)
    ImGui.EndChildFrame()
    ImGui.Separator()
    ImGui.Spacing()
    ImGui.Indent(framePaddingX)

    local contentRegionAvailX = ImGui.GetContentRegionAvail()

    if next(modules.count) then
        if ImGui.SmallButton("total: " .. modules.count.all) then
            search.serFilterQuery("GameModules.Root", "")
        end

        local countBarWidth = ImGui.GetItemRectSize()

        ImGui.SameLine()

        if ImGui.SmallButton("system: " .. modules.count["system"]) then
            search.serFilterQuery("GameModules.Root", "system")
            search.setFiltering(true)
        end

        countBarWidth = countBarWidth + ImGui.GetItemRectSize()

        ImGui.SameLine()

        if ImGui.SmallButton("native: " .. modules.count["native"]) then
            search.serFilterQuery("GameModules.Root", "native")
            search.setFiltering(true)
        end

        countBarWidth = countBarWidth + ImGui.GetItemRectSize()

        ImGui.SameLine()

        if ImGui.SmallButton("redmod: " .. modules.count["redmod"]) then
            search.serFilterQuery("GameModules.Root", "redmod")
            search.setFiltering(true)
        end

        countBarWidth = countBarWidth + ImGui.GetItemRectSize()

        ImGui.SameLine()

        if ImGui.SmallButton("mods resource: " .. modules.count["mods resource"]) then
            search.serFilterQuery("GameModules.Root", "mods resource")
            search.setFiltering(true)
        end

        countBarWidth = countBarWidth + ImGui.GetItemRectSize()

        if countBarWidth < contentRegionAvailX * 0.7 then
            ImGui.SameLine()
        end

        if ImGui.SmallButton("mod / unknown: " .. modules.count["mod / unknown"]) then
            search.serFilterQuery("GameModules.Root", "mod / unknown")
            search.setFiltering(true)
        end
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    local previewed = modules.data[modules.previewed] or {}
    local labelWidth = ImGui.CalcTextSize("TimeDateStamp (UTC)") + 6 * ImGuiExt.GetResolutionFactor() + windowPaddingX

    drawViewerRow("File Name", previewed["File Name"], contentRegionAvailX, labelWidth)
    drawViewerRow("Version", previewed["Version"], contentRegionAvailX, labelWidth)
    drawViewerRow("Description", previewed["Description"], contentRegionAvailX, labelWidth)
    drawViewerRow("File Path", previewed["File Path"], contentRegionAvailX, labelWidth)
    drawViewerRow("Entry Point", previewed["Entry Point"], contentRegionAvailX, labelWidth)
    drawViewerRow("Load Address", previewed["Load Address"], contentRegionAvailX, labelWidth)
    drawViewerRow("Mapped Size", previewed["Mapped Size"], contentRegionAvailX, labelWidth)
    ImGui.Indent(-framePaddingX)
    ImGui.Spacing()
end

local function drawSettings()
    local itemsPerPage, itemsPerPageToggle
    local charThreshold, charThresholdToggle
    
    ImGui.SetNextItemWidth(200 * ImGuiExt.GetScaleFactor())

    itemsPerPage, itemsPerPageToggle = ImGui.SliderFloat("##itemsPerPage", widgetState.__global.exportTableItemsPerPage(), 100, 2000, "%.0f")

    ImGuiExt.SetTooltip("Higher values may cause a noticeable performance hit when inspecting a module.")
    ImGui.SameLine()
    ImGuiExt.TextAlt("Module export table entries per page")
    
    if itemsPerPageToggle then
        settings.setUserSetting("gameModules", "exportTableItemsPerPage", itemsPerPage)
    end

    ImGui.SetNextItemWidth(200 * ImGuiExt.GetScaleFactor())

    charThreshold, charThresholdToggle = ImGui.SliderFloat("##charThreshold", widgetState.__global.importNodesCharThreshold(), 0, 10, "%.0f")
    
    ImGuiExt.SetTooltip("Lower values may cause a noticeable performance hit when inspecting a module.")
    ImGui.SameLine()
    ImGuiExt.TextAlt("Search query characters number to open import nodes")

    if charThresholdToggle then
        settings.setUserSetting("gameModules", "importNodesCharThreshold", charThreshold)
    end
end

local events = {}

function events.onInit()
    if not app.isCyberlibsDLL() then
        logger.warning("Install Cyberlibs RED4ext Plugin.")
    end
end

function events.onOverlayOpen()
    refreshLoadedModules()
end

return {
    __NAME = "Game Modules",
    __ICON = IconGlyphs.Bookshelf,
    appApi = {
        addModuleTab = addModuleTab,
        getCategorizedModules = getCategorizedModules,
        getLoadedModules = getModules
    },
    draw = draw,
    drawSettings = drawSettings,
    events = events
}

-- return {
--     __NAME = "Exemplary AppModule", -- required
--     __ICON = IconGlyphs.Bookshelf, -- optional
--     __VERSION = { 0, 1, 0}, -- optional
--     __TITLE = "Tab Title", -- optional
--     appApi = {
--         privateFunction = privateFunction
--     }, -- optional
--     publicApi = {
--         exposedFunction = exposedFunction,
--     }, -- optional
--     draw = draw, -- required
--     drawSettings = drawSettings, -- optional
--     events = {}, -- optional, functions named: onInit, onOverlayOpen, onOverlayClose, onUpdate, onDraw
--     inputs = {
--         { id = "exampleInput", description = "Describe Action", keyPressCallback = functionOnKeyPress, keyReleaseCallback = functionOnKeyRelease },
--     } -- optional
-- }