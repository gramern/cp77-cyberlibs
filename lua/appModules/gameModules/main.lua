local app = ...

local gameModules = {
    __NAME = "Game Modules",
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

local loadedModules = {}

local modulesData = {}

-- local viewerVars = {
--     openedModules = {},
--     states = {}
-- }

local function getLoadedModules()
    local modulesArray = GameModule.GetLoadedModules()
    local t = {}

    for i, module in ipairs(modulesArray) do
        local fileName = utils.getFileName(module)

        t[i] = {
            fileName = fileName,
            filePath = module
        }
    end

    return t
end

local function drawViewerRow(label, value, rowWidth)
    ImGui.BeginGroup()
    ImGuiExt.TextAlt(label)
    ImGui.SameLine()
    ImGui.SetCursorPosX(200)
    ImGui.SetNextItemWidth(rowWidth - 200)
    ImGui.InputText('##' .. label, value, 256)
    ImGui.EndGroup()
end

local function getModule(fileName)
    if modulesData[fileName] == nil then return nil end

    return modulesData[fileName]
end

local function openModule(fileName, filePath)
    if getModule(fileName) then
        modulesData[fileName] = {}
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
        ["Time Date Stamp"] = GameModule.GetTimeDateStamp(filePath),
        ["Version"] = Cyberlibs.GetVersion(filePath)
    }

    modulesData[fileName] = tables.deepcopy(moduleData)
end

local function drawModuleTab(fileName, filePath)
    if getModule(fileName) == nil then
        openModule(fileName, filePath)
    end

    local moduleData = getModule(fileName)
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
                            250 * ImGuiExt.GetScaleFactor(),
                            ImGuiWindowFlags.NoBackground)

    for name, attribute in pairs(moduleData) do
        if type(attribute) ~= "table" then
            drawViewerRow(name, tostring(attribute), ImGui.GetContentRegionAvail())
        end
    end

    ImGui.EndChildFrame()
end

local function addModuleTab(fileName, filePath)
    if getModule(fileName) == nil then
        openModule(fileName, filePath)
    end

    ImGuiExt.AddTab("RootWindow.TabBar", fileName, "", drawModuleTab, fileName, filePath)
end

function gameModules.draw()
    local itemWidth = ImGui.GetWindowWidth() - 2 * ImGui.GetStyle().WindowPadding.x

    ImGui.BeginChildFrame(ImGui.GetID("GameModulesViewer"), itemWidth, 400 * ImGuiExt.GetScaleFactor())

    for _, module in ipairs(loadedModules)do
        if ImGui.Selectable(module.fileName) then
            addModuleTab(module.fileName, module.filePath)
        end
    end

    ImGui.EndChildFrame()

    if next(loadedModules) ~= nil then return end
    loadedModules = getLoadedModules()
end

return gameModules