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

local tabAboutVars = {
    pluginVersion = "",
    luaGuiVersion = "",
    licenses = ""
}

local tabHelpVars = {
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

local function nameFilterInstance(name)
    return "RootWindow.SearchInput." .. name
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
    ImGuiExt.TextAlt(tabAboutVars.pluginVersion)
    ImGuiExt.TextAlt("Lua GUI Version:")
    ImGui.SameLine()
    ImGuiExt.TextAlt(tabAboutVars.luaGuiVersion)
    ImGui.Text("")
    ImGuiExt.TextAlt("License & Third Party")

    ImGui.BeginChildFrame(ImGui.GetID("HelpTopicView"),
                            itemWidth,
                            300 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.AlwaysHorizontalScrollbar)
    ImGui.Text(tabAboutVars.licenses)
    ImGui.EndChildFrame()

    if tabAboutVars.pluginVersion ~= "" then return end
    tabAboutVars.pluginVersion = Cyberlibs.Version()
    tabAboutVars.luaGuiVersion = Cyberlibs.Version()
    local thirdparty = loadfile("thirdparty")

    if thirdparty ~= nil then
        tabAboutVars.licenses = utils.indentString(Cyberlibs.__LICENSE .. "\n" .. thirdparty(), -20, true)
    else
        tabAboutVars.licenses = utils.indentString(Cyberlibs.__LICENSE, -20, true)
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

        if nodePath == tabHelpVars.selectedTopic then
            flags = flags + ImGuiTreeNodeFlags.Selected
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
        end
    end

    if not tabHelpVars.states.isTreeContextPopup then
        local rectMin = ImVec2.new()
        rectMin.x, rectMin.y = ImGui.GetCursorScreenPos()
        local contentRegionAvailX = ImGui.GetContentRegionAvail()
        local rectMax = ImVec2.new(rectMin.x + contentRegionAvailX, rectMin.y + ImGui.GetFrameHeight())

        if ImGui.IsMouseHoveringRect(rectMin.x, rectMin.y, rectMax.x, rectMax.y - 10) then
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor('text')
        end
    end

    ImGui.PushStyleColor(ImGuiCol.Text, textRed, textGreen, textBlue, textAlpha)

    local shouldOpen = string.find(tabHelpVars.selectedTopic, "^" .. nodePath .. "%.")

    if tabHelpVars.commands.jumpToSelected and nodePath == tabHelpVars.selectedTopic then
        ImGui.SetScrollHereY()
    end

    if not isLeaf then
        if shouldOpen then
            if tabHelpVars.commands.jumpToSelected then
                ImGui.SetNextItemOpen(true)
            elseif tabHelpVars.commands.collapseAll then
                ImGui.SetNextItemOpen(false)
            end
        else
            if tabHelpVars.commands.collapseOther or tabHelpVars.commands.collapseAll then
                ImGui.SetNextItemOpen(false)
            end
        end
    end

    local isOpen = ImGui.TreeNodeEx(name .. "##" .. tostring(depth), flags)

    if ImGui.IsItemClicked() and isLeaf then
        tabHelpVars.selectedTopic = nodePath
        tabHelpVars.selectedTopicContent = utils.indentString(node, -20, true)
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

    if search.getFilterQuery(nameFilterInstance("Help")) == "" then
        tabHelpVars.topicsPool = help.getTable()
    else
        if search.isFiltering() then
            tabHelpVars.topicsPool = search.filter(help.getTable(), search.getFilterQuery(nameFilterInstance("Help")))
        end
    end

    local sortedKeys = tables.assignKeysOrder(tabHelpVars.topicsPool)

    for _, k in ipairs(sortedKeys) do
        local v = tabHelpVars.topicsPool[k]

        drawHelpTreeNode(v, tostring(k), 0, tostring(k))
    end

    tabHelpVars.commands.jumpToSelected = false
    tabHelpVars.commands.collapseOther = false
    tabHelpVars.commands.collapseAll = false

    ImGui.EndChildFrame()

    local contextPopup = "RootWindow.Help.TopicsTree.Popup"

    if ImGui.IsPopupOpen(contextPopup) then
        tabHelpVars.states.isTreeContextPopup = true
    else
        tabHelpVars.states.isTreeContextPopup = false
    end

    if ImGui.BeginPopupContextItem(contextPopup, ImGuiPopupFlags.MouseButtonRight) then
        if ImGui.MenuItem("Jump To Selection") then
            tabHelpVars.commands.jumpToSelected = true
        end

        ImGui.Separator()

        if ImGui.MenuItem("Collapse Others") then
            tabHelpVars.commands.collapseOther = true
        end

        if ImGui.MenuItem("Collapse All") then
            tabHelpVars.commands.collapseAll = true
        end

        ImGui.EndPopup()
    end

    ImGui.Spacing()
    ImGui.InputTextMultiline("##RootWindow.Help.Viewer",
                                tabHelpVars.selectedTopicContent,
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
    ImGuiExt.DrawWithItemWidth(300, true, "ThemesCombo")
    ImGuiExt.SetTooltip("Select mod's window theme.")
    ImGui.SameLine()

    if ImGui.Button("Save", 100 * ImGuiExt.GetScaleFactor(), 0) then
        settings.setModSetting("windowTheme", ImGuiExt.GetActiveThemeName())

        ImGuiExt.SetStatusBar("Settings saved.")
    end

    ImGui.Text("")
    ImGuiExt.TextAlt("Debug:")
    ImGui.Separator()

    debugBool, debugToggle = ImGuiExt.Checkbox("Enable debug mode", settings.isDebugMode(), debugToggle)
    if debugToggle then
        settings.setDebugMode(debugBool)
    end

    ImGui.Text("")

    if debugBool then
        local width, height = GetDisplayResolution()
        local displayResolution = "Display Resolution: " .. width .. "x" .. height
        local aspectRatio = "Aspect Ratio: " .. (width / height)
        local scalingFactor = "UI Scale Factor: " .. ImGuiExt.GetScaleFactor()
        ImGui.Indent(40)
        ImGuiExt.TextAlt(displayResolution)
        ImGuiExt.TextAlt(aspectRatio)
        ImGuiExt.TextAlt(scalingFactor)
        ImGui.Unindent()
        ImGui.Text("")
    end
end

local function getClosedTabsList(closedTabsTable)
    local closedTabsList = {}

    if next(closedTabsTable) then
        local j = 1

        for i = #closedTabsTable, 1, -1 do
            closedTabsList[j] = {
                label = closedTabsTable[i].label,
                command = function() return ImGuiExt.AddTab("RootWindow.TabBar",
                                                            closedTabsTable[i].label,
                                                            closedTabsTable[i].title,
                                                            closedTabsTable[i].callback,
                                                            closedTabsTable[i].callbackParams)                                                         
                                                        end
            }
            j = j + 1
        end
    end

    return closedTabsList
end

local function drawRecentlyClosedTabsMenu()
    if ImGui.BeginMenu("Recently Closed Tabs") then
        local closedTabsList = getClosedTabsList(ImGuiExt.GetRecentlyClosedTabs("RootWindow.TabBar"))

        if next(closedTabsList)then
            for _, entry in ipairs(closedTabsList) do
                if ImGui.MenuItem(entry.label) then
                    entry.command()
                end
            end
        else
            ImGui.MenuItem("---")
        end

        ImGui.EndMenu()
    end
end

local function drawRootPopupMenu()
    if ImGui.BeginPopupContextItem("RootWindow.RootPopupMenu", ImGuiPopupFlags.MouseButtonLeft) then
        local tabBarLabel = "RootWindow.TabBar"

        for _, module in pairs(appModules) do
            if ImGui.MenuItem(module.__NAME) then
                ImGuiExt.AddTab(tabBarLabel, module.__NAME, module.__TITLE, module.draw)
            end
        end

        ImGui.Separator()

        if ImGui.MenuItem("Close Other Tabs") then
            ImGuiExt.CloseOtherTabs(tabBarLabel)
        end

        drawRecentlyClosedTabsMenu()
        ImGui.Separator()

        if ImGui.MenuItem("Settings") then
            ImGuiExt.AddTab(tabBarLabel, "Settings", "Cyberlibs Settings", drawTabSettings)
        end

        ImGui.Separator()

        if ImGui.MenuItem("Help") then
            ImGuiExt.AddTab(tabBarLabel, "Help", "Help Topics", drawTabHelp)
        end

        if ImGui.MenuItem("About") then
            ImGuiExt.AddTab(tabBarLabel, "About", "About Cyberlibs", drawTabAbout)
        end

        ImGui.EndPopup()
    end
end

local function drawRootWindow()
    local activeTabLabel = ImGuiExt.GetActiveTabLabel("RootWindow.TabBar")

    if activeTabLabel == "" then
        search.updateFilterInstance(nameFilterInstance("Default"))
    else
        search.updateFilterInstance(nameFilterInstance(activeTabLabel))
    end

    ImGuiExt.PushStyle()
    ImGui.SetNextWindowPos(400, 200, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(780 * ImGuiExt.GetScaleFactor(), 0)

    if ImGui.Begin(Cyberlibs.__NAME) then
        local activeFilter = search.getActiveFilter()
        local windowWidth = ImGui.GetWindowWidth()
        local windowPadding = ImGui.GetStyle().WindowPadding
        local itemSpacing = ImGui.GetStyle().ItemSpacing
        local dotsWidth = ImGui.CalcTextSize(IconGlyphs.DotsVertical)
        local dummyText = "Open a Cyberlibs module to start."
        local tabBarSettingsFlags = {
            tabBarPopup = ImGuiTabBarFlags.TabListPopupButton +
                            ImGuiTabBarFlags.NoTabListScrollingButtons,
            tabCloseOnMiddleButtonClick = -ImGuiTabBarFlags.NoCloseWithMiddleMouseButton
        }

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

        local tabBarFlags = ImGuiTabBarFlags.Reorderable +
                            ImGuiTabBarFlags.FittingPolicyScroll +
                            ImGuiTabBarFlags.NoCloseWithMiddleMouseButton

        if settings.getModSetting("tabBarPopup") then
            tabBarFlags = tabBarFlags + tabBarSettingsFlags.tabBarPopup
        end

        if settings.getModSetting("tabCloseOnMiddleButtonClick") then
            tabBarFlags = tabBarFlags + tabBarSettingsFlags.tabCloseOnMiddleButtonClick
        end

        if not ImGuiExt.TabBar("RootWindow.TabBar", tabBarFlags) then
            ImGui.Dummy(100, 120)
            ImGuiExt.AlignNextItemToWindowCenter(ImGui.CalcTextSize(dummyText), windowWidth, windowPadding.x)
            ImGuiExt.TextAlt(dummyText)
            ImGui.Dummy(100, 120)
        end

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
    logger.setDebug(settings.isDebugMode())
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

    logger.setDebug(settings.isDebugMode())
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