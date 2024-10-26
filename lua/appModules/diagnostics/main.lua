local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local search = require("globals/search")
local settings = require("globals/settings")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

local function draw()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x

    ImGui.BeginChildFrame(ImGui.GetID("RootWindow.Settings"),
                            itemWidth,
                            656 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)


    ImGui.EndChildFrame()
end

local function dumpLoadedMods()
    local modules = app.categorizeLoadedModules(app.getLoadedModules())
    local reportsDir = "Reports"
    local filePath = reportsDir .. "/" .. "LoadedModsLibraries-" .. GameDiagnostics.GetTimestamp(true) .. ".txt"

    GameDiagnostics.WriteToOutput(filePath, "Loaded Mods Modules Report\nGenerated in Cyberlibs on " .. GameDiagnostics.GetTimestamp())
    GameDiagnostics.WriteToOutput(filePath, "\n\n" .. style.formatHeader("Mods Resources"), true)

    local modsResourceAmount = 0

    for _, module in ipairs(modules) do
        if module.category == "mods resource" then
            GameDiagnostics.WriteToOutput(filePath, "\n" .. style.formatEntry(module.fileName .. " Version: " .. Cyberlibs.GetVersion(module.filePath)), true)

            modsResourceAmount = modsResourceAmount + 1
        end
    end

    GameDiagnostics.WriteToOutput(filePath, "\n" .. style.formatFooter(modsResourceAmount), true)
    GameDiagnostics.WriteToOutput(filePath, "\n\n" .. style.formatHeader("Mods / Unknown"), true)

    local modAmount = 0

    for _, module in ipairs(modules) do
        if module.category == "mod / unknown" then
            GameDiagnostics.WriteToOutput(filePath, "\n" .. style.formatEntry(module.filePath .. " Version: " .. Cyberlibs.GetVersion(module.filePath)), true)

            modAmount = modAmount + 1
        end
    end

    GameDiagnostics.WriteToOutput(filePath, "\n" .. style.formatFooter(modAmount), true)
end

return {
    __NAME = "Diagnostics",
    __ICON = IconGlyphs.Stethoscope,
    draw = draw,
    inputs = {
        { id = "dumpLoadedMods", description = "Dump Loaded Mods Modules", keyPressCallback = dumpLoadedMods },
    }
}