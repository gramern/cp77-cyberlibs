local gameModules = {
  __NAME = "Game Modules",
  __VERSION = { 0, 2, 0},
}

local ImGuiExt = require("globals/ImGuiExt")
local logger = require("globals/logger")
local localization = require("globals/localization")
local search = require("globals/search")
local settings = require("globals/settings")
local style = require("globals/custom/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

return gameModules