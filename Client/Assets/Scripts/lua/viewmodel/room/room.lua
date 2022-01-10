local bind = require "binder.room".room
local pinfo = require "binder.room".pinfo
local server = require "server"
local router = require "router"
local ui = require "zx.ui"
local battle = require "model.battle"

local M = {}
local roomid = nil
local room_list = {}
local remove = table.remove
local function click_back()
	server.send("roomleave_r")
	ui.back()
end

local function click_begin()
	server.send("roomplay_r")
end

local function sync_data(members)
	for i = 1, #members do
		room_list[i] = members[i]
	end
	for i = #members + 1, #room_list do
		room_list[i] = nil
	end
end

local function refresh_list()
	local list = M.atk_list
	list:RemoveChildrenToPool()
	local x = {}
	for k, uid in pairs(room_list) do
		local obj = list:AddItemFromPool("ui://room/pinfo");
		pinfo(x, obj)
		x.name.text = uid
		x.level.text = "30"
	end
end

function router.roomleave_a(ack)
	print("roomleave_a", ack.roomid, roomid)
	if roomid == ack.roomid then
		local uid = ack.uid
		for i = 1, #room_list do
			if room_list[i] == uid then
				remove(room_list, i)
				break
			end
		end
		refresh_list()
	end
end

function router.roomenter_n(ack)
	print("roomenter_n", ack.roomid, roomid)
	if roomid == ack.roomid then
		local has = false
		local uid = ack.uid
		for i = 1, #room_list do
			if room_list[i] == uid then
				has = true
				break
			end
		end
		room_list[#room_list + 1] = uid
		refresh_list()
	end
end

function router.roombattle_n(ack)
	print("roombattle_n")
	ui.clear()
	battle.start(ack.uids)
end

function M:start(view, rid, name, list)
	print("room.room", rid, name, list)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	bind(M, view)
	M.back.onClick:Add(click_back)
	M.begin.onClick:Add(click_begin)
	M.room_name.text = name
	roomid = rid
	sync_data(list)
	refresh_list()
	return 
end

function M:stop()
	
end

return M
