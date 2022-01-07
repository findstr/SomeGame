local E = require "E"
local proto = require "proto.client" --TODO: reduce proto
local core = require "sys.core"
local gate = require "agent.gate"
local battle = require "agent.battle"
local errno = require "errno.room"

local rooms = {}
local uid_to_roomid = {}
local room_cache = setmetatable({}, {__mode = "kv"})

local ipairs = ipairs
local remove = table.remove
local log = core.log

function E.roomlist_r(req)
	return "roomlist_a", {list = rooms}
end

local function leave(id, uid)
	local erase = 0
	local r = rooms[id]
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
	remove(r, erase)
	gate.multicast(r, "roomleave_a", {uid = uid, owner = owner, id = id,})
	uid_to_roomid[uid] = nil
	if not owner then --room is empty
		rooms[id] = nil
		room_cache[#room_cache + 1] = r
	end
	log("[room] leave uid:", uid, "room", id)
end

function E.roomcreate_c(req)
	local uid = req.uid
	gate.online(uid, req.gate)
	local id = uid_to_roomid[uid]
	if id then
		leave(id, uid)
	end
	local id = #rooms + 1
	local r = remove(room_cache)
	if not r then
		r = {
			id = id,
			battle = nil,
			name = "hello",
			[1] = uid,
		}
	else
		r.id = id
		r.name = "hello"
		r.battle = nil
		for k, _ in ipairs(r) do
			r[k] = nil
		end
		r[1] = uid
	end
	rooms[id] = r
	uid_to_roomid[uid] = id
	req.id = id
	gate.send(uid, "roomcreate_a", req)
	log("[room] create uid:", uid, "room", id)
	return "roomcreate_a", req
end

function E.roomenter_c(req)
	local uid = req.uid
	local id = uid_to_roomid[uid]
	print("roomenter_c", uid, id)
	if id then
		leave(id, uid)
	end
	local id = req.id
	local r = rooms[id]
	if not r then
		log("[room] enter uid:", uid, "room", id, "no room")
		return "error", {errno = errno.NOROOM}
	else
		gate.online(uid, req.gate)
		req.name = r.name
		req.list = r
		r[#r + 1] = uid
		uid_to_roomid[uid] = id
		gate.multicast(r, "roomenter_a", req)
	end
	log("[room] enter uid:", uid, "room", id, "count", #r)
	return "roomenter_a", req
end

function E.roomleave_r(req)
	local uid = req.uid_
	local id = uid_to_roomid[uid]
	log("[room] leave uid:", uid, "room", id)
	if id then
		leave(id, uid)
	end
	gate.offline(uid, nil)
	return "roomleave_a", req
end

function E.roomplay_r(req)
	local uid = req.uid_
	local id = uid_to_roomid[uid]
	if not id then
		log("[room] play uid:", uid, "room", id, "no room")
		return "error", {errno = errno.NOROOM}
	end
	local r = rooms[id]
	local slot = battle.new(r)
	if not slot then
		log("[room] play uid:", uid, "room", id, " new scene fault")
		return "error", {errno = errno.SYSTEM}
	end
	if not r.battle then
		r.battle = slot
		gate.battleready(r, slot)
	end
	return "roomplay_a", nil
end

