local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local tables = require("globals/tables")
local utils = require("globals/utils")

local elementsToPick = 50
local isRandomSeed = false
local instances = 1
local interval = 1
local fileName = "Cyberpunk2077.exe"

local min, random = math.min, math.random
local insert, remove = table.insert, table.remove

local function isCrashTest()
    return utils.isDelay("crashTest")
end

local function parseModule(filePath, moduleData)
    moduleData = {
        ["Company Name"] = GameModules.GetCompanyName(filePath),
        ["Description"] = GameModules.GetDescription(filePath),
        ["Entry Point"] = GameModules.GetEntryPoint(filePath),
        ["Export"] = GameModules.GetExport(filePath),
        ["File Size"] = GameModules.GetFileSize(filePath),
        ["File Type"] = GameModules.GetFileType(filePath),
        ["Import"] = GameModules.GetImport(filePath),
        ["Load Address"] = GameModules.GetLoadAddress(filePath),
        ["Mapped Size"] = GameModules.GetMappedSize(filePath),
        ["TimeDateStamp"] = GameModules.GetTimeDateStamp(filePath),
        ["Version"] = Cyberlibs.GetVersion(filePath)
    }

    if moduleData["Version"] ~= nil then
        return true
    else
        return false
    end
end

local function executeCrashTest()
    local loadedModules = app.getLoadedModules()
    local lodadedCount = #loadedModules
    local filePath
    local moduleData = {}

    if not next(loadedModules) then
        print("Received empty list.")

        return {}
    end

    for _, module in ipairs(loadedModules) do
        if module.fileName == fileName then
            filePath = module.filePath

            if parseModule(filePath, moduleData) then
                logger.debug("Parsed", fileName)
            end

            break
        end
    end

    local pickedCount = min(elementsToPick - 1, lodadedCount)
    local picked = {}

    for i = 1, pickedCount do
        local randomIndex = random(1, lodadedCount)
        insert(picked, loadedModules[randomIndex])
        remove(loadedModules, randomIndex)
    end

    for _, module in ipairs(picked) do
        filePath = module.filePath

        parseModule(filePath, moduleData)
    end

    if pickedCount > 0 then
        logger.debug(pickedCount, tables.tableToString(picked, true))
    end
end

local function handleCrashTest()
    for i = 1, instances do
        executeCrashTest()
    end

    ImGuiExt.SetNotification(interval - 0.2, "Crash Test In Progress...", false, ImVec2.new(40, 40))
    utils.setDelay(interval, "crashTest", handleCrashTest)
end

local function initializeCrashTest()
    if not app.isAppModule("gameModules") then
        logger.warning("Install \"Game Modules\" app module to continue...")
        ImGuiExt.SetNotification(3, "Install \"Game Modules\" app module to continue...", false)

        return
    end

    if not GameModules.IsLoaded(fileName) then
        logger.warning("Can't find module:", fileName)

        return
    end

    if not isRandomSeed then
        math.randomseed(os.time())

        isRandomSeed = true
    end

    if isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Test Initialized")
    utils.setDelay(interval, "crashTest", handleCrashTest)
end

local function stopCrashTest()
    if not isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Test Cancelled")
    utils.cancelDelay("crashTest")
end

local function draw()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()
    local windowPadding = ImGui.GetStyle().WindowPadding

    ImGui.Spacing()
    ImGui.SetNextItemWidth(150)

    if isCrashTest() then
        ImGui.BeginDisabled()
    end

    instances = ImGui.SliderFloat("##Number of instances to fire simultaneously on each tick", instances, 1, 5, "%.0f")

    ImGui.SameLine()
    ImGuiExt.TextAlt("Number of instances to fire simultaneously on each tick")
    ImGui.SetNextItemWidth(150)

    elementsToPick = ImGui.SliderFloat("##Number of modules to parse per instance on each tick", elementsToPick, 1, 200, "%.0f")

    ImGuiExt.SetTooltip("1 = parse selected module only")
    ImGui.SameLine()
    ImGuiExt.TextAlt("Number of modules to parse per instance on each tick")

    if elementsToPick == 1 then
        ImGui.Spacing()
        ImGui.Indent(windowPadding.x)
        ImGui.SetNextItemWidth(200)

        fileName = ImGui.InputText("##Module To Parse", fileName, 32768)

        ImGui.SameLine()
        ImGuiExt.TextAlt("Module's file name or path")
        ImGui.Indent(- windowPadding.x)
        ImGui.Spacing()
    else
        fileName = "Cyberpunk2077.exe"
    end

    ImGui.SetNextItemWidth(150)

    interval = ImGui.SliderFloat("##Tick duration", interval, 0.5, 2, "%.1f")

    ImGui.SameLine()
    ImGuiExt.TextAlt("Tick duration (s)")

    if isCrashTest() then
        ImGui.EndDisabled()
    end

    ImGui.Spacing()
    ImGui.Spacing()

    ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    if not isCrashTest() then
        if ImGui.Button("Start Crash Test", 300, 0) then
            initializeCrashTest()
        end

        ImGui.Spacing()

        local text = "The heavier the test, the more noticeable game lag."
        local textWidth = ImGui.CalcTextSize(text)

        ImGuiExt.AlignNextItemToCenter(textWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(text)

        text = "Crash test generates heavy prints to logs when the app's debug mode is turned ON."
        textWidth = ImGui.CalcTextSize(text)

        ImGuiExt.AlignNextItemToCenter(textWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(text)
    else
        if ImGui.Button("Stop Crash Test", 300, 0) then
            stopCrashTest()
        end
        
        ImGui.Spacing()

        local text = "Crash Test In Progress..."
        local textWidth = ImGui.CalcTextSize(text)

        ImGuiExt.AlignNextItemToCenter(textWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(text)
    end

    ImGui.Text("")
end

return {
    __NAME = "Crash Test",
    __TITLE = "Loaded Modules Heavy Parsing Crash Test",
    draw = draw,
    inputs = {
        { id = "intializeCrashTest", description = "Initalize Crash Test", keyPressCallback = initializeCrashTest },
        { id = "stopCrashTest", description = "Stop Crash Test", keyPressCallback = stopCrashTest },
    }
}