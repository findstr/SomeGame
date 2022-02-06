local bind = require "binder.lobby".lobby
local router = require "router":new()
local server = require "server"
local ui = require "zx.ui"
local battle = require "battle"

local M = {}

local function roomlist_a(ack)
	print("roomlist")
	ui.inplace("room.list", ack.list)
end

local function battleenter_a(ack)
	print("battleenter")
	ui.inplace("room.room", ack.roomid, ack.name, ack.uidlist, ack.redcount)
end

local function battlestart_n(ack)
	print("battlestart_n")
	ui.clear()
	battle.start(ack.players)
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
	router.roomlist_a = roomlist_a
	router.battleenter_a = battleenter_a
	router.battlestart_n = battlestart_n

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

function M:stop(view)
	router:detach()
	print("[lobby] stop")
end

return M
