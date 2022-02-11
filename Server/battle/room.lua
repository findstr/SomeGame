local core = require "sys.core"
local gate = require "agent.gate"
local room = require "agent.room"
local errno = require "errno.battle"
local property = require "property"
local const = require "const"
local entity = require "entity"
local router = require "router"
local ai = require "ai"
local E = require "E"

local M = {}
local mt = {__index = M}
local rooms = {}
local uid_to_room = {}
local room_cache = require "cache" ()

local pairs = pairs
local log = core.log
local remove = table.remove
local insert = table.insert
local online = gate.online
local offline = gate.offline
local multicast = gate.multicast
local maxinteger = math.maxinteger
local setmetatable = setmetatable

local IDLE<const> = 1
local BATTLE<const> = 2
local OVER<const> = 3

local RED<const> = 1
local BLUE<const> = 2

local NPC_BLUE<const> = 500

local HP<const> = property.HP
local MP<const> = property.MP
local HPMAX<const> = property.HPMAX
local MPMAX<const> = property.MPMAX
local SPEED<const> = property.SPEED


local roomid_start

local function enter(room, e, gateid)
	local uid, side = e.uid, e.side
	room[side][e.uid] = e
	local uidlist = room.uidlist
	if side == RED then
		local redcount = room.redcount + 1
		room.redcount = redcount
		insert(uidlist, redcount, uid)
	else
		uidlist[#uidlist + 1] = uid
	end
	room.entities[uid] = e
	online(uid, gateid)
	uid_to_room[uid] = room
end

local function clear_side(from, to, uidlist, readylist, sidelist)
	for i = from, to do
		local uid = uidlist[i]
		local e = sidelist[uid]
		uid_to_room[uid] = nil
		offline(uid, nil)
		e:del()
		readylist[uid] = nil
		sidelist[uid] = nil
		uidlist[i] = nil
	end
	--the last is npc
	for uid, e in pairs(sidelist) do
		sidelist[uid] = nil
		e:del()
	end
end

local function del(self)
	local uidlist = self.uidlist
	local readylist = self.readylist
	local redcount = self.redcount
	local uidcount = #uidlist
	local entities = self.entities
	local brains = self.brains
	self.redcount = 0
	clear_side(1, redcount, uidlist, readylist, self[RED])
	clear_side(redcount + 1, uidcount, uidlist, readylist, self[BLUE])
	for k, _ in pairs(entities) do
		entities[k] = nil
	end
	for k, _ in pairs(brains) do
		brains[k] = nil
	end
	local roomid = self.roomid
	rooms[roomid - roomid_start] = nil
	room.call("roomclear_c", self)
	room_cache[#room_cache + 1] = self
	log("[room] del room:", roomid)
end

local function leave(room, e)
	local uid, side = e.uid, e.side
	room[side][uid] = nil
	room.entities[uid] = nil
	room.brains[uid] = nil
	offline(uid, nil)
	uid_to_room[uid] = nil
	local uidlist, redcount = room.uidlist, room.redcount
	local from, to
	if side == RED then
		from = 1
		to = redcount
	else
		from = redcount + 1
		to = #uidlist
	end
	for i = from, to do
		if uidlist[i] == uid then
			if side == RED then
				room.redcount = redcount - 1
			end
			remove(uidlist, i)
			if #uidlist == 0 then
				del(room)
			else
				multicast(uidlist, "battleleave_a", {
					uid = uid, roomid = room.roomid
				})
				room.call("roomleave_c", e)
			end
			break
		end
	end
	e:del()
end

function M:broadcast(cmd, ack)
	multicast(self.uidlist, cmd, ack)
end

function M:select_nearest(x, z, side)
	local dist = maxinteger
	local target = nil
	local players = self[side]
	for _, p in pairs(players) do
		local dx = x - p.px
		local dz = z - p.pz
		local n = dx * dx + dz * dz
		if n < dist then
			dist = n
			target = p
		end
	end
	return target, dist
end

local function new(name, uid)
	local id = #rooms + 1
	local roomid = id + roomid_start
	local r = remove(room_cache)
	if not r then
		local uidlist = {}
		r = setmetatable({
			roomid = nil,
			status = IDLE,
			name = nil,
			redcount = 0,
			readylist = {},
			uidlist = uidlist,
			[RED] = {},
			[BLUE] = {},
			entities = {},
			brains = {},
		}, mt)
	end
	rooms[id] = "" --shadow
	local ack, err = room.call("roomcreate_c", {
		roomid = roomid,
		name = name,
		owner = uid,
	})
	if ack then
		r.roomid = roomid
		r.status = IDLE
		r.name = name
		r.redcount = 0
		rooms[id] = r
		log("[room] create uid:", uid, "room", roomid)
		return r
	end
	room_cache[#room_cache + 1] = r
	log("[room] create uid:", uid, "room", roomid, "error", err)
	return nil
end

local function born(room)
	local blue = room[BLUE]
	local brains = room.brains
	local entities = room.entities
	local npc = require "bt.npc"
	for i = 1, 1 do
		local id = #blue + 1
		local uid = id + NPC_BLUE
		local e = entity:new(uid, 10001, -16, -17, BLUE)
		blue[id] = e
		entities[uid] = e
		brains[uid] = ai:newctx(e, npc)
	end
end

local function exist_alive(self, side)
	local l = self[side]
	for i = 1, #l do
		if l[i].hp > 0.0001 then
			return true
		end
	end
	return false
end

local function battlestart_n(room)
	local l = {}
	local entities = room.entities
	for uid, e in pairs(entities) do
		l[#l + 1] = {
			uid = e.uid,
			heroid = e.heroid,
			px = e.px,
			pz = e.pz,
			side = e.side,
			hp = e[HP],
			mp = e[MP],
			hpmax = e[HPMAX],
			mpmax = e[MPMAX],
			speed = e[SPEED],
		}
	end
	return {entities = l}
end

local function check_ready(room, uid)
	local readylist = room.readylist
	if readylist[uid] then
		return
	end
	local n = 0
	local uidlist = room.uidlist
	local total = #uidlist
	readylist[uid] = true
	for _, v in pairs(readylist) do
		if v then
			n = n + 1
		end
	end
	log("[room] battleready uid:", uid, n, "/", total)
	if n == total then
		room.status = BATTLE
		born(room)
		multicast(uidlist, "battlestart_n", battlestart_n(room))
	end
	local ack = {
		current = n,
		total = total,
	}
	return "battleready_a", ack
end


function M:checkover()
	if not exist_alive(self, RED) then
		self.status = OVER
		gate.multicast(self.uidlist, "battleover_n", {winner = BLUE})
	elseif not exist_alive(self, BLUE) then
		self.status = OVER
		gate.multicast(self.uidlist, "battleover_n", {winner = RED})
	end
end

function M:tick(delta)
	local status = self.status
	if status == IDLE then
		return
	end
	if status == OVER then
		del(self)
		return
	end
	for i = 1, #self do
		local players = self[i]
		for j = 1, #players do
			players[j]:tick(self, delta)
		end
	end
	local brains = self.brains
	for _, b in pairs(brains) do
		b:tick(self, delta)
	end
end

---------------------tick

local ms = core.monotonic
local last_time = ms() / 1000
local pcall = core.pcall
local function timer_tick()
	local t = ms() / 1000
	local delta = t - last_time
	last_time = t
	for _, r in pairs(rooms) do
		local ok, err = pcall(r.tick, r, delta)
		if not ok then
			log("[room] tick roomid:", r.roomid, "err:", err)
		end
	end
	core.timeout(100, timer_tick)
end

----------------------handler

function router.battleplayers_c(req)
	local list = {}
	local ack = {
		rooms = list
	}
	for _, r in pairs(rooms) do
		list[#list + 1] = r
	end
	return "battleplayers_a", ack
end

function router.battlerestore_c(req)
	local room =  uid_to_room[req.uid]
	print("battlerestore_c", room)
	if not room then
		req.list = req
		return "error", {errno = errno.NOROOM}
	end
	if room.status == IDLE then
		return "battleenter_a", room
	else
		return "battlestart_n", battlestart_n(room)
	end
end

function router.battlecreate_c(req)
	local uid = req.uid
	local r = new(req.name, uid)
	if r then
		local e = entity:new(uid, 10000, -6, -6, RED, r.broadcast)
		enter(r, e, req.gate)
		log("[player] battlecreate uid:", uid, "room", r.roomid)
		return "battlecreate_a", r
	end
	log("[player] battlecreate uid:", uid, "error")
	return "error", {errno = errno.SYSTEM}
end

function E.battleenter_c(req)
	local roomid = req.roomid
	local uid, side = req.uid, req.side
	local r = rooms[roomid - roomid_start]
	if not r then
		log("[room] enter uid:", uid, "room", roomid, "not exist")
		return "error", {errno = errno.NOROOM}
	end
	local ack, err = room.call("roomjoin_c", {
		roomid = roomid, uid = uid, side = side
	})
	if not ack then
		log("[room] enter uid:", uid, "room", roomid, "error:", err)
		return "error", {errno = errno.SYSTEM}
	end
	local gateid = req.gate
	local req = {
		roomid = roomid,
		uid = uid,
		side = side,
	}
	local uidlist = r.uidlist
	multicast(uidlist, "battleenter_n", req)
	local e = entity:new(uid, 1000, -6, -6, side)
	enter(r, e, gateid)
	log("[room] enter uid:", uid, "room", roomid, "count", #uidlist)
	return "battleenter_a" ,r
end

function E.battleleave_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if r then
		local e = r[RED][uid] or r[BLUE][uid]
		if e then
			leave(r, e)
		end
	end
	log("[player] battleleave uid:", uid)
	return "battleleave_a", req
end

function E.battleready_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if not r then
		log("[player] play uid:", uid, "out of room")
		return "error", {errno = errno.NOROOM}
	end
	check_ready(r, uid)
	log("[player] battleready_r", uid, "room", r.roomid)
	return "battleready_a", req
end

function E.battlemove_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if r then
		local e = r.entities[uid]
		if e then
			e.px = req.px
			e.pz = req.pz
			e.vx = req.vx
			e.vz = req.vz
			multicast(r.uidlist, "battlemove_a", e)
		end
	end
end

function E.battleskill_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if r then
		local entities = r.entities
		local atk = entities[uid]
		local target = entities[req.target]
		local s = atk.skills[req.skill]
		s:fire(r, atk, target)
	end
end

---------------------------------
function M.start(slot)
	roomid_start = slot * const.ROOM_PER_BATTLE
	timer_tick()
end


return M

