Cyberlibs = {
  __NAME = "Cyberlibs",
  __EDITION = nil,
  __VERSION = { 0, 2, 0},
  __VERSION_SUFFIX = nil,
  __VERSION_STATUS = "alpha",
  __DESCRIPTION = "Diagnostics tool to inspect and parse libraries loaded by Cyberpunk 2077 during runtime.",
  __LICENSE = [[
    MIT License

    Copyright (c) 2024 gramern

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]],
}

------------------
-- Globals
------------------

local logger = require("globals/logger")
local ImGuiExt = require("globals/imguiext")
local search = require("globals/search")
local style = require("globals/style")
local tables = require("globals/tables")
local utils = require("globals/utils")

------------------
-- API
------------------

local publicApi = require("api/publicApi")

------------------
-- Registers
------------------

registerForEvent("onInit", function()
  Cyberlibs = tables.add(Cyberlibs, publicApi)

  publicApi.OnInit()
end)

registerForEvent("onOverlayOpen", function()

end)

registerForEvent("onOverlayClose", function()
  search.flush()
end)

registerForEvent("onUpdate", function()

end)

------------------
-- Draw The Window
------------------

registerForEvent("onDraw", function()
  
end)

return Cyberlibs