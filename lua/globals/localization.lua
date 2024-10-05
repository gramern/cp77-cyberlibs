-- localization.lua
-- A part of "globals" pack for CET lua mods
-- (c) gramern 2024

local localization = {
  __VERSION = { 0, 2, 0 },
}

local uiText = {}

local logText = {}

local var = {
  gameOnScreenLang = nil,
  localizationsDir = "localizations",
  modDefaultLang = "en-us",
  modOnScreenLang = nil,
}

local tables = require("globals/tables")
local utils = require("Modules/Globals")

------------------
-- Getters
------------------

function localization.getUIText(nestedTable)
  if nestedTable then
    return uiText[nestedTable]
  else
    return uiText
  end
end

function localization.getLogText()
  return logText
end

function localization.getOnScreenLanguage()
  var.gameOnScreenLang = Game.NameToString(Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue())

  return var.gameOnScreenLang
end

local function setLocalization(languageCode)

end

------------------
-- Registers
------------------

function localization.onOverlayOpen(languageCode)
  -- setLocalization(languageCode)
end

return localization