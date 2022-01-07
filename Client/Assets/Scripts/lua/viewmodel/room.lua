local bind = require "binder.room".room
local ui = require "zx.ui"

local M = {}

local function normal_mode()
	print("match_mode")
end

local function room_mode()
	print("room_mode")
	ui.inplace("room.list")
end

local function hell_mode()
	print("hell_mode")
end

function M:start(view)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	bind(M, view)
	return 
end

function M:stop()
	
end

return M
