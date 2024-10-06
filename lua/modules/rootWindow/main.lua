local rootWindow = {
  __VERSION = { 0, 2, 0},
}

local thirdparty = require("thirdparty")

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local localization = require("globals/localization")
local search = require("globals/search")
local settings = require("globals/settings")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- API
------------------

local publicApi = require("api/publicApi")

local tabAboutVar = {
  pluginVersion = "",
  luaGuiVersion = "",
  licenses = ""
}

local searchCompVar = {
  query = "",
}

local function getClosedTabsList(closedTabs)
  local closedTabsList = {}

  if next(closedTabs) then
    local j = 1

    for i = #closedTabs, 1, -1 do
      closedTabsList[j] = {
        label = closedTabs[i].label,
        command = function() return ImGuiExt.AddTab("RootWindow.TabBar", closedTabs[i].label, closedTabs[i].content, closedTabs[i].title) end
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

    if ImGui.MenuItem("Settings") then
      ImGuiExt.AddTab("RootWindow.TabBar", "Settings", rootWindow.drawTabSettings, "Cyberlibs Settings:")
    end

    ImGui.Separator()

    if ImGui.MenuItem("About") then
      ImGuiExt.AddTab("RootWindow.TabBar", "About", rootWindow.drawTabAbout, "About Cyberlibs")
    end

    ImGui.EndPopup()
  end
end

function rootWindow.drawTabAbout()
  local windowWidth = ImGui.GetWindowWidth()

  ImGuiExt.TextAlt("Plugin Version:")
  ImGui.SameLine()
  ImGuiExt.TextAlt(tabAboutVar.pluginVersion)
  ImGuiExt.TextAlt("Lua GUI Version:")
  ImGui.SameLine()
  ImGuiExt.TextAlt(tabAboutVar.luaGuiVersion)
  ImGui.Text("")
  ImGuiExt.TextAlt("License & Third Party")
  ImGui.InputTextMultiline("##License", tabAboutVar.licenses, 7000, windowWidth - 2 * ImGui.GetStyle().WindowPadding.x, 320, ImGuiInputTextFlags.ReadOnly)

  if tabAboutVar.pluginVersion ~= "" then return end
  tabAboutVar.pluginVersion = Cyberlibs.Version()
  tabAboutVar.luaGuiVersion = Cyberlibs.Version()
  tabAboutVar.licenses = Cyberlibs.__LICENSE .. "\n" .. thirdparty[1]
end

function rootWindow.drawTabHelp()

end

function rootWindow.drawTabSettings()
  ImGuiExt.TextAlt("Window Theme:")
  ImGuiExt.DrawWithItemWidth(300, "ThemesCombo")
  ImGuiExt.SetTooltip("Select mod's window theme.")
  ImGui.SameLine()

  if ImGui.Button("Save",  100 * ImGuiExt.GetScaleFactor(), 0) then
    settings.setTheme(ImGuiExt.GetActiveThemeName())

    ImGuiExt.SetStatusBar("Settings saved.")
  end
end



function rootWindow.draw()
  ImGuiExt.PushWindowMinSize(480, 60)
  ImGuiExt.PushStyle()
  ImGui.SetNextWindowPos(400, 200, ImGuiCond.FirstUseEver)

  if ImGui.Begin(Cyberlibs.__NAME, ImGuiWindowFlags.AlwaysAutoResize) then

    searchCompVar.query, searchCompVar.isTyped = ImGuiExt.SearchInput("RootWindow.SearchInput", searchCompVar.query, "Search...", 480)
    if searchCompVar.isTyped then
      print(searchCompVar.query)
    end

    ImGui.SameLine()

    if ImGui.Button(IconGlyphs.DotsVertical) then
      print("menu click")
    end

    drawRootPopupMenu()
    ImGui.Separator()
    ImGuiExt.TabBar("RootWindow.TabBar")
    ImGuiExt.StatusBarAlt(ImGuiExt.GetStatusBar())
  end

  ImGui.End()
  ImGuiExt.PopStyle()
end

return rootWindow