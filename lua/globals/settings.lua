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
  modSettings.isDebugMode = newSettings and newSettings.debugMode or false
  modSettings.isDebugView = newSettings and newSettings.debugView or false
  modSettings.isHelp = newSettings and newSettings.help or true
  modSettings.isKeepWindow = newSettings and newSettings.keepWindow or false
  modSettings.languageCode = newSettings and newSettings.language or "en-us"
  modSettings.windowTheme = newSettings and newSettings.windowTheme or nil
end

local function saveModSettings()
  local savedSettings = {
    debugMode = modSettings.isDebugMode,
    debugView = modSettings.isDebugView,
    help = modSettings.isHelp,
    keepWindow = modSettings.isKeepWindow,
    language = modSettings.languageCode,
    windowTheme = modSettings.windowTheme
  }

  settings.writeUserSettings("modSettings", savedSettings)
end

---@return boolean
function settings.isDebugMode()
  return modSettings.isDebugMode
end

---@param isDebugMode boolean
function settings.setDebugMode(isDebugMode)
  modSettings.isDebugMode = isDebugMode

  saveRequest()
end

---@return boolean
function settings.isDebugView()
  return modSettings.isDebugView
end

---@param isDebugView boolean
function settings.setDebugView(isDebugView)
  modSettings.isDebugView = isDebugView
  saveRequest()
end

---@return boolean
function settings.isHelp()
  return modSettings.isHelp
end

---@param isHelp boolean
function settings.setHelp(isHelp)
  modSettings.isHelp = isHelp

  saveRequest()
end

---@return boolean
function settings.isKeepWindow()
  return modSettings.isKeepWindow
end

---@param isKeepWindow boolean
function settings.setKeepWindow(isKeepWindow)
  modSettings.isKeepWindow = isKeepWindow

  saveRequest()
end

---@return string
function settings.getLanguage()
  return modSettings.languageCode
end

---@param languageCode string
function settings.setLanguage(languageCode)
  modSettings.languageCode = languageCode

  saveRequest()
end

---@return string
function settings.getTheme()
  return modSettings.windowTheme
end

---@param themeName string
function settings.setTheme(themeName)
  modSettings.windowTheme = themeName

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