local bind = require "binder.room".list
local rinfo = require "binder.room".rinfo
local server = require "server"
local router = require "router"
local ui = require "zx.ui"

local M = {}
local item_ud = setmetatable({}, {__mode = "kv"})

function router.roomlist_a(ack)
	print("roomlist_a", ack)
	local list = M.room_list
	list:RemoveChildrenToPool()
	local x = {}
	for k, _ in pairs(item_ud) do
		item_ud[k] = nil
	end
	for k, v in pairs(ack.list) do
		local obj = list:AddItemFromPool("ui://room/rinfo");
		rinfo(x, obj)
		x.room_name.text = v.name
		x.room_id.text = v.id
		item_ud[obj] = v.id
	end
end

function router.roomcreate_a(ack)
	print("roomcreate_a")
	ui.inplace("room.room", ack.id, ack.name, {ack.uid})
end

function router.roomenter_a(ack)
	print("roomenter_a")
	ui.inplace("room.room", ack.id, ack.name, ack.list)
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

local function click_item(ctx)
	local id = item_ud[ctx.data]
	if id then
		server.send("roomenter_r", {id = id})
	end
	print("click_item", item_ud[ctx.data])
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
	server.send("roomcreate_r", {name = "房间号"})
end

function M:start(view)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	bind(M, view)
	M.back.onClick:Add(click_back)
	M.refresh.onClick:Add(click_refresh)
	M.create.onClick:Add(click_create)
	local list = M.room_list
	list.onClickItem:Add(click_item)
	server.send("roomlist_r", {}) 
	return 
end

function M:stop()
	
end

return M
