local bind = require "binder.lobby".lobby
local router = require "router":new()
local server = require "server"
local ui = require "zx.ui"
local battle = require "battle"

local M = {}

function router.roomlist_a(ack)
	print("roomlist")
	ui.inplace("room.list", ack.list)
end

function router.battleenter_a(ack)
	print("battleenter")
	ui.inplace("room.room", ack.roomid, ack.name, ack.uidlist, ack.redcount)
end

function router.battlestart_n(ack)
	print("battlestart_n")
	ui.clear()
	battle.start(ack)
end

local function normal_mode()
	print("match_mode")
end

local function room_mode()
	print("room_mode")
	server.send("roomlist_r")
end

local function hell_mode()
	print("hell_mode")
end

function M:start(view)
	print("lobby start")
	router:attach()
	view:MakeFullScreen()
	bind(M, view)
	GRoot.inst:AddChild(view)
	M.normalpvp.onClick:Add(normal_mode)
	M.roompvp.onClick:Add(room_mode)
	M.hellpvp.onClick:Add(hell_mode)
	print("[lobby] start")
	return
end

function M:stop()
	router:detach()
	print("[lobby] stop")
end

return M
