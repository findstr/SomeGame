local socket = require "zx.socket"
local json = require "zx.json"
local router = require "router"
local core = require "zx.core"
local proto = require "proto"
local ui = require "zx.ui"
local resources = require "zx.resources"

ui.lan("conf.CN")
local gprint = print
xprint = function(...)
	gprint(..., "\n", debug.traceback())
end

ui.assetdir("FGUI")
ui.open "login.login"

resources.load_async({"Character/125001.prefab"}, function(ud) print("hello", ud) end, 100)

