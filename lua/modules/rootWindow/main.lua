local rootWindow = {
  __VERSION = { 0, 2, 0},
}

local thirdparty = require("thirdparty")

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local localization = require("globals/localization")
local search = require("globals/search")
local settings = require("globals/settings")
local tables = require("globals/tables")
local utils = require("globals/utils")

-- ------------------
-- -- API
-- ------------------

-- local publicApi = require("api/publicApi")


local help = require("knowledgeBase/help")

local tabAboutVars = {
  pluginVersion = "",
  luaGuiVersion = "",
  licenses = ""
}

local tabHelpVars = {
  selectedTopic = "",
  selectedTopicContent = "",
  topicsPool = {},
  commands = {
    jumpToSelected = false,
    collapseOther = false,
    collapseAll = false
  },
  states = {
    isTreeContextPopup = false,
  }
}

local function nameFilterInstance(name)
  return "RootWindow.SearchInput." .. name
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

  ImGui.BeginChildFrame(ImGui.GetID("HelpTopicView"), itemWidth, 300, ImGuiWindowFlags.AlwaysHorizontalScrollbar)
  ImGui.Text(tabAboutVars.licenses)
  ImGui.EndChildFrame()

  if tabAboutVars.pluginVersion ~= "" then return end
  tabAboutVars.pluginVersion = Cyberlibs.Version()
  tabAboutVars.luaGuiVersion = Cyberlibs.Version()
  tabAboutVars.licenses = utils.indentString(Cyberlibs.__LICENSE .. "\n" .. thirdparty, -10, true)
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

  ImGui.BeginChildFrame(ImGui.GetID("RootWindow.Help.TopicsTree"), itemWidth, 200, ImGuiWindowFlags.HorizontalScrollbar + ImGuiWindowFlags.NoBackground)

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
    if ImGui.MenuItem("Jump to selection") then
      tabHelpVars.commands.jumpToSelected = true
    end

    ImGui.Separator()

    if ImGui.MenuItem("Collapse other") then
      tabHelpVars.commands.collapseOther = true
    end

    if ImGui.MenuItem("Collapse all") then
      tabHelpVars.commands.collapseAll = true
    end

    ImGui.EndPopup()
  end

  ImGui.Spacing()
  ImGui.InputTextMultiline("##RootWindow.Help.Viewer", tabHelpVars.selectedTopicContent, 7000, itemWidth, 300, ImGuiInputTextFlags.ReadOnly)
end

local function drawTabSettings()
  ImGuiExt.TextAlt("Window Theme:")
  ImGuiExt.DrawWithItemWidth(300, "ThemesCombo")
  ImGuiExt.SetTooltip("Select mod's window theme.")
  ImGui.SameLine()

  if ImGui.Button("Save",  100 * ImGuiExt.GetScaleFactor(), 0) then
    settings.setTheme(ImGuiExt.GetActiveThemeName())

    ImGuiExt.SetStatusBar("Settings saved.")
  end
end

local function getClosedTabsList(closedTabsTable)
  local closedTabsList = {}

  if next(closedTabsTable) then
    local j = 1

    for i = #closedTabsTable, 1, -1 do
      closedTabsList[j] = {
        label = closedTabsTable[i].label,
        command = function() return ImGuiExt.AddTab("RootWindow.TabBar", closedTabsTable[i].label, closedTabsTable[i].content, closedTabsTable[i].title) end
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
    drawRecentlyClosedTabsMenu()

    local tabBarLabel = "RootWindow.TabBar"

    if ImGui.MenuItem("Settings") then
      ImGuiExt.AddTab(tabBarLabel, "Settings", drawTabSettings, "Cyberlibs Settings:")
    end

    ImGui.Separator()

    if ImGui.MenuItem("Help") then
      ImGuiExt.AddTab(tabBarLabel, "Help", drawTabHelp, "Help Topics")
    end

    if ImGui.MenuItem("About") then
      ImGuiExt.AddTab(tabBarLabel, "About", drawTabAbout, "About Cyberlibs")
    end

    ImGui.EndPopup()
  end
end

function rootWindow.draw()
  local activeTabLabel = ImGuiExt.GetActiveTabLabel("RootWindow.TabBar")

  if activeTabLabel == "" then
    search.updateFilterInstance(nameFilterInstance("Default"))
  else
    search.updateFilterInstance(nameFilterInstance(activeTabLabel))
  end

  ImGuiExt.PushWindowMinSize(480, 60)
  ImGuiExt.PushStyle()
  ImGui.SetNextWindowPos(400, 200, ImGuiCond.FirstUseEver)

  if ImGui.Begin(Cyberlibs.__NAME, ImGuiWindowFlags.AlwaysAutoResize) then

    local activeFilter = search.getActiveFilter()
    local isTyping

    activeFilter.query, isTyping = ImGuiExt.SearchInput(activeFilter.label, activeFilter.query, "Search...", 480)
    if isTyping then
      search.setFiltering(true)

      utils.SetDelay(1, "RootWindow.SearchInput", search.setFiltering, false)
    end

    ImGui.SameLine()
    ImGui.Button(IconGlyphs.DotsVertical)
    drawRootPopupMenu()
    ImGui.Separator()

    if not ImGuiExt.TabBar("RootWindow.TabBar") then
      local textWidth = ImGui.CalcTextSize("Open Cyberlibs' module or a file to start.")
      ImGui.Text("")
      ImGuiExt.AlignNextItemToWindowCenter(textWidth, ImGui.GetWindowWidth(), ImGui.GetStyle().WindowPadding.x)
      ImGuiExt.TextAlt("Open Cyberlibs' module or a file to start.")
      ImGui.Text("")
      ImGuiExt.AlignNextItemToWindowCenter(380, ImGui.GetWindowWidth(), ImGui.GetStyle().WindowPadding.x)
      ImGui.Button("Open Cyberlibs' module or a file to start.", 380, 0)
    end

    ImGuiExt.StatusBarAlt(ImGuiExt.GetStatusBar())
  end

  ImGui.End()
  ImGuiExt.PopStyle()
end

return rootWindow