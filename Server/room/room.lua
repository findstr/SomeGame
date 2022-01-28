local E = require "E"
local const = require "const"
local router = require "router"
local json = require "sys.json"
local core = require "sys.core"
local gate = require "agent.gate"
local battle = require "agent.battle"
local errno = require "errno.room"

local rooms = {}
local uid_to_room = {}

local pairs = pairs
local ipairs = ipairs
local remove = table.remove
local log = core.log
local jencode = json.encode

local RED<const> = 1
local BLUE<const> = 2

local ROOM_PER_BATTLE = const.ROOM_PER_BATTLE

function router.roomcreate_c(req)
	local roomid = req.roomid
	req.redcount = 1
	req.bluecount = 0
	rooms[roomid] = req
	uid_to_room[req.owner] = req
	log("[room] roomcreate_c", roomid, jencode(req))
	return "roomcreate_a", req
end

function router.roomhide_c(req)
	rooms[req.roomid] = nil
	log("[room] roomhide_c", id)
	return "roomhide_a", req
end

function router.roomclear_c(req)
	rooms[req.roomid] = nil
	for _, uid in pairs(req.uidlist) do
		uid_to_room[uid] = nil
	end
	return "roomclear_a", req
end

function router.roomjoin_c(req)
	local uid = req.uid
	local id = req.roomid
	local r = rooms[id]
	uid_to_room[uid] = rooms[id]
	if req.side == RED then
		r.redcount = r.redcount + 1
	else
		r.bluecount = r.bluecount + 1
	end
	log("[room] roomjoin uid:", uid, "roomid:", id)
	return "roomjoin_a", nil
end

function router.roomleave_c(req)
	local uid = req.uid
	local r = uid_to_room[uid]
	if r then
		uid_to_room[uid] = nil
		if req.side == RED then
			r.redcount = r.redcount - 1
		else
			r.bluecount = r.bluecount + 1
		end
	end
	log("[room] roomleave uid:", uid)
	return "roomleave_a", nil
end

function router.whichroom_c(req)
	local room = uid_to_room[req.uid]
	req.roomid = room and room.roomid
	log("[room] whichroom_c uid:", req.uid, "roomid", req.roomid)
	return "whichroom_a", req
end

local function battleclear(battle)
	for k, v in pairs(uid_to_room) do
		if (v.roomid // ROOM_PER_BATTLE)  == battle then
			uid_to_room[k] = nil
		end
	end
	for k, v in pairs(rooms) do
		print("battle clear:", v.roomid, battle)
		if (v.roomid // ROOM_PER_BATTLE) == battle then
			rooms[k] = nil
		end
	end
end

function E.roomlist_r(req)
	local l = {}
	for k, v in pairs(rooms) do
		l[#l + 1] = v
	end
	return "roomlist_a", {list = l}
end

battle.restart_cb(battleclear)

local function start()
	local buf = battle.restore()
	for battle, rs in pairs(buf) do
		for _, r in pairs(rs) do
			local roomid = r.roomid
			local room = {
				roomid = roomid,
				name = r.name,
				redcount = r.redcount,
				bluecount = #r.uidlist - red
			}
			for _, uid in pairs(r.uidlist) do
				uid_to_battle[uid] = roomid
			end
			rooms[roomid] = room
		end
	end
end

return start

