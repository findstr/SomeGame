local E = require "E"
local router = require "router"
local json = require "sys.json"
local proto = require "proto.client" --TODO: reduce proto
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

local function makeid(battle, room)
	return room * 2000 + battle
end

function router.roomcreate_c(req)
	local battle = req.battle
	local id = makeid(req.battle, req.roomid)
	req.red = 1
	req.blue = 0
	rooms[id] = req
	uid_to_room[req.owner] = req
	log("[room] roomcreate_c", id, jencode(req))
	return "roomcreate_a", req
end

function router.roomhide_c(req)
	rooms[makeid(req.battle, req.roomid)] = nil
	log("[room] roomhide_c", id)
	return "roomhide_a", req
end

function router.roomclear_c(req)
	rooms[makeid(req.battle, req.roomid)] = nil
	for _, uid in pairs(req.uidlist) do
		uid_to_room[uid] = nil
	end
	return "roomclear_a", req
end

function router.roomjoin_c(req)
	local uid = req.uid
	local id = makeid(req.battle, req.roomid)
	uid_to_room[uid] = rooms[id]
	log("[room] roomjoin uid:", uid, "battle:", id)
	return "roomjoin_a", nil
end

function router.battleleave_c(req)
	local uid = req.uid
	local battle = uid_to_room[uid]
	uid_to_room[uid] = nil
	log("[room] battleleave uid:", uid, "battle:", battle)
	return "battleleave_a", nil
end

function router.whichbattle_c(req)
	local room = uid_to_room[req.uid]
	req.battle = room and room.battle
	log("[room] whichbattle_c uid:", req.uid, "battle", req.battle)
	return "whichbattle_a", req
end

local function battleclear(battle)
	for k, v in pairs(uid_to_room) do
		if v.battle == battle then
			uid_to_room[k] = nil
		end
	end
	for k, v in pairs(rooms) do
		print("battle clear:", v.battle, battle)
		if v.battle == battle then
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
				battle = battle,
				roomid = roomid,
				name = r.name,
				red = r.redcount,
				blue = #r.uidlist - red
			}
			for _, uid in pairs(r.uidlist) do
				uid_to_battle[uid] = roomid
			end
			rooms[makeid(battle, roomid)] = room
		end
	end
end

return start
