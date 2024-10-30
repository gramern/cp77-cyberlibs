-- ImGuiExt.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local ImGuiExt = {
    __VERSION = { 0, 3, 1 },
}

local activeThemeName = "Default"

local activeTheme = {}

local fallbackTheme = {
    text = { 0, 0, 0, 1 },
    textAlt = { 1, 1, 1, 1 },
    textTitle = { 1, 1, 1, 1 },
    textTitleBg = { 0.25, 0.25, 0.25, 0.75 },
    base = { 0.5, 0.5, 0.5, 1 },
    border = { 0.5, 0.5, 0.5, 1 },
    bg = { 0, 0, 0, 0.75 },
    dim = { 0.25, 0.25, 0.25, 1 },
    pop = { 0.75, 0.75, 0.75, 1 },
    scrollbar = { base = { 0.5, 0.5, 0.5, 1 }, dim = { 0.5, 0.5, 0.5, 1 }, pop = { 0.75, 0.75, 0.75, 1 }, rounding = 5, size = 20 },
    separator = { 0.5, 0.5, 0.5, 1 },
    child = { border = 0, rounding = 5 },
    frame = { border = 0, rounding = 5 },
    popup = { border = 1, rounding = 5 },
    tab = { base = { 0.5, 0.5, 0.5, 1 }, border = 0, rounding = 5 },
    window = { border = 1, rounding = 5 }
}

local searchInputs = {}

local statusBars = {
    __default = {}
}

local tabBars = {}

local var = {
    notification = { active = false, text = "", textWidth = 0 },
    scaleFactor = 1.5,
    screen = { aspectRatio = 1.78, width = 3840, height = 2160 }
}

local settings = require("globals/settings")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- Scaling
------------------

local function setupScreen()
    var.screen.width, var.screen.height = GetDisplayResolution();
    var.screen.aspectRatio = var.screen.width / var.screen.height

    if var.screen.aspectRatio >= 3.4 then
        var.scaleFactor = 0.5
    else
        if var.screen.width >= 3840 then
            var.scaleFactor = 1.5
        elseif var.screen.width >= 2160 then
            var.scaleFactor = 1
        else
            var.scaleFactor = 0.75
        end
    end
end

---@return number
function ImGuiExt.GetAspectRatio()
    return var.screen.aspectRatio
end

---@return number
function ImGuiExt.GetResolutionFactor()
    return var.screen.height / 360
end

---@return number
function ImGuiExt.GetScaleFactor()
    return var.scaleFactor
end

------------------
-- Push/Pop Styles
------------------

function ImGuiExt.PushStyle()
    local child = activeTheme.child
    local frame = activeTheme.frame
    local popup = activeTheme.popup
    local tab = activeTheme.tab
    local window = activeTheme.window

    local base = activeTheme.base
    local border = activeTheme.border
    local dim = activeTheme.dim
    local pop = activeTheme.pop
    local scrollbar = activeTheme.scrollbar
    local text = activeTheme.text

    ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 5, 2)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildBorderSize, child.border)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, child.rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, frame.border)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 6, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, frame.rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.IndentSpacing, 28)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 5, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupBorderSize, popup.border)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, popup.rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarRounding, scrollbar.rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, scrollbar.size)
    ImGui.PushStyleVar(ImGuiStyleVar.TabBorderSize, tab.border)
    ImGui.PushStyleVar(ImGuiStyleVar.TabBarBorderSize, tab.border)
    ImGui.PushStyleVar(ImGuiStyleVar.TabRounding, tab.rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 10, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, window.border)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, window.rounding)
    ImGui.PushStyleColor(ImGuiCol.Border, border[1], border[2], border[3], border[4])
    ImGui.PushStyleColor(ImGuiCol.BorderShadow, border[1], border[2], border[3], border[4])
    ImGui.PushStyleColor(ImGuiCol.Button, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.CheckMark, text[1], text[2], text[3], text[4])
    ImGui.PushStyleColor(ImGuiCol.ChildBg, activeTheme.bg[1], activeTheme.bg[2], activeTheme.bg[3], activeTheme.bg[4])
    ImGui.PushStyleColor(ImGuiCol.FrameBg, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.Header, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.HeaderActive, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.PopupBg, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.ResizeGrip, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.ResizeGripHovered, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.ResizeGripActive, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrab, scrollbar.base[1], scrollbar.base[2], scrollbar.base[3], scrollbar.base[4])
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrabHovered, scrollbar.pop[1], scrollbar.pop[2], scrollbar.pop[3], scrollbar.pop[4])
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrabActive, scrollbar.dim[1], scrollbar.dim[2], scrollbar.dim[3], scrollbar.dim[4])
    ImGui.PushStyleColor(ImGuiCol.SeparatorActive, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.Separator, activeTheme.separator[1], activeTheme.separator[2], activeTheme.separator[3], activeTheme.separator[4])
    ImGui.PushStyleColor(ImGuiCol.SeparatorHovered, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.SliderGrab, scrollbar.base[1], scrollbar.base[2], scrollbar.base[3], scrollbar.base[4])
    ImGui.PushStyleColor(ImGuiCol.SliderGrabActive, scrollbar.pop[1], scrollbar.pop[2], scrollbar.pop[3], scrollbar.pop[4])
    ImGui.PushStyleColor(ImGuiCol.Tab, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.TabHovered, pop[1], pop[2], pop[3], pop[4])
    ImGui.PushStyleColor(ImGuiCol.TabActive, tab.base[1], tab.base[2], tab.base[3], tab.base[4])
    ImGui.PushStyleColor(ImGuiCol.TabUnfocused, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.TabUnfocusedActive, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.Text, text[1], text[2], text[3], text[4])
    ImGui.PushStyleColor(ImGuiCol.TitleBg, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, base[1], base[2], base[3], base[4])
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, dim[1], dim[2], dim[3], dim[4])
    ImGui.PushStyleColor(ImGuiCol.WindowBg, activeTheme.bg[1], activeTheme.bg[2], activeTheme.bg[3], activeTheme.bg[4])
end

function ImGuiExt.PopStyle()
    ImGui.PopStyleColor(34)
    ImGui.PopStyleVar(15)
end

------------------
-- Wrappers
------------------

---@param itemWidth number
---@param horizontalScaling boolean
---@param funcName string
---@return function
function ImGuiExt.DrawWithItemWidth(itemWidth, horizontalScaling, funcName, ...)
    local scaling = horizontalScaling and var.scaleFactor or 1
    ImGui.SetNextItemWidth(itemWidth * scaling)

    return ImGuiExt[funcName](...)
end

---@param regionPos Vector2|ImVec2|table
---@param regionSize Vector2|ImVec2|table
---@param mouseButton number
---@return boolean
function ImGuiExt.IsMouseClickOverRegion(regionPos, regionSize, mouseButton)
    local hovered = ImGui.IsMouseHoveringRect(regionPos.x, regionPos.y, regionPos.x + regionSize.x, regionPos.y + regionSize.y)
    local clicked = hovered and ImGui.IsMouseClicked(mouseButton)
  
    return clicked
end

---@param regionPos Vector2|ImVec2|table
---@param regionSize Vector2|ImVec2|table
---@return boolean
function ImGuiExt.IsMouseHoverOverRegion(regionPos, regionSize)
    local hovered = ImGui.IsMouseHoveringRect(regionPos.x, regionPos.y, regionPos.x + regionSize.x, regionPos.y + regionSize.y)
  
    return hovered
end

------------------
-- Align
------------------

---@param itemWidth number
---@param regionWidth number
---@param padding number?
---@param horizontalScaling boolean?
function ImGuiExt.AlignNextItemToCenter(itemWidth, regionWidth, padding, horizontalScaling)
    local padding = (padding or ImGui.GetStyle().ItemSpacing.x) * 2
    local scaling = horizontalScaling and var.scaleFactor or 1
    local scaledItemWidth = itemWidth * scaling
    local startX = (regionWidth - padding - scaledItemWidth) * 0.5 + padding
    ImGui.SetCursorPosX(startX)
    ImGui.SetNextItemWidth(scaledItemWidth)
end

---@param itemWidth number
---@param regionWidth number
---@param padding number?
---@param horizontalScaling boolean?
function ImGuiExt.AlignNextItemToRight(itemWidth, regionWidth, padding, horizontalScaling)
    padding = (padding or 0) - ImGui.GetStyle().ItemSpacing.x
    local scaling = horizontalScaling and var.scaleFactor or 1
    local scaledItemWidth = itemWidth * scaling
    local startX = regionWidth - scaledItemWidth - padding
    ImGui.SetCursorPosX(startX)
    ImGui.SetNextItemWidth(scaledItemWidth)
end

------------------
-- Draw widgets
------------------

---@param text string
---@param setting boolean
---@param toggle boolean
function ImGuiExt.Checkbox(text, setting, toggle)
    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.textAlt[1], activeTheme.textAlt[2], activeTheme.textAlt[3], activeTheme.textAlt[4])
    setting, toggle = ImGui.Checkbox(text, setting)
    ImGui.PopStyleColor()

    return setting, toggle
end

---@param text string
function ImGuiExt.SetTooltip(text)
    if ImGui.IsItemHovered() and settings.getModSetting("tooltips") then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30)
        ImGui.TextWrapped(text)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

------------------
-- Context Popup
------------------

---@param value any
---@param valueLabel string?
function ImGuiExt.MenuItemCopyValue(value, valueLabel)
    local command

    if value and value ~= "" and value ~= "-" and value ~= "Unknown" and value ~= 0 then
        if valueLabel then
            command = ImGuiExt.TextIcon("Copy " .. valueLabel, IconGlyphs.ContentCopy)
        else
            command = ImGuiExt.TextIcon("Copy", IconGlyphs.ContentCopy)
        end

        if ImGui.MenuItem(command) then
            ImGui.SetClipboardText(tostring(value))
        end
    else
        command = ImGuiExt.TextIcon("Nothing To Copy", IconGlyphs.CheckboxBlankOffOutline)

        ImGui.BeginDisabled()
        ImGui.MenuItem(command)
        ImGui.EndDisabled()
    end
end

------------------
-- Draw text
------------------

---@param text string
---@param wrap boolean?
function ImGuiExt.TextAlt(text, wrap)
    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.textAlt[1], activeTheme.textAlt[2], activeTheme.textAlt[3], activeTheme.textAlt[4])

    if not wrap then
        ImGui.Text(text)
        ImGui.PopStyleColor()
        return
    end

    ImGui.TextWrapped(text)
    ImGui.PopStyleColor()
end

---@param text string
---@param red number
---@param green number
---@param blue number
---@param alpha number
---@param wrap boolean?
function ImGuiExt.TextColor(text, red, green, blue, alpha, wrap)
    ImGui.PushStyleColor(ImGuiCol.Text, red, green, blue, alpha)

    if not wrap then
        ImGui.Text(text)
        ImGui.PopStyleColor()
        return
    end

    ImGui.TextWrapped(text)
    ImGui.PopStyleColor()
end

---@param text string
---@param fontScale number
---@param wrap boolean?
function ImGuiExt.TextScale(text, fontScale, wrap)
    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.text[1], activeTheme.text[2], activeTheme.text[3], activeTheme.text[4])
    ImGui.SetWindowFontScale(fontScale)

    if not wrap then
        ImGui.Text(text)
        ImGui.SetWindowFontScale(1.0)
        ImGui.PopStyleColor()
        return
    end

    ImGui.TextWrapped(text)
    ImGui.SetWindowFontScale(1.0)
    ImGui.PopStyleColor()
end

---@param text string
---@param fontScale number
---@param wrap boolean?
function ImGuiExt.TextAltScale(text, fontScale, wrap)
    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.textAlt[1], activeTheme.textAlt[2], activeTheme.textAlt[3], activeTheme.textAlt[4])
    ImGui.SetWindowFontScale(fontScale)

    if not wrap then
        ImGui.Text(text)
        ImGui.SetWindowFontScale(1.0)
        ImGui.PopStyleColor()
        return
    end

    ImGui.TextWrapped(text)
    ImGui.SetWindowFontScale(1.0)
    ImGui.PopStyleColor()
end

---@param text string
---@param fontScale number
---@param drawBackground boolean?
---@param charCount number?
function ImGuiExt.TextTitle(text, fontScale, drawBackground, charCount)
    ImGui.SetWindowFontScale(fontScale)
    charCount = charCount or 70

    if drawBackground then
        local curPosX, curPosY = ImGui.GetCursorScreenPos()
        local contentRegionAvailX = ImGui.GetContentRegionAvail()
        local textWidth, textHeight = ImGui.CalcTextSize(text)
        local itemSpacingX = ImGui.GetStyle().ItemSpacing.x
        local itemSpacingY = ImGui.GetStyle().ItemSpacing.y
        ImGui.ImDrawListAddRectFilled(ImGui.GetWindowDrawList(),
                                        curPosX - itemSpacingX,
                                        curPosY - (itemSpacingY / 2),
                                        curPosX + contentRegionAvailX + itemSpacingX,
                                        curPosY + textHeight + itemSpacingY,
                                        ImGui.ColorConvertFloat4ToU32(activeTheme.textTitleBg))
    end

    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.textTitle[1], activeTheme.textTitle[2], activeTheme.textTitle[3], activeTheme.textTitle[4])
    ImGui.Text(utils.trimString(text, charCount))
    ImGui.PopStyleColor()
    ImGui.SetWindowFontScale(1.0)
end

---@param text string
---@param iconGlyph any?
function ImGuiExt.TextIcon(text, iconGlyph)
    if iconGlyph then
        return iconGlyph .. " " .. text
    else
        return "      " .. text
    end
end

------------------
-- Notifications
------------------

---@param isActive boolean
local function ShowNotification(isActive)
    var.notification.active = isActive
end

---@param timeSeconds number -- `0` will set a permament notification until next change
---@param text string
---@param hideOnGameMenu boolean?
---@param screenPos ImVec2?
function ImGuiExt.SetNotification(timeSeconds, text, hideOnGameMenu, screenPos)
    ShowNotification(true)
    var.notification.text = text
    var.notification.hideOnGameMenu = hideOnGameMenu

    if screenPos and screenPos.x and screenPos.y then
        var.notification.screenPos = screenPos
    else
        var.notification.screenPos = nil
    end

    if timeSeconds == 0 then return end
    utils.setDelay(timeSeconds, "Notification", ShowNotification, false)
end

function ImGuiExt.Notification()
    if var.notification.active then
        local posX, posY
        local style = ImGui.GetStyle()
        local padding = style.WindowPadding

        if not var.notification.screenPos then
            var.notification.textWidth = ImGui.CalcTextSize(var.notification.text)
            local totalWidth = var.notification.textWidth + 2 * padding.x
            local totalHeight = ImGui.GetTextLineHeight() + 2 * padding.y
            posX = var.screen.width / 2 - totalWidth / 2
            posY = var.screen.height / 2 - totalHeight / 2
        else
            posX = var.notification.screenPos.x
            posY = var.notification.screenPos.y
        end

        ImGui.SetNextWindowPos(posX, posY)
        ImGui.Begin("Notification", true, ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoTitleBar)
        ImGuiExt.TextAlt(var.notification.text)
        ImGui.End()

        if not var.notification.hideOnGameMenu then return end
        if not Game.GetSystemRequestsHandler():IsPreGame() and not Game.GetSystemRequestsHandler():IsGamePaused() then return end
        ShowNotification(false)
    end
end

------------------
-- Search Input
------------------

---@param label string
---@param hint string
local function intializeSearchInput(label, hint)
    searchInputs[label] = {
        hint = ImGuiExt.TextIcon(hint, IconGlyphs.Magnify),
        isActive = nil,
        isTyped = nil,
        newLabel = "##" .. label,
        newQuery = "",
    }
end

---@param label string
---@param query string
---@param hint string
---@param itemWidth number
---@param horizontalScaling boolean?
---@return string
---@return boolean
---@return boolean
function ImGuiExt.SearchInput(label, query, hint, itemWidth, horizontalScaling)
    if searchInputs[label] == nil then
        intializeSearchInput(label, hint)
    end

    if query ~= "" then
        searchInputs[label].hint = query
    else
        searchInputs[label].hint = ImGuiExt.TextIcon(hint, IconGlyphs.Magnify)
    end

    local scaling = horizontalScaling and var.scaleFactor or 1

    ImGui.SetNextItemWidth(itemWidth * scaling)
    searchInputs[label].newQuery, searchInputs[label].isTyped = ImGui.InputTextWithHint(searchInputs[label].newLabel,
                                                                                        query,
                                                                                        searchInputs[label].hint,
                                                                                        40,
                                                                                        ImGuiInputTextFlags.AutoSelectAll)

    if ImGui.IsItemActive() then
        searchInputs[label].isActive = true
    else
        searchInputs[label].isActive = false
    end

    if query ~= searchInputs[label].hint and string.find(searchInputs[label].newQuery, IconGlyphs.Magnify, 1, true) then
        searchInputs[label].newQuery = ""
    end

    return searchInputs[label].newQuery, searchInputs[label].isTyped, searchInputs[label].isActive
end

---@return boolean
function ImGuiExt.IsSearchInputActive(label)
    if searchInputs[label] ~= nil then
        return searchInputs[label].isActive
    else
        return false
    end
end

---@return boolean
function ImGuiExt.IsSearchInputTyped(label)
    if searchInputs[label] ~= nil then
        return searchInputs[label].isTyped
    else
        return false
    end
end

------------------
-- Status Bar
------------------

local function setStatusBarFallback(text)
    statusBars.__fallback = text
end

---@param barName string?
function ImGuiExt.ResetStatusBar(barName)
    if not barName then
        ImGuiExt.SetStatusBar(statusBars.__fallback)
    else
        ImGuiExt.SetStatusBar(statusBars.__fallback, barName)
    end
end

---@param text string
---@param barName string?
function ImGuiExt.SetStatusBar(text, barName)
    if not barName and statusBars.__default.previous == text then return end

    if not barName then
        statusBars.__default.current = text
        statusBars.__default.previous = text
    else
        if not statusBars[barName] then
            statusBars[barName] = { current = "", previous = ""}
        end
        
        local otherStatus = statusBars[barName]

        if otherStatus.previous == text then return end

        otherStatus.current = text
        otherStatus.previous = text
    end
end

---@param barName string?
---@return string
function ImGuiExt.GetStatusBar(barName)
    if not barName then
        return statusBars.__default.current
    else
        local otherStatus = statusBars[barName]

        return otherStatus.current
    end
end

---@param text string
function ImGuiExt.StatusBar(text)
    ImGui.Separator()
    ImGui.TextWrapped(text)
end

---@param text string
function ImGuiExt.StatusBarAlt(text)
    ImGui.Separator()
    ImGui.PushStyleColor(ImGuiCol.Text, activeTheme.textAlt[1], activeTheme.textAlt[2], activeTheme.textAlt[3], activeTheme.textAlt[4])
    ImGui.TextWrapped(text)
    ImGui.PopStyleColor()
end

------------------
-- Tab Bar
------------------

local function initializeTabBar(label)
    tabBars[label] = {
        activeTab = "",
        newLabel = "##" .. label,
        recentlyClosedTabs = {},
        tabs = {},
    }
end

---@param tabBarLabel string
---@param tabLabel string
---@param callback function
---@param title string?
---@return boolean
function ImGuiExt.AddTab(tabBarLabel, tabLabel, title, callback, ...)
    if tabBars[tabBarLabel] == nil then
        initializeTabBar(tabBarLabel)
    end

    if tabBars[tabBarLabel].tabs[tabLabel] ~= nil then
        ImGuiExt.SetActiveTab(tabBarLabel, tabLabel)
 
        return false
    end

    tabBars[tabBarLabel].tabs[tabLabel] = {
        label = tabLabel,
        callback = callback,
        title = title or ""
    }

    if ... ~= nil and type(...) == "table" then
        tabBars[tabBarLabel].tabs[tabLabel].callbackParams = ...
    else
        tabBars[tabBarLabel].tabs[tabLabel].callbackParams = {...} or nil
    end

    return true
end

---@param tabBarLabel string
---@return string
function ImGuiExt.GetActiveTabLabel(tabBarLabel)
    if tabBars[tabBarLabel] ~= nil then
        return tabBars[tabBarLabel].activeTab
    else
        return ""
    end
end

---@param tabBarLabel string
---@param tabLabel string
---@return boolean
function ImGuiExt.SetActiveTab(tabBarLabel, tabLabel)
    if tabBars[tabBarLabel].tabs[tabLabel] ~= nil then
        tabBars[tabBarLabel].tabs[tabLabel].isOld = nil

        return true
    else
        return false
    end
end

---@param tabBarLabel string
---@param flags integer
---@return boolean
function ImGuiExt.TabBar(tabBarLabel, flags)
    if tabBars[tabBarLabel] == nil then
        initializeTabBar(tabBarLabel)
    end

    local tabBar = tabBars[tabBarLabel]

    if next(tabBar.tabs) then
        local activeTab = nil
        for _, tab in pairs(tabBar.tabs) do
            if not tab.isOld then
                activeTab = tab.label
                tab.isOld = true
                break
            end
        end

        if ImGui.BeginTabBar(tabBar.newLabel, flags) then
            for item, tab in pairs(tabBar.tabs) do
                if item then
                    local tabFlags = tab.label == activeTab and ImGuiTabItemFlags.SetSelected or 0

                    tab.isOpen, tab.isActive = ImGui.BeginTabItem(tab.label, true, tabFlags)

                    if tab.isActive then
                        if tab.title ~= "" then
                            ImGuiExt.TextTitle(tab.title, 1.2, false, 75)
                        else
                            ImGui.Spacing()
                        end

                        if tab.callback and type(tab.callback) == "function" then
                            if tab.callbackParams then
                                tab.callback(unpack(tab.callbackParams))
                            else
                                tab.callback()
                            end
                        end

                        ImGui.EndTabItem()

                        tabBar.activeTab = tab.label
                    end
                end

                if not tab.isOpen then
                    tab.isOld = nil
                    tab.isOpen = nil
                    tab.isActive = nil
                    tabBar.activeTab = ""

                    for i, closedTab in ipairs(tabBar.recentlyClosedTabs) do
                        if closedTab.label == tab.label then
                            table.remove(tabBar.recentlyClosedTabs, i)
                            break
                        end
                    end

                    if #tabBar.recentlyClosedTabs > 20 then
                        table.remove(tabBar.recentlyClosedTabs, 1)
                    end

                    table.insert(tabBar.recentlyClosedTabs, tab)
                    tabBar.tabs[item] = nil
                end
            end

            ImGui.EndTabBar()
        end

        return true
    else
        ImGui.Spacing()

        return false
    end
end

---@param tabBarLabel string
function ImGuiExt.CloseInactiveTabs(tabBarLabel)
    if tabBars[tabBarLabel] == nil then return end
    local tabBar = tabBars[tabBarLabel]

    for item, tab in pairs(tabBar.tabs) do
        if not tab.isActive then
            for i, closedTab in ipairs(tabBar.recentlyClosedTabs) do
                if closedTab.label == tab.label then
                    table.remove(tabBar.recentlyClosedTabs, i)
                    break
                end
            end

            local closedNumber = #tabBar.recentlyClosedTabs

            if closedNumber > 20 then
                table.remove(tabBar.recentlyClosedTabs, 1)
            end

            table.insert(tabBar.recentlyClosedTabs, tab)
            tabBar.tabs[item] = nil

            if tabBar.recentlyClosedTabs[closedNumber] ~= nil  then
                tabBar.recentlyClosedTabs[closedNumber].isOld = nil
                tabBar.recentlyClosedTabs[closedNumber].isOpen = nil
            end
        end
    end
end

local function getClosedTabsList(tabBarLabel, closedTabsTable)
    local closedTabsList = {}

    if closedTabsTable ~= nil and next(closedTabsTable) then
        local j = 1

        for i = #closedTabsTable, 1, -1 do
            closedTabsList[j] = {
                label = closedTabsTable[i].label,
                command = function() return ImGuiExt.AddTab(tabBarLabel,
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

---@param tabBarLabel string
---@return table
function ImGuiExt.GetRecentlyClosedTabs(tabBarLabel)
    if tabBars[tabBarLabel] == nil then return {} end

    return tabBars[tabBarLabel].recentlyClosedTabs
end

---@param menuLabel string
---@param tabBarLabel string
function ImGuiExt.BeginMenuRecentlyClosedTabs(menuLabel, tabBarLabel)
    if ImGui.BeginMenu(menuLabel) then
        local closedTabsList = getClosedTabsList(tabBarLabel, ImGuiExt.GetRecentlyClosedTabs(tabBarLabel))

        if next(closedTabsList) then
            for _, entry in ipairs(closedTabsList) do
                if ImGui.MenuItem(entry.label) then
                    entry.command()
                end
            end
        else
            ImGui.BeginDisabled()
            ImGui.MenuItem("---")
            ImGui.EndDisabled()
        end

        ImGui.EndMenu()
    end
end

function ImGuiExt.BeginMenuOpenedTabs(menuLabel, tabBarLabel)
    if ImGui.BeginMenu(menuLabel) then
        local openedTabsList = tabBars[tabBarLabel].tabs

        if next(openedTabsList) then
            for _, entry in pairs(openedTabsList) do
                if ImGui.MenuItem(entry.label) then
                    ImGuiExt.SetActiveTab(tabBarLabel, entry.label)
                end
            end
        else
            ImGui.BeginDisabled()
            ImGui.MenuItem("---")
            ImGui.EndDisabled()
        end

        ImGui.EndMenu()
    end
end

------------------
-- Themes
------------------

local function getThemesList()
    local i = 1
    local themesDir = dir('themes')
    local themesList = {}

    for _, theme in pairs(themesDir) do
        if string.find(theme.name, '%.json$') then
            themesList[i] = string.gsub(theme.name, "%.json$", "")
            i = i + 1
        end
    end

    return themesList
end

local function isValidTheme(theme)
    local colors = {"text", "textAlt", "bg", "base", "dim", "pop"}

    for _, color in ipairs(colors) do
        if not theme[color] then
            return false
        end
    end

    for _, color in pairs(theme) do
        if type(color) ~= "table" then
            return false
        end

        if colors[color] ~= nil then
            if #color ~= 4 then
                return false
            end
                
            for _, v in ipairs(color) do
                if type(v) ~= "number" or v < 0 or v > 1 then
                    return false
                end
            end
        end
    end

    return true
end

---@return string
function ImGuiExt.GetActiveThemeName()
    return activeThemeName
end

--- Avaiable elements: `text, textAlt, textTitle, base, border, bg,
--- dim, pop, scrollbar.base, scrollbar.dim, scrollbar.pop,
--- separator, tab.base`
---@param elementName string
---@return float (red)
---@return float (green)
---@return float (blue)
---@return float (alpha)
function ImGuiExt.GetActiveThemeColor(elementName)
    if activeTheme ~= nil then
        local color = activeTheme[elementName]

        return color[1], color[2], color[3], color[4]
    else
        return 1, 1, 1, 1
    end
end

---@param themeName string
function ImGuiExt.SetActiveTheme(themeName)
    local themePath
    local theme

    if themeName then
        themePath = "themes/" .. themeName .. ".json"
        theme = utils.loadJson(themePath)
    else
        theme = nil
    end

    if theme and isValidTheme(theme) then
        activeTheme = tables.mergeTables(fallbackTheme, theme)
        activeThemeName = themeName
     
        return true
    else
        activeTheme = tables.mergeTables(activeTheme, fallbackTheme)
        activeThemeName = "Default"

        return false
    end
end

function ImGuiExt.ThemesCombo()
    if ImGui.BeginCombo("##Themes", ImGuiExt.GetActiveThemeName()) then
        local themesList = getThemesList()

        for _, themeName in ipairs(themesList) do
            local isSelected = (ImGuiExt.GetActiveThemeName() == themeName)

            if ImGui.Selectable(themeName, isSelected) then
                ImGuiExt.SetActiveTheme(themeName)
            end

            if isSelected then
                ImGui.SetItemDefaultFocus()
            end
        end

        ImGui.EndCombo()
    end
end

------------------
-- Registers
------------------

---@param themeName string
---@param statusBarFallbackText string
function ImGuiExt.onInit(themeName, statusBarFallbackText)
    setStatusBarFallback(statusBarFallbackText)
    ImGuiExt.ResetStatusBar()
    ImGuiExt.SetActiveTheme(themeName)
    setupScreen()
end

function ImGuiExt.onOverlayOpen()
    setupScreen()
end

function ImGuiExt.onOverlayClose()
    ImGuiExt.ResetStatusBar()
end

return ImGuiExt