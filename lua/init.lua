Cyberlibs = {
    __NAME = "Cyberlibs",
    __EDITION = nil,
    __VERSION = { 0, 2, 0 },
    __VERSION_SUFFIX = nil,
    __VERSION_STATUS = nil,
    __DESCRIPTION = "A mods resource and on-runtime diagnostics tool for Cyberpunk 2077.",
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
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- Knowledge Base
------------------

local help = require("knowledgeBase/help")

------------------
-- App Tables
------------------

local publicApi = require("api/publicApi")
local appApi = {}
local appModules = {}
local appModulesContents = {}

------------------
-- App / Public API
------------------

local function registerPublicApi()
    Cyberlibs = tables.add(Cyberlibs, publicApi)
end

---@return boolean
function appApi.isRootWindow()
    return isRootWindow
end

---@return boolean
function appApi.isCyberlibsDLL()
    return type(GameModules) ~= "nil"
end

---@param moduleFolderName string
---@return boolean
function appApi.isAppModule(moduleFolderName)
    return appModules[moduleFolderName] ~= nil
end

local function registerAppModulesApi()
    local modulesDir = dir("appModules")

    for _, folder in pairs(modulesDir) do
        local modulePath = "appModules/" .. folder.name .. "/main.lua"
        local moduleFile = loadfile(modulePath)

        if moduleFile then
            local loadedModule = moduleFile()

            if loadedModule.appApi then
                appApi = tables.add(appApi, loadedModule.appApi)
            end

            if loadedModule.publicApi then
                Cyberlibs = tables.add(Cyberlibs, loadedModule.publicApi)
            end
        end
    end
end

------------------
-- App Modules
------------------

local function verifyAppModule(path)
    local moduleFile = loadfile(path)(appApi)

    if moduleFile.__NAME and
        moduleFile.draw and
        type(moduleFile.draw) == "function" then

        return moduleFile
    end
end

local function sortAppModules()
    appModulesContents = tables.assignKeysOrder(appModules)

    table.sort(appModulesContents, function(a, b)
        return appModules[a].__NAME < appModules[b].__NAME
    end)
end

local function registerAppModules()
    local modulesDir = dir("appModules")

    for _, folder in pairs(modulesDir) do
        local modulePath = "appModules/" .. folder.name .. "/main.lua"
        local loadedModule = verifyAppModule(modulePath)

        if loadedModule ~= nil then
            appModules[folder.name] = loadedModule
            logger.debug("Added app module:", folder.name)
        else
            logger.debug("App module discarded:", folder.name)
        end
    end

    sortAppModules()
end

------------------
--- App Modules Inputs
------------------

local function executeInput(keypress, keyPressCallback, keyReleaseCallback)
    if keypress then
        if keyPressCallback then
            keyPressCallback()
        end
    else
        return
    end

    if keyReleaseCallback then
        keyReleaseCallback()
    end
end

local function registerAppModulesInputs()
    for appModule, _ in pairs(appModules) do
        local inputs = appModules[appModule].inputs

        if inputs ~= nil  then
            for i, _ in ipairs(inputs) do
                registerInput(inputs[i].id, 
                                appModules[appModule].__NAME .. ": " .. inputs[i].description,
                                function(keypress)

                    executeInput(keypress, inputs[i].keyPressCallback, inputs[i].keyReleaseCallback)
                end)
            end
        end
    end
end

------------------
--- App Modules Events
------------------

local function fireAppModulesEvents(appEventName, ...)
    for appModule, _ in pairs(appModules) do
        if appModules[appModule].events ~= nil and
            appModules[appModule].events[appEventName] ~= nil then

            appModules[appModule].events[appEventName](...)
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
        stylizePrints = true,
        tooltips = true,
        tabBarDropdown = false,
        tabCloseOnMiddleButtonClick = false
    }

    for setting, value in pairs(appSettings) do
        if settings.getModSetting(setting) == nil then
            settings.setModSetting(setting, value)
        end
    end
end

local function openDefaultTab()
    local gameModules = appModules.gameModules
    local tabBarLabel = "RootWindow.TabBar"

    if gameModules ~= nil and ImGuiExt.GetActiveTabLabel(tabBarLabel) == "" then
        ImGuiExt.AddTab(tabBarLabel, gameModules.__NAME, gameModules.__TITLE, gameModules.draw)
    end
end

local function drawAboutTab()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x
    local framePaddingX = ImGui.GetStyle().FramePadding.x

    search.updateFilterInstance("RootWindow.AboutTab")
    ImGui.Indent(framePaddingX)
    ImGuiExt.TextAlt("Plugin Version:")
    ImGui.SameLine()
    ImGuiExt.TextAlt(tabAbout.pluginVersion)
    ImGuiExt.TextAlt("Lua GUI Version:")
    ImGui.SameLine()
    ImGuiExt.TextAlt(tabAbout.luaGuiVersion)
    ImGui.Text("")
    ImGuiExt.TextAlt("License & Third Party")
    ImGui.Indent(- framePaddingX)

    ImGui.BeginChildFrame(ImGui.GetID("RootWindow.About.LicenseThirdParty"),
                            itemWidth,
                            400 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.AlwaysHorizontalScrollbar)
    ImGui.Text(tabAbout.licenses)
    ImGui.EndChildFrame()

    if tabAbout.pluginVersion ~= "" then return end

    if not appApi.isCyberlibsDLL() then
        tabAbout.pluginVersion = "Install Cyberlibs RED4ext Plugin."
        tabAbout.luaGuiVersion = "Install Cyberlibs RED4ext Plugin."
        tabAbout.licenses = utils.indentString(Cyberlibs.__LICENSE, -20, true)

        return
    end

    tabAbout.pluginVersion = Cyberlibs.Version()
    tabAbout.luaGuiVersion = Cyberlibs.Version()
    local thirdparty = GameDiagnostics.ReadTextFile("red4ext/plugins/Cyberlibs/THIRD_PARTY_LICENSES.md")
    local kudos = GameDiagnostics.ReadTextFile("bin/x64/plugins/cyber_engine_tweaks/mods/Cyberlibs/kudos.md")

    if thirdparty ~= nil then
        tabAbout.licenses = utils.indentString(Cyberlibs.__LICENSE, -20, true) .. "\n" .. thirdparty
    else
        tabAbout.licenses = utils.indentString(Cyberlibs.__LICENSE, -20, true)
    end

    if kudos ~= nil then
        tabAbout.licenses = tabAbout.licenses .. "\n\n" .. kudos
    end
end

local function drawHelpTreeNode(node, name, depth, nodePath)
    depth = depth or 0
    nodePath = nodePath or name
    local flags = ImGuiTreeNodeFlags.SpanFullWidth
    local nodeType = type(node)
    local isLeaf = nodeType ~= "table" or next(node) == nil
    local textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("textAlt")

    if isLeaf then
        flags = flags + ImGuiTreeNodeFlags.Leaf

        if nodePath == tabHelp.selectedTopic then
            flags = flags + ImGuiTreeNodeFlags.Selected
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("text")
        end
    end

    if not tabHelp.states.isTreeContextPopup then
        local rectPos = ImVec2.new()
        rectPos.x, rectPos.y = ImGui.GetCursorScreenPos()
        local contentRegionAvailX = ImGui.GetContentRegionAvail()
        local rectSize = ImVec2.new(rectPos.x + contentRegionAvailX, rectPos.y + ImGui.GetFrameHeight())

        if ImGui.IsMouseHoveringRect(rectPos.x, rectPos.y, rectSize.x, rectSize.y - 10) then
            textRed, textGreen, textBlue, textAlpha = ImGuiExt.GetActiveThemeColor("text")
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

local function drawHelpTab()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x

    search.updateFilterInstance("RootWindow.HelpTab")

    if search.getFilterQuery("RootWindow.HelpTab") == "" then
        tabHelp.topicsPool = help.getTable()
    else
        if ImGuiExt.IsSearchInputTyped(search.getActiveFilter().label) then
            search.setFiltering(true)
        end

        tabHelp.topicsPool = search.filter("RootWindow.HelpTab", help.getTable(), search.getFilterQuery("RootWindow.HelpTab"))
        tabHelp.commands.openAll = true
    end

    local sortedKeys = tables.assignKeysOrder(tabHelp.topicsPool)

    ImGui.BeginChildFrame(ImGui.GetID("RootWindow.Help.TopicsTree"),
                            itemWidth,
                            200 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.HorizontalScrollbar +
                            ImGuiWindowFlags.NoBackground)

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
        if ImGui.MenuItem(ImGuiExt.TextIcon("Jump To Selection", IconGlyphs.ArrowTopLeft)) then
            tabHelp.commands.jumpToSelected = true
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse Others", IconGlyphs.MinusBoxMultipleOutline)) then
            tabHelp.commands.collapseOther = true
        end

        if ImGui.MenuItem(ImGuiExt.TextIcon("Collapse All", IconGlyphs.CollapseAllOutline)) then
            tabHelp.commands.collapseAll = true
        end

        ImGui.EndPopup()
    end

    ImGui.Spacing()
    ImGui.InputTextMultiline("##RootWindow.Help.Viewer",
                                tabHelp.selectedTopicContent,
                                32768,
                                itemWidth,
                                300 * ImGuiExt.GetScaleFactor(),
                                ImGuiInputTextFlags.ReadOnly)
    
    if ImGui.BeginPopupContextItem("RootWindow.Help.Viewer", ImGuiPopupFlags.MouseButtonRight) then
        ImGuiExt.MenuItemCopyValue(tabHelp.selectedTopicContent, "Topic")
        ImGui.EndPopup()
    end
end

local function drawSettingsTab()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x
    local debugBool, debugToggle
    local tabBarDropdownBool, tabBarDropdownToggle
    local tabOnMiddleClickBool, tabOnMiddleClickToggle
    local tooltipsBool, tooltipsToggle
    local printStylingBool, printStylingToggle

    search.updateFilterInstance("RootWindow.SettingsTab")
    ImGui.BeginChildFrame(ImGui.GetID("RootWindow.Settings"),
                            itemWidth,
                            656 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)

    ------------------
    --- App Modules Settings

    for _, key in ipairs(appModulesContents) do
        local appModule = appModules[key]

        if appModule.drawSettings then
            ImGui.Separator()
            ImGuiExt.TextTitle(appModule.__NAME, 0.9, true)
            ImGui.Spacing()
            appModule.drawSettings()
            ImGui.Text("")
        end
    end

    ------------------

    ImGui.Separator()
    ImGuiExt.TextTitle("User Interface", 0.9, true)
    ImGui.Spacing()

    tooltipsBool, tooltipsToggle = ImGuiExt.Checkbox("Enable tooltips",
                                                        settings.getModSetting("tooltips") or false,
                                                        tooltipsToggle)
    if tooltipsToggle then
        settings.setModSetting("tooltips", tooltipsBool)
    end

    tabBarDropdownBool, tabBarDropdownToggle = ImGuiExt.Checkbox("Enable drop-down list for the tab bar",
                                                            settings.getModSetting("tabBarDropdown") or false,
                                                            tabBarDropdownToggle)
    if tabBarDropdownToggle then
        settings.setModSetting("tabBarDropdown", tabBarDropdownBool)
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
    ImGui.Separator()
    ImGuiExt.TextTitle("Printing / Dumping", 0.9, true)
    ImGui.Spacing()

    printStylingBool, printStylingToggle = ImGuiExt.Checkbox("Stylize prints / data dumps",
                                                                settings.getModSetting("stylizePrints") or false,
                                                                tabOnMiddleClickToggle)
    
    if printStylingToggle then
        settings.setModSetting("stylizePrints", printStylingBool)
        style.setEnabled(settings.getModSetting("stylizePrints"))
    end

    ImGui.Text("")
    ImGui.Separator()
    ImGuiExt.TextTitle("Debug", 0.9, true)
    ImGui.Spacing()

    debugBool, debugToggle = ImGuiExt.Checkbox("Enable debug mode", settings.getModSetting("debugMode") or false, debugToggle)
    if debugToggle then
        settings.setModSetting("debugMode", debugBool)
        logger.setDebug(settings.getModSetting("debugMode"))
    end

    ImGui.Text("")

    if debugBool then
        local floor = math.floor
        local width, height = GetDisplayResolution()
        local displayResolution = "Display Resolution: " .. width .. "x" .. height
        local aspectRatio = "Aspect Ratio: " .. floor(width / height * 100 + 0.5) / 100
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

    ImGui.EndChildFrame()
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

        for _, key in ipairs(appModulesContents) do
            local appModule = appModules[key]
            local appModuleIcon = appModule.__ICON or nil
        
            if ImGui.MenuItem(ImGuiExt.TextIcon(appModule.__NAME, appModuleIcon)) then
                ImGuiExt.AddTab(tabBarLabel, appModule.__NAME, appModule.__TITLE, appModule.draw)
            end
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Close Inactive Tabs", IconGlyphs.CloseBoxMultipleOutline)) then
            ImGuiExt.CloseInactiveTabs(tabBarLabel)
        end

        ImGuiExt.BeginMenuRecentlyClosedTabs(ImGuiExt.TextIcon("Recently Closed Tabs", IconGlyphs.DeleteOutline), tabBarLabel)
        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Settings", IconGlyphs.CogOutline)) then
            ImGuiExt.AddTab(tabBarLabel, "Settings", "Cyberlibs Settings", drawSettingsTab)
        end

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Help", IconGlyphs.HelpCircleOutline)) then
            ImGuiExt.AddTab(tabBarLabel, "Help", "Help Topics", drawHelpTab)
        end

        if ImGui.MenuItem(ImGuiExt.TextIcon("About", IconGlyphs.InformationOutline)) then
            ImGuiExt.AddTab(tabBarLabel, "About", "About Cyberlibs", drawAboutTab)
        end

        if settings.getModSetting("debugMode") then
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
        ImGuiExt.BeginMenuOpenedTabs(ImGuiExt.TextIcon("Opened Tabs"), "RootWindow.TabBar")

        ImGui.Separator()

        if ImGui.MenuItem(ImGuiExt.TextIcon("Close Inactive Tabs", IconGlyphs.CloseBoxMultipleOutline)) then
            ImGuiExt.CloseInactiveTabs("RootWindow.TabBar")
        end

        ImGuiExt.BeginMenuRecentlyClosedTabs(ImGuiExt.TextIcon("Recently Closed Tabs", IconGlyphs.DeleteOutline), "RootWindow.TabBar")
        ImGui.EndPopup()
    end
end

local function getTabBarFlags()
    local tabBarFlags = ImGuiTabBarFlags.Reorderable +
                        ImGuiTabBarFlags.FittingPolicyScroll +
                        ImGuiTabBarFlags.NoCloseWithMiddleMouseButton

    local tabBarSettingsFlags = {
        tabBarDropdown = ImGuiTabBarFlags.TabListPopupButton +
                        ImGuiTabBarFlags.NoTabListScrollingButtons,
        tabCloseOnMiddleButtonClick = -ImGuiTabBarFlags.NoCloseWithMiddleMouseButton
    }

    if settings.getModSetting("tabBarDropdown") then
        tabBarFlags = tabBarFlags + tabBarSettingsFlags.tabBarDropdown
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
        ImGuiExt.ResetStatusBar()
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

        activeFilter.query = ImGuiExt.SearchInput(activeFilter.label,
                                                    activeFilter.query,
                                                    "Search...",
                                                    windowWidth - (windowPadding.x * 2) - itemSpacing.x - dotsWidth - 12)

        if ImGuiExt.IsSearchInputTyped(activeFilter.label) then
            utils.setDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
        end

        ImGui.SameLine()
        ImGui.Button(IconGlyphs.DotsVertical, dotsWidth + 12, 0)
        drawRootPopupMenu()
        ImGui.Separator()

        regionPos.x, regionPos.y = ImGui.GetCursorScreenPos()

        if not ImGuiExt.TabBar("RootWindow.TabBar", getTabBarFlags()) then
            ImGui.Dummy(100, 30 * resolutionFactor)
            ImGuiExt.AlignNextItemToCenter(ImGui.CalcTextSize(dummyText), windowWidth, windowPadding.x)
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

registerPublicApi()
registerAppModulesApi()
registerAppModules()
registerAppModulesInputs()
initializeModSettings()

registerForEvent("onInit", function()
    logger.setModName(Cyberlibs.__NAME)
    publicApi.onInit()
    settings.onInit()
    logger.setDebug(settings.getModSetting("debugMode"))
    style.setEnabled(settings.getModSetting("stylizePrints"))
    ImGuiExt.onInit(settings.getModSetting("windowTheme"), Cyberlibs.Version())
    fireAppModulesEvents("onInit")
end)

registerForEvent("onOverlayOpen", function()
    isRootWindow = true

    settings.onOverlayOpen()
    ImGuiExt.onOverlayOpen()
    fireAppModulesEvents("onOverlayOpen")
    openDefaultTab()
end)

registerForEvent("onOverlayClose", function()
    isRootWindow = false

    search.flushBrowse()
    search.flushFilter()
    fireAppModulesEvents("onOverlayClose")
    settings.onOverlayClose()
end)

registerForEvent("onUpdate", function(deltaTime)
    utils.updateDelays(deltaTime)
    fireAppModulesEvents("onUpdate", deltaTime)
end)

registerForEvent("onDraw", function()
    ImGuiExt.Notification()

    if isRootWindow then
        drawRootWindow()
    end

    fireAppModulesEvents("onDraw")
end)

return Cyberlibs

--                000000                00    0000                       00                     000          000    0     0000                    
--             00000000  00      0000000000000000000     000000000000000000000000000          0000          0000000000000000000         000000000 
--           000000000  000     000000000    000000     000000  00000000000000000000        0000          00000000000    000000  00000000    0000 
--        00000   000  000    0000   000  000000       000      000  0000   000000         000           0000   000   000000   00000      00000   
--      00000         000   0000   0000000000        00000000000    000000000000         0000           000    0000000000     000       0000      
--     0000          000  00000   000000000         00000000000    00000000            0000           0000    000000000        00000              
--    000      00   0000 0000    000  00000000     0000           0000000000          000            000    000  000000000        000000          
--   000   00000    0000000     00      000000   0000     000000000      00000      0000   000000000000    000     000000    000      000         
--  000 00000      000000     000   000000      0000000000000   00          0000  00000000000000  0000    000   000000     000     00000          
-- 0000000         00000      0  00000        0000000          00             00000000000        0000    00  00000       000000000000             
--  00             000                         0              00                  00                                    000000000                 
--                000                                                                                                    0                        
--               00                                                                                                                               
--              00 