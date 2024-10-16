Cyberlibs = {
    __NAME = "Cyberlibs",
    __EDITION = nil,
    __VERSION = { 0, 2, 0},
    __VERSION_SUFFIX = "",
    __VERSION_STATUS = "alpha",
    __DESCRIPTION = "Diagnostics tool to inspect and parse libraries loaded by Cyberpunk 2077 during runtime.",
    __LICENSE =
        [[
        MIT License

        Copyright (c) 2024 gramern, https://github.com/gramern

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        ]]
}

local isRootWindow = false

------------------
-- Globals
------------------

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local settings = require("globals/settings")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- Knowledge Base
------------------

local help = require("knowledgeBase/help")

------------------
-- API
------------------

local publicApi = require("api/publicApi")

local appApi = {}

------------------
-- App Modules
------------------

local appModules = {}

local function verifyAppModule(path)
    local folderDir = dir(path)

    for _, file in pairs(folderDir) do
        if string.find(file.name, "main.lua$") then
            local modulePath = path .. "/main.lua"
            local moduleFile = loadfile(modulePath)(appApi)

            if moduleFile ~= nil and
                    moduleFile.__NAME and
                    moduleFile.__TITLE and
                    moduleFile.draw and
                    type(moduleFile.draw) == "function" then

                return moduleFile
            end
        end
    end
end

local function loadAppModules()
    local modulesDir = dir("appModules")

    for _, folder in pairs(modulesDir) do
        if not string.find(folder.name, "rootWindow$") then
            local folderPath = "appModules/" .. folder.name
            local loadedModule = verifyAppModule(folderPath)

            if loadedModule ~= nil then
                appModules[folder.name] = loadedModule
                logger.debug("Added app module:", folder.name)
            else
                logger.debug("App module discarded:", folder.name)
            end
        end
    end
end

------------------
-- Root Window
------------------

local tabAbout = {
    pluginVersion = "",
    luaGuiVersion = "",
    licenses = ""
}

local tabHelp = {
    selectedTopic = "",
    selectedTopicContent = "",
    topicsPool = {},
    commands = {},
    states = {}
}

local function initializeModSettings()
    local appSettings = {
        tooltips = true,
        tabBarPopup = true,
        tabCloseOnMiddleButtonClick = false
    }

    for setting, value in pairs(appSettings) do
        if settings.getModSetting(setting) == nil then
            settings.setModSetting(setting, value)
        end
    end
end

local function openTabGameModules()
    local gameModules = appModules.gameModules
    local tabBarLabel = "RootWindow.TabBar"

    if gameModules ~= nil and ImGuiExt.GetActiveTabLabel(tabBarLabel) == "" then
        ImGuiExt.AddTab(tabBarLabel, gameModules.__NAME, gameModules.__TITLE, gameModules.draw)
    end
end

local function drawTabAbout()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x

    ImGuiExt.TextAlt("Plugin Version:")
    ImGui.SameLine()
    ImGuiExt.TextAlt(tabAbout.pluginVersion)
    ImGuiExt.TextAlt("Lua GUI Version:")
    ImGui.SameLine()
    ImGuiExt.TextAlt(tabAbout.luaGuiVersion)
    ImGui.Text("")
    ImGuiExt.TextAlt("License & Third Party")

    ImGui.BeginChildFrame(ImGui.GetID("HelpTopicView"),
                            itemWidth,
                            300 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.AlwaysHorizontalScrollbar)
    ImGui.Text(tabAbout.licenses)
    ImGui.EndChildFrame()

    if tabAbout.pluginVersion ~= "" then return end
    tabAbout.pluginVersion = Cyberlibs.Version()
    tabAbout.luaGuiVersion = Cyberlibs.Version()
    local thirdparty = loadfile("thirdparty")

    if thirdparty ~= nil then
        tabAbout.licenses = utils.indentString(Cyberlibs.__LICENSE .. "\n" .. thirdparty(), -20, true)
    else
        tabAbout.licenses = utils.indentString(Cyberlibs.__LICENSE, -20, true)
    end
end

local function drawHelpTreeNode(node, name, depth, nodePath)
    depth = depth or 0
    nodePath = nodePath or name
    local flags = ImGuiTreeNodeFlags.SpanFullWidth
    local nodeType = type(node)
    local isLeaf = nodeType ~= "table" or next(node) == nil
    local textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('textAlt')

    if isLeaf then
        flags = flags + ImGuiTreeNodeFlags.Leaf

        if nodePath == tabHelp.selectedTopic then
            flags = flags + ImGuiTreeNodeFlags.Selected
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
        end
    end

    if not tabHelp.states.isTreeContextPopup then
        local rectMin = ImVec2.new()
        rectMin.x, rectMin.y = ImGui.GetCursorScreenPos()
        local contentRegionAvailX = ImGui.GetContentRegionAvail()
        local rectMax = ImVec2.new(rectMin.x + contentRegionAvailX, rectMin.y + ImGui.GetFrameHeight())

        if ImGui.IsMouseHoveringRect(rectMin.x, rectMin.y, rectMax.x, rectMax.y - 10) then
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
        end
    end

    ImGui.PushStyleColor(ImGuiCol.Text, textRed, textGreen, textBlue, textAlpha)

    local shouldOpen = string.find(tabHelp.selectedTopic, "^" .. nodePath .. "%.")

    if tabHelp.commands.jumpToSelected and nodePath == tabHelp.selectedTopic then
        ImGui.SetScrollHereY()
    end

    if not isLeaf then
        if shouldOpen then
            if tabHelp.commands.jumpToSelected then
                ImGui.SetNextItemOpen(true)
            elseif tabHelp.commands.collapseAll then
                ImGui.SetNextItemOpen(false)
            end
        else
            if tabHelp.commands.collapseOther or tabHelp.commands.collapseAll then
                ImGui.SetNextItemOpen(false)
            elseif tabHelp.commands.openAll then
                ImGui.SetNextItemOpen(true)
            end
        end
    end

    local isOpen = ImGui.TreeNodeEx(name .. "##" .. tostring(depth), flags)

    if ImGui.IsItemClicked() and isLeaf then
        tabHelp.selectedTopic = nodePath
        tabHelp.selectedTopicContent = utils.indentString(node, -20, true)
    end

    if isOpen then
        if nodeType == "table" then
            local sortedKeys = tables.assignKeysOrder(node)

            for _, k in ipairs(sortedKeys) do
                local v = node[k]
                local childPath = nodePath .. "." .. tostring(k)

                if type(v) == "table" then
                    drawHelpTreeNode(v, tostring(k), depth + 1, childPath)
                else
                    drawHelpTreeNode(tostring(v), tostring(k), depth + 1, childPath)
                end
            end
        end

        ImGui.TreePop()
    end

    ImGui.PopStyleColor()
end

local function drawTabHelp()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x

    ImGui.BeginChildFrame(ImGui.GetID("RootWindow.Help.TopicsTree"),
                            itemWidth,
                            200 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.HorizontalScrollbar +
                            ImGuiWindowFlags.NoBackground)

    if search.getFilterQuery("Help") == "" then
        tabHelp.topicsPool = help.getTable()
    else
        if search.isFiltering() then
            tabHelp.topicsPool = search.filter(help.getTable(), search.getFilterQuery("Help"))
            tabHelp.commands.openAll = true
        end
    end

    local sortedKeys = tables.assignKeysOrder(tabHelp.topicsPool)

    for _, k in ipairs(sortedKeys) do
        local v = tabHelp.topicsPool[k]

        drawHelpTreeNode(v, tostring(k), 0, tostring(k))
    end

    tabHelp.commands.jumpToSelected = false
    tabHelp.commands.collapseOther = false
    tabHelp.commands.collapseAll = false
    tabHelp.commands.openAll = false

    ImGui.EndChildFrame()

    local contextPopup = "RootWindow.Help.TopicsTree.Popup"

    if ImGui.IsPopupOpen(contextPopup) then
        tabHelp.states.isTreeContextPopup = true
    else
        tabHelp.states.isTreeContextPopup = false
    end

    if ImGui.BeginPopupContextItem(contextPopup, ImGuiPopupFlags.MouseButtonRight) then
        if ImGui.MenuItem("Jump To Selection") then
            tabHelp.commands.jumpToSelected = true
        end

        ImGui.Separator()

        if ImGui.MenuItem("Collapse Others") then
            tabHelp.commands.collapseOther = true
        end

        if ImGui.MenuItem("Collapse All") then
            tabHelp.commands.collapseAll = true
        end

        ImGui.EndPopup()
    end

    ImGui.Spacing()
    ImGui.InputTextMultiline("##RootWindow.Help.Viewer",
                                tabHelp.selectedTopicContent,
                                7000,
                                itemWidth,
                                300 * ImGuiExt.GetScaleFactor(),
                                ImGuiInputTextFlags.ReadOnly)
end

local function drawTabSettings()
    local debugBool, debugToggle
    local tabBarPopupBool, tabBarPopupToggle
    local tabOnMiddleClickBool, tabOnMiddleClickToggle
    local tooltipsBool, tooltipsToggle

    ImGui.Spacing()
    ImGuiExt.TextAlt("User Interface:")
    ImGui.Separator()

    tooltipsBool, tooltipsToggle = ImGuiExt.Checkbox("Enable tooltips",
                                                        settings.getModSetting("tooltips") or false,
                                                        tooltipsToggle)
    if tooltipsToggle then
        settings.setModSetting("tooltips", tooltipsBool)
    end

    tabBarPopupBool, tabBarPopupToggle = ImGuiExt.Checkbox("Enable popup menu for the tab bar",
                                                            settings.getModSetting("tabBarPopup") or false,
                                                            tabBarPopupToggle)
    if tabBarPopupToggle then
        settings.setModSetting("tabBarPopup", tabBarPopupBool)
    end

    tabOnMiddleClickBool, tabOnMiddleClickToggle = ImGuiExt.Checkbox("Close tabs with a middle mouse button click",
                                                                        settings.getModSetting("tabCloseOnMiddleButtonClick") or false,
                                                                        tabOnMiddleClickToggle)
    if tabOnMiddleClickToggle then
    settings.setModSetting("tabCloseOnMiddleButtonClick", tabOnMiddleClickBool)
    end

    ImGui.Text("")
    ImGuiExt.TextAlt("Window Theme:")
    ImGuiExt.DrawWithItemWidth(300 * ImGuiExt.GetScaleFactor(), true, "ThemesCombo")
    ImGuiExt.SetTooltip("Select mod's window theme.")
    ImGui.SameLine()

    if ImGui.Button("Save", 100 * ImGuiExt.GetScaleFactor(), 0) then
        settings.setModSetting("windowTheme", ImGuiExt.GetActiveThemeName())

        ImGuiExt.SetStatusBar("Settings saved.")
    end

    ImGui.Text("")
    ImGuiExt.TextAlt("Debug:")
    ImGui.Separator()

    debugBool, debugToggle = ImGuiExt.Checkbox("Enable debug mode", settings.getModSetting('debugMode') or false, debugToggle)
    if debugToggle then
        settings.setModSetting('debugMode', debugBool)
        logger.setDebug(settings.getModSetting('debugMode'))
    end

    ImGui.Text("")

    if debugBool then
        local width, height = GetDisplayResolution()
        local displayResolution = "Display Resolution: " .. width .. "x" .. height
        local aspectRatio = "Aspect Ratio: " .. (width / height)
        local resolutionFactor = "Resolution Height Factor: " .. ImGuiExt.GetResolutionFactor()
        local scalingFactor = "UI Scale Factor: " .. ImGuiExt.GetScaleFactor()
        ImGui.Indent(40)
        ImGuiExt.TextAlt(displayResolution)
        ImGuiExt.TextAlt(aspectRatio)
        ImGuiExt.TextAlt(resolutionFactor)
        ImGuiExt.TextAlt(scalingFactor)
        ImGui.Indent(-40)
        ImGui.Text("")
    end
end

local function drawDebugMenu()
    if ImGui.BeginMenu("Debug Menu") then
        if ImGui.MenuItem("Print Active Tab Label") then
            local activeTabLabel = ImGuiExt.GetActiveTabLabel("RootWindow.TabBar")
            logger.debug(activeTabLabel)
        end

        ImGui.EndMenu()
    end
end

local function drawRootPopupMenu()
    if ImGui.BeginPopupContextItem("RootWindow.RootPopupMenu", ImGuiPopupFlags.MouseButtonLeft) then
        local tabBarLabel = "RootWindow.TabBar"

        for _, module in pairs(appModules) do
            local menuIcon

            if module.__ICON then
                menuIcon = module.__ICON
            else
                menuIcon = "    "
            end

            if ImGui.MenuItem(menuIcon .. " " ..  module.__NAME) then
                ImGuiExt.AddTab(tabBarLabel, module.__NAME, module.__TITLE, module.draw)
            end
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.CloseBoxMultipleOutline .. " " .. "Close Inactive Tabs") then
            ImGuiExt.CloseInactiveTabs(tabBarLabel)
        end

        ImGuiExt.RecentlyClosedTabsMenu(IconGlyphs.DeleteOutline .. " " .. "Recently Closed Tabs", tabBarLabel)
        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.CogOutline .. " " ..  "Settings") then
            ImGuiExt.AddTab(tabBarLabel, "Settings", "Cyberlibs Settings", drawTabSettings)
        end

        ImGui.Separator()

        if ImGui.MenuItem(IconGlyphs.HelpCircleOutline .. " " ..  "Help") then
            ImGuiExt.AddTab(tabBarLabel, "Help", "Help Topics", drawTabHelp)
        end

        if ImGui.MenuItem(IconGlyphs.InformationOutline .. " " ..  "About") then
            ImGuiExt.AddTab(tabBarLabel, "About", "About Cyberlibs", drawTabAbout)
        end

        if settings.getModSetting('debugMode') then
            ImGui.Separator()
            drawDebugMenu()
        end

        ImGui.EndPopup()
    end
end

local function drawTabBarContextMenu(regionPos, regionSize)
    if ImGuiExt.IsMouseClickOverRegion(regionPos, regionSize, ImGuiMouseButton.Right) then
        ImGui.OpenPopup("RootWindow.TabBar.PopupMenu")
    end

    if ImGui.BeginPopup("RootWindow.TabBar.PopupMenu") then
        if ImGui.MenuItem(IconGlyphs.CloseBoxMultipleOutline .. " " .. "Close Inactive Tabs") then
            ImGuiExt.CloseInactiveTabs("RootWindow.TabBar")
        end

        ImGuiExt.RecentlyClosedTabsMenu(IconGlyphs.DeleteOutline .. " " .. "Recently Closed Tabs", "RootWindow.TabBar")
        ImGui.EndPopup()
    end
end

local function getTabBarFlags()
    local tabBarFlags = ImGuiTabBarFlags.Reorderable +
                        ImGuiTabBarFlags.FittingPolicyScroll +
                        ImGuiTabBarFlags.NoCloseWithMiddleMouseButton

    local tabBarSettingsFlags = {
        tabBarPopup = ImGuiTabBarFlags.TabListPopupButton +
                        ImGuiTabBarFlags.NoTabListScrollingButtons,
        tabCloseOnMiddleButtonClick = -ImGuiTabBarFlags.NoCloseWithMiddleMouseButton
    }

    if settings.getModSetting("tabBarPopup") then
        tabBarFlags = tabBarFlags + tabBarSettingsFlags.tabBarPopup
    end

    if settings.getModSetting("tabCloseOnMiddleButtonClick") then
        tabBarFlags = tabBarFlags + tabBarSettingsFlags.tabCloseOnMiddleButtonClick
    end

    return tabBarFlags
end

local function drawRootWindow()
    local activeTabLabel = ImGuiExt.GetActiveTabLabel("RootWindow.TabBar")

    if activeTabLabel == "" then
        search.updateFilterInstance("RootWindow.SearchInput.Default")
    else
        search.updateFilterInstance(activeTabLabel)
    end

    ImGuiExt.PushStyle()
    ImGui.SetNextWindowPos(400, 200, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(780 * ImGuiExt.GetScaleFactor(), 0)

    if ImGui.Begin(Cyberlibs.__NAME) then
        local activeFilter = search.getActiveFilter()
        local resolutionFactor = ImGuiExt.GetResolutionFactor()
        local windowWidth = ImGui.GetWindowWidth()
        local windowPadding = ImGui.GetStyle().WindowPadding
        local itemSpacing = ImGui.GetStyle().ItemSpacing
        local dotsWidth = ImGui.CalcTextSize(IconGlyphs.DotsVertical)
        local regionPos = {}
        local dummyText = "Open a Cyberlibs module to start."

        activeFilter.query, activeFilter.isTyped = ImGuiExt.SearchInput(activeFilter.label,
                                                                        activeFilter.query,
                                                                        "Search...",
                                                                        windowWidth - (windowPadding.x * 2) - itemSpacing.x - dotsWidth - 12)
        if activeFilter.isTyped then
            search.setFiltering(true)

            utils.SetDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
        end

        ImGui.SameLine()
        ImGui.Button(IconGlyphs.DotsVertical, dotsWidth + 12, 0)
        drawRootPopupMenu()
        ImGui.Separator()

        regionPos.x, regionPos.y = ImGui.GetCursorScreenPos()

        if not ImGuiExt.TabBar("RootWindow.TabBar", getTabBarFlags()) then
            ImGui.Dummy(100, 30 * resolutionFactor)
            ImGuiExt.AlignNextItemToWindowCenter(ImGui.CalcTextSize(dummyText), windowWidth, windowPadding.x)
            ImGuiExt.TextAlt(dummyText)
            ImGui.Dummy(100, 30 * resolutionFactor)
        end

        local regionSize = ImVec2.new(windowWidth, 8 * resolutionFactor)

        drawTabBarContextMenu(regionPos, regionSize)
        ImGuiExt.StatusBarAlt(ImGuiExt.GetStatusBar())
    end

    ImGui.End()
    ImGuiExt.PopStyle()
end

------------------
-- Registers
------------------

registerForEvent("onInit", function()
    logger.setModName(Cyberlibs.__NAME)

    Cyberlibs = tables.add(Cyberlibs, publicApi)

    publicApi.onInit()
    settings.onInit()
    logger.setDebug(settings.getModSetting('debugMode'))
    ImGuiExt.onInit(settings.getModSetting("windowTheme"), Cyberlibs.Version() ..
                                            Cyberlibs.__VERSION_SUFFIX ..
                                            "-" ..
                                            Cyberlibs.__VERSION_STATUS)

    loadAppModules()
    initializeModSettings()
end)

registerForEvent("onOverlayOpen", function()
    isRootWindow = true

    settings.onOverlayOpen()
    ImGuiExt.onOverlayOpen()

    openTabGameModules()
end)

registerForEvent("onOverlayClose", function()
    isRootWindow = false

    search.flushBrowse()
    settings.onOverlayClose()

    logger.setDebug(settings.getModSetting('debugMode'))
end)

registerForEvent("onUpdate", function(deltaTime)
    utils.updateDelays(deltaTime)
end)

registerForEvent("onDraw", function()
    ImGuiExt.Notification()

    if isRootWindow then
        drawRootWindow()
    end
end)

return Cyberlibs