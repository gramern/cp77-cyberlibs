local app = ...

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local tables = require("globals/tables")
local utils = require("globals/utils")

local isRandomSeed = false
local min, random = math.min, math.random
local insert, remove = table.insert, table.remove

local function isCrashTest()
    return utils.isDelay("crashTest")
end

local function executeCrashTest()
    local loadedModules = app.getLoadedModules()
    local lodadedNumber = #loadedModules
    local elementsNumber = 50
    local filePath
    local moduleData = {}

    if not next(loadedModules) then
        print("Received empty list.")

        return {}
    end

    for _, module in ipairs(loadedModules) do
        if module.fileName == "Cyberpunk2077.exe" then
            filePath = module.filePath

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
    end

    local pickedNumber = min(elementsNumber, lodadedNumber)
    local picked = {}

    for i = 1, pickedNumber do
        local randomIndex = random(1, lodadedNumber)
        insert(picked, loadedModules[randomIndex])
        remove(loadedModules, randomIndex)
    end

    for _, module in ipairs(picked) do
        filePath = module.filePath

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

    logger.debug(pickedNumber, tables.tableToString(picked, true))
    ImGuiExt.SetNotification(0.8, "Crash Test In Progress...", true, ImVec2.new(40, 40))
    utils.setDelay(1, "crashTest", executeCrashTest)
end

local function initializeCrashTest()
    if not isRandomSeed then
        math.randomseed(os.time())

        isRandomSeed = true
    end

    if isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Testing Initialized")
    utils.setDelay(1, "crashTest", executeCrashTest)
end

local function stopCrashTest()
    if not isCrashTest() then return end
    ImGuiExt.SetNotification(3, "Crash Testing Cancelled")
    utils.cancelDelay("crashTest")
end

local function draw()
    local contentRegionAvailX = ImGui.GetContentRegionAvail()

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
    ImGuiExt.AlignNextItemToCenter(300, contentRegionAvailX)

    if not isCrashTest() then
        if ImGui.Button("Start Crash Test", 300, 0) then
            initializeCrashTest()
        end

        ImGui.Text("")

        local text = "Crash test generates heavy prints to logs when debug mode is turned ON"
        local textWidth = ImGui.CalcTextSize(text)

        ImGuiExt.AlignNextItemToCenter(textWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(text)
    else
        if ImGui.Button("Stop Crash Test", 300, 0) then
            stopCrashTest()
        end
        
        ImGui.Text("")

        local text = "Crash Test In Progress..."
        local textWidth = ImGui.CalcTextSize(text)

        ImGuiExt.AlignNextItemToCenter(textWidth, contentRegionAvailX)
        ImGuiExt.TextAlt(text)
    end

    ImGui.Dummy(100, 30 * ImGuiExt.GetResolutionFactor())
end

return {
    __NAME = "Crash Test",
    __VERSION = { 0, 2, 0},
    draw = draw,
    inputs = {
        { id = "intializeCrashTest", description = "Initalize Crash Testting", keyPressCallback = initializeCrashTest },
        { id = "stopCrashTest", description = "Stop Crash Testing", keyPressCallback = stopCrashTest },
    }
}