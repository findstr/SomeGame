local bind = require "binder.room".room
local pinfo = require "binder.room".pinfo
local server = require "server"
local router = require "router":new()
local ui = require "zx.ui"
local battle = require "battle"

local M = {}
local members = {}
local RED<const> = 1
local BLUE<const> = 2
local remove = table.remove

local function click_back()
	server.send("battleleave_r")
	ui.single("lobby.lobby")
end

local function click_begin()
	server.send("battleready_r")
end

local function sync_data(list, redcount)
	for i = 1, #list do
		members[list[i]] = i <= redcount and RED or BLUE
	end
	for i = #list + 1, #members do
		members[i] = nil
	end
end

local function refresh_list()
	local left, right = M.left_list, M.right_list
	local list = {
		[RED] = left,
		[BLUE] = right,
	}
	left:RemoveChildrenToPool()
	right:RemoveChildrenToPool()
	local x = {}
	for uid, side in pairs(members) do
		local obj = list[side]:AddItemFromPool("ui://room/pinfo");
		pinfo(x, obj)
		x.name.text = uid
		x.level.text = "30"
	end
end

function router.battleleave_a(ack)
	print("battleleave_a", ack.roomid, roomid)
	local uid = ack.uid
	members[uid] = nil
	refresh_list()
end

function router.battleenter_n(ack)
	print("battleenter_n", ack.roomid, ack.side)
	local has = false
	local uid = ack.uid
	members[uid] = ack.side
	refresh_list()
end

function router.battlestart_n(ack)
	print("roombattle_n")
	ui.clear()
	battle.start(ack.entities)
end

function M:start(view, roomid, name, uidlist, redcount)
	router:attach()
	print("room.room", roomid, name, uidlist, redcount)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)
	bind(M, view)
	M.back.onClick:Add(click_back)
	M.begin.onClick:Add(click_begin)
	M.room_name.text = name
	sync_data(uidlist, redcount)
	refresh_list()
	return
end

function M:stop()
	router:detach()
end

return M
