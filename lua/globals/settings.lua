-- settings.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local settings = {
    __VERSION = { 0, 2, 0 },
}

local modSettings = {}

local userSettings = {}

local logger = require("globals/logger")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- Saving Reqests
------------------

local isSaveRequest = false

---@return boolean
function settings.issaveRequest()
    return isSaveRequest
end

local function resetsaveRequest()
    isSaveRequest = false
end

local function saveRequest()
    isSaveRequest = true
end

------------------
-- Mod Settings
------------------

local function loadModSettings(newSettings)
    modSettings.debugMode = newSettings and newSettings.debugMode or false

    if newSettings == nil then return end

    for setting, value in pairs(newSettings) do
        modSettings[setting] = value or nil
    end
end

local function saveModSettings()
    settings.writeUserSettings("modSettings", modSettings)
end

---@return boolean
function settings.isDebugMode()
    return modSettings.debugMode
end

---@param isDebugMode boolean
function settings.setDebugMode(isDebugMode)
    modSettings.debugMode = isDebugMode

    saveRequest()
end

---@param name string
---@return any|nil
function settings.getModSetting(name)
    return modSettings[name] or nil
end

---@param name string
---@param value any
function settings.setModSetting(name, value)
    modSettings[name] = value

    saveRequest()
end

------------------
-- User Settings
------------------

---@param poolName string
---@param contents table
function settings.writeUserSettings(poolName, contents)
    local copiedContents = tables.deepcopy(contents)

    userSettings[poolName] = copiedContents

    saveRequest()
end

---@param poolName string
function settings.getUserSettings(poolName)
    if not poolName then
        return userSettings or nil
    elseif userSettings[poolName] == nil then return nil end

    return userSettings[poolName]
end

------------------
-- File Handling
------------------

local function loadFile()
    local userSettingsContents = tables.deepcopy(utils.loadJson("user-settings"))

    if userSettingsContents then
        userSettings = tables.deepcopy(userSettingsContents)

        logger.info("User settings loaded.")
        return true
    else
        logger.info("User settings not found.")
        return false
    end
end

local function saveFile()
    if not isSaveRequest then return end 

    saveModSettings()

    local result = utils.saveJson("user-settings", userSettings)

    if result then
        resetsaveRequest()
        logger.info("User settings saved to file.")
    else
        resetsaveRequest()
        logger.info("Failed to save user settings to file.")
    end
end

------------------
-- Registers
------------------

function settings.onInit()
    loadFile()
    loadModSettings(settings.getUserSettings("modSettings"))
end

function settings.onOverlayOpen()
    if userSettings == nil then
        local isFile = loadFile()

        if isFile then
            loadModSettings(settings.getUserSettings("modSettings"))
        else
            saveRequest()
        end
    end
end

function settings.onOverlayClose()
    saveFile()
end

return settings