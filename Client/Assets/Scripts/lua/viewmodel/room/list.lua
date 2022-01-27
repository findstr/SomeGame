local bind = require "binder.room".list
local rinfo = require "binder.room".rinfo
local server = require "server"
local router = require "router"
local ui = require "zx.ui"

local M = {}
local item_ud = setmetatable({}, {__mode = "kv"})
local RED<const> = 1
local BLUE<const> = 2

local function join_left(ctx)
	print(ctx, ctx.sender)
	local r = item_ud[ctx.sender]
	local id = r.roomid
	if id then
		server.send("battleenter_r", {roomid = id, battle = r.battle, side = RED})
	end
	print("join_left", id)
end

local function join_right(ctx)
	local r = item_ud[ctx.sender]
	local id = r.roomid
	if id then
		server.send("battleenter_r", {roomid = id, battle = r.battle, side = BLUE})
	end
	print("join_right", id)
end

local function click_back()
	ui.back()
end

local function click_refresh()
	print("click_refresh")
	server.send("roomlist_r", {}) 
end

local function click_create()
	print("click_create")
	server.send("battlecreate_r", {name = "xxx"})
end

local function refresh_list(data_list)
	local list = M.room_list
	list:RemoveChildrenToPool()
	local x = {}
	for k, _ in pairs(item_ud) do
		item_ud[k] = nil
	end
	for k, v in pairs(data_list) do
		local obj = list:AddItemFromPool("ui://room/rinfo");
		rinfo(x, obj)
		x.room_name.text = v.name
		x.room_id.text = v.roomid
		local left, right = x.join_left, x.join_right
		left.onClick:Add(join_left)
		right.onClick:Add(join_right)
		item_ud[left] = v
		item_ud[right] = v
	end
end

function router.roomlist_a(ack)
	refresh_list(ack.list)
end

function router.battlecreate_a(ack)
	print("roomcreate_a")
	ui.inplace("room.room", ack.roomid, ack.name, {server.uid}, 1)
end

function router.battleenter_a(ack)
	print("battleenter_a")
	ui.inplace("room.room", ack.roomid, ack.name, ack.uidlist, ack.redcount)
end

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

function M:start(view, list)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	bind(M, view)
	M.back.onClick:Add(click_back)
	M.refresh.onClick:Add(click_refresh)
	M.create.onClick:Add(click_create)
	refresh_list(list)
	return 
end

function M:stop()
	
end

return M
