local E = require "E"
local router = require "router"
local json = require "sys.json"
local core = require "sys.core"
local gate = require "agent.gate"
local room = require "agent.room"
local errno = require "errno.battle"
local const = require "const"

local log = core.log
local next = next
local pairs = pairs
local ipairs = ipairs
local insert = table.insert
local concat = table.concat
local remove = table.remove
local monotonic = core.monotonic
local battle_slot
local roomid_start

local rooms = {}
local uid_to_room = {}
local weak_mt = {__mode = "kv"}
local room_cache = setmetatable({}, weak_mt)
local player_cache = setmetatable({}, weak_mt)

local IDLE<const> = 1
local BATTLE<const> = 2

local RED<const> = 1
local BLUE<const> = 2

local PLAYER_IDLE<const> = 0 * 2
local PLAYER_READY<const> = 1 * 2
local PLAYER_BATTLE<const> = 2 * 2

function router.battlerestore_c(req)
	local r = uid_to_room[req.uid]
	if not r then
		req.list = req
		return "battlelist_a", req
	end
	if r.state == IDLE then
		return "battleenter_a", r
	else
		return "battlestart_n", r
	end
end

function router.battleplayers_c(req)
	return "battleplayers_a", ack
end

local function clearplayer(players, uid)
	local p = players[uid]
	player_cache[#player_cache + 1] = p
	players[uid] = nil
	uid_to_room[uid] = nil
end

local function clearroom(r)
	local players = r.players
	local uidlist = r.uidlist
	room.call("roomclear_c", r)
	for i = 1, #uidlist do
		local uid = uidlist[i]
		uidlist[i] = nil
		clearplayer(players, uid);
	end
	rooms[r.roomid - roomid_start] = nil
	room_cache[#room_cache + 1] = r
end


local function leave(r, uid)
	local redcount = r.redcount
	local uidlist = r.uidlist
	for i = 1, #uidlist do
		if uidlist[i] == uid then
			if i <= redcount then
				r.redcount = redcount - 1
			end
			remove(uidlist, i)
			break
		end
	end
	local roomid = r.roomid
	clearplayer(r.players, uid)
	gate.multicast(uidlist, "battleleave_a", {uid = uid, roomid = roomid,})
	if #uidlist == 0 then
		clearroom(r)
	end
	log("[room] leave uid:", uid, "room", roomid)
end

local function new_player(uid, side)
	local p = remove(player_cache)
	if not p then
		p = {
			uid = uid,
			hero = 1000,
			hp = 100,
			mp = 100,
			px = -4.6,
			pz = -5.8,
			vx = 0,
			vz = 0,
			mt = 0,
			side = side,
			state = IDLE,
		}
	else
		p.uid = uid
		p.hero = 1000
		p.hp = 100
		p.mp = 100
		p.px = -4.6
		p.pz = -5.8
		p.vx = 0
		p.vz = 0
		p.mt = 0
		p.side = side
		p.state = IDLE
	end
	return p
end

local function new_room(id, name, uid, p)
	local r = remove(room_cache)
	if not r then
		r = {
			roomid = id + roomid_start,
			frame = 0,
			redcount = 0,
			state = IDLE,
			name = name,
			players = {[uid] = p},
			uidlist = {uid},
		}
	else
		local players = r.players
		r.roomid = id + roomid_start
		r.state = IDLE
		r.roomid = roomid
		r.name = name
		r.frame = 0
		r.redcount = 0
		r.uidlist[1] = uid
		r.players[uid] = p
	end
	return r
end

function router.battlecreate_c(req)
	local uid = req.uid
	gate.online(uid, req.gate)
	local r = uid_to_room[uid]
	if r then
		leave(r, uid)
	end
	local name = req.name
	local id = #rooms + 1
	local p = new_player(uid, RED)
	local r = new_room(id, name, uid, p)
	local roomid = r.roomid
	r.redcount = 1
	rooms[id] = "" --shadow
	local ack, err = room.call("roomcreate_c", {
		roomid = roomid,
		name = name,
		owner = uid,
	})
	if ack then
		rooms[id] = r
		uid_to_room[uid] = r
		req.roomid = roomid
		log("[room] create uid:", uid, "room", roomid)
		return "battlecreate_a", req
	end
	rooms[id] = nil
	log("[room] create uid:", uid, "room", roomid, "err", err)
	return "error", {errno = errno.SYSTEM}
end

function E.battleenter_c(req)
	local uid, side = req.uid, req.side
	local r = uid_to_room[uid]
	if r then
		print("battleenter_c", uid, r.roomid)
		leave(r, uid)
	end
	local roomid = req.roomid
	local id = roomid - roomid_start
	r = rooms[id]
	if not r then
		log("[room] enter uid:", uid, "room", roomid, "no room")
		return "error", {errno = errno.NOROOM}
	end
	local ack, err = room.call("roomjoin_c", {
		roomid = roomid, uid = uid, side = side
	})
	if not ack then
		log("[room] enter uid:", uid, "room", roomid, "rpc error:", err)
		return "error", {errno = errno.SYSTEM}
	end
	local uidlist = r.uidlist
	gate.online(uid, req.gate)
	gate.multicast(r.uidlist, "battleenter_n", req)
	if side == RED then
		local n = r.redcount + 1
		r.redcount = n
		insert(uidlist, n, uid)
	else
		uidlist[#uidlist + 1] = uid
	end
	r.players[uid] = new_player(uid, side)
	uid_to_room[uid] = r
	log("[room] enter uid:", uid, "room", roomid, "count", #uidlist)
	return "battleenter_a", r
end

function E.battleleave_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	log("[room] leave uid:", uid, "room", roomid)
	if r then
		p = r.players[uid]
		req.uid = uid
		req.side = p.side
		room.call("roomleave_c", req)
		leave(r, uid)
	end
	gate.offline(uid, nil)
	return "battleleave_a", req
end

function E.battleready_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if not r then
		log("[room] play uid:", uid, "no room")
		return "error", {errno = errno.NOROOM}
	end
	local uidlist = r.uidlist
	local total = #r.uidlist
	local current = 0
	print("battleready_r", uid, r.players[uid])
	r.players[uid].state = BATTLE
	for k, p in pairs(r.players) do
		if p.state == BATTLE then
			current = current + 1
		end
	end
	log("[room] battleready uid:", uid, current, "/", total)
	if current == total then
		r.state = BATTLE
		gate.multicast(uidlist, "battlestart_n", r)
		return "battleready_a", req
	else
		req.current = current
		req.total = total
		return "battleready_a", req
	end
end

function E.battlemove_r(req)
	local uid = req.uid_
	req.uid = uid
	local r = uid_to_room[uid]
	if not r then
		return
	end
	local p = r.players[uid]
	p.px = req.px
	p.pz = req.pz
	p.vx = req.vx
	p.vz = req.vz
	p.mt = monotonic()
	gate.multicast(r.uidlist, "battlemove_a", req)
end

function E.battleskill_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if not r then
		return
	end
	local skill = req.skill
	local target = req.target
	local players = r.players
	local a = players[uid]
	local t = players[target]
	local hp = t.hp
	hp = hp - 10
	if hp < 0 then
		hp = 0
	end
	t.hp = hp
	a.mp = a.mp - 1
	print("battleskill_a", json.encode(req))
	req.uid = uid
	req.mp = a.mp
	req.targethp = t.hp
	gate.multicast(r.uidlist, "battleskill_a", req)
	if hp == 0 then
		req.winner = a.side
		gate.multicast(r.uidlist, "battleover_n", req)
		clearroom(r)
	end

end

local function start(slot)
	battle_slot = slot
	roomid_start = slot * const.ROOM_PER_BATTLE
end

return start
