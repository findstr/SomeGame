local socket = require "zx.socket"
local json = require "zx.json"
local router = require "router"
local core = require "zx.core"
local proto = require "proto"
local ui = require "zx.ui"

local gprint = print
xprint = function(...)
	gprint(..., "\n", debug.traceback())
end

ui.open "login.login"

