local E = require "E"
local router = require "router"
local core = require "sys.core"
local gate = require "agent.gate"
local room = require "agent.room"
local errno = require "errno.battle"

local log = core.log
local pairs = pairs
local ipairs = ipairs
local concat = table.concat
local remove = table.remove
local battle_slot

local rooms = {}
local uid_to_room = {}
local room_cache = setmetatable({}, {__mode = "kv"})

local ROOM_IDLE<const> = 1
local ROOM_BATTLE<const> = 2

function router.battleplayers_c(req)
	local l = {}
	local ack = {uids = l}
	for uid, _ in pairs(uid_to_room) do
		l[#l + 1] = uid
	end
	return "battleplayers_a", ack
end

local function leave(r, uid)
	local erase = 0
	for i = 1, #r do
		if r[i] == uid then
			erase = i
			break
		end
	end
	local first = r[1]
	local owner
	if first == uid then
		owner = r[2]
	else
		owner = first
	end
	local roomid = r.roomid
	remove(r, erase)
	gate.multicast(r, "roomleave_a", {uid = uid, owner = owner, roomid = roomid,})
	uid_to_room[uid] = nil
	if not owner then --room is empty
		rooms[roomid] = nil
		room_cache[#room_cache + 1] = r
	end
	log("[room] leave uid:", uid, "room", roomid)
end

function E.roomrestore_c(req)
	local r = uid_to_room[req.uid]
	if not r then
		return "roomrestore_a", r
	end
	req.roomstate = r.state
	req.members = r
	return "roomrestore_a", req
end

function E.roomcreate_c(req)
	local uid = req.uid
	gate.online(uid, req.gate)
	local r = uid_to_room[uid]
	if r then
		leave(r, uid)
	end
	local name = "hello"
	local roomid = #rooms + 1
	local r = remove(room_cache)
	if not r then
		r = {
			state = ROOM_IDLE,
			roomid = roomid,
			name = name,
			[1] = uid,
		}
	else
		r.state = ROOM_IDLE
		r.roomid = roomid
		r.name = name
		for k, _ in ipairs(r) do
			r[k] = nil
		end
		r[1] = uid
	end
	rooms[roomid] = "" --shadow
	local ack, err = room.call("roomshow_c", {
		battle = battle_slot,
		roomid = roomid,
		name = name,
		owner = uid,
	})
	if ack then
		rooms[roomid] = r
		uid_to_room[uid] = r
		req.roomid = roomid
		gate.send(uid, "roomcreate_a", req)
		log("[room] create uid:", uid, "room", roomid)
		return "roomcreate_a", req
	end
	rooms[roomid] = nil
	log("[room] create uid:", uid, "room", roomid, "err", err)
	return "error", {errno = errno.SYSTEM}
end

function E.roomenter_c(req)
	local uid = req.uid
	local r = uid_to_room[uid]
	if r then
		print("roomenter_c", uid, r.roomid)
		leave(r, uid)
	end
	local roomid = req.roomid
	r = rooms[roomid]
	if not r then
		log("[room] enter uid:", uid, "room", roomid, "no room")
		return "error", {errno = errno.NOROOM}
	end
	local ack, err = room.call("battlejoin_c", {
		battle = battle_slot, uid = uid
	})
	if ack then
		gate.online(uid, req.gate)
		gate.multicast(r, "roomenter_n", req)
		req.name = r.name
		req.list = r
		r[#r + 1] = uid
		uid_to_room[uid] = r
		log("[room] enter uid:", uid, "room", roomid, "count", #r)
		return "roomenter_a", req
	end
	log("[room] enter uid:", uid, "room", roomid, "rpc error:", err)
	return "error", {errno = errno.SYSTEM}
end

function E.roomleave_r(req)
	local uid = req.uid_
	local roomid = uid_to_room[uid]
	log("[room] leave uid:", uid, "room", roomid)
	if roomid then
		leave(roomid, uid)
	end
	gate.offline(uid, nil)
	room.call("battleleave_c", req)
	return "roomleave_a", req
end

function E.roomplay_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if not r then
		log("[room] play uid:", uid, "no room")
		return "error", {errno = errno.NOROOM}
	end
	r.state = ROOM_BATTLE
	req.uids = r
	gate.multicast(r, "roombattle_n", req)
	log("[room] play uid:", uid, "room", r.roomid, "ok")
	return "roomplay_a", nil
end

function E.battlemove_r(req)
	local uid = req.uid_
	req.uid = uid
	local r = uid_to_room[uid]
	gate.multicast(r, "battlemove_a", req)
end

function E.battleskill_r(req)
	local uid = req.uid_
	req.uid = uid
	local r = uid_to_room[uid]
	gate.multicast(r, "battleskill_a", req)
end


local function start(slot)
	battle_slot = slot
end

return start
