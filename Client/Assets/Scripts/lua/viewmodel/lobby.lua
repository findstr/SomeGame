local bind = require "binder.lobby".lobby
local ui = require "zx.ui"

local M = {}

local function normal_mode()
	print("match_mode")
end

local function room_mode()
	print("room_mode")
	ui.inplace("room.room")
end

local function hell_mode()
	print("hell_mode")
end

function M:start(view)
	view:MakeFullScreen()
	bind(M, view)
	GRoot.inst:AddChild(view)
	M.normalpvp.onClick:Add(normal_mode)
	M.roompvp.onClick:Add(room_mode)
	M.hellpvp.onClick:Add(hell_mode)
	print("[lobby] start")
	return 
end

function M:stop(view)
	print("[lobby] stop")
end

return M
