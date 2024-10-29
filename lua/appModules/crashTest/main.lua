local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local tables = require("globals/tables")
local utils = require("globals/utils")

local isRandomSeed = false
local elementsToPick = 50
local interval = 1

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
        if module.fileName == "Cyberpunk2077.exe" then
            filePath = module.filePath

            parseModule(filePath, moduleData)
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

    logger.debug(pickedCount, tables.tableToString(picked, true))
    ImGuiExt.SetNotification(interval - 0.2, "Crash Test In Progress...", false, ImVec2.new(40, 40))
    utils.setDelay(interval, "crashTest", executeCrashTest)
end

local function initializeCrashTest()
    if not app.isAppModule("gameModules") then
        logger.warning("Install \"Game Modules\" app module to continue...")
        ImGuiExt.SetNotification(3, "Install \"Game Modules\" app module to continue...", false)

        return
    end

    if not isRandomSeed then
        math.randomseed(os.time())

        isRandomSeed = true
    end

    if isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Test Initialized")
    utils.setDelay(interval, "crashTest", executeCrashTest)
end

local function stopCrashTest()
    if not isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Test Cancelled")
    utils.cancelDelay("crashTest")
end

local function draw()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()

    ImGui.Spacing()
    ImGui.SetNextItemWidth(150)

    elementsToPick = ImGui.SliderFloat("##Number of modules to parse on each tick", elementsToPick, 1, 200, "%.0f")

    ImGuiExt.SetTooltip("1 = parse \"Cyberpunk2077.exe\" only")
    ImGui.SameLine()
    ImGuiExt.TextAlt("Number of modules to parse on each tick")
    ImGui.SetNextItemWidth(150)

    interval = ImGui.SliderFloat("##Tick duration", interval, 0.5, 2, "%.1f")

    ImGui.SameLine()
    ImGuiExt.TextAlt("Tick duration (s)")
    ImGui.Spacing()
    ImGui.Spacing()

    ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    if not isCrashTest() then
        if ImGui.Button("Start Crash Test", 300, 0) then
            initializeCrashTest()
        end

        ImGui.Spacing()

        local text = "The test may cause noticeable game lag."
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