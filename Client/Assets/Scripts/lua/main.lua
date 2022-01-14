local socket = require "zx.socket"
local json = require "zx.json"
local router = require "router"
local core = require "zx.core"
local proto = require "proto"
local ui = require "zx.ui"

--[[
ui.lan("conf.CN")

local gprint = print
xprint = function(...)
	gprint(..., "\n", debug.traceback())
end

ui.assetdir("FGUI")
ui.open "login.login"


]]

local LoadAsset = CS.ZX.Core.LoadAsset
local strings = require "zx.strings"
local foo = "hellohellohellohellohellohellohellohellohellohello"
for i = 1, 64 * 1024 * 1024 do
	LoadAsset(strings[foo])
end
