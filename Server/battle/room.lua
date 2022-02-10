local core = require "sys.core"
local gate = require "agent.gate"
local room = require "agent.room"
local errno = require "errno.battle"
local const = require "const"
local router = require "router"
local npc = require "npc"

local M = {}
local mt = {__index = M}
local rooms = {}
local room_cache = require "cache" ()

local pairs = pairs
local log = core.log
local remove = table.remove
local insert = table.insert
local multicast = gate.multicast
local maxinteger = math.maxinteger
local setmetatable = setmetatable

local IDLE<const> = 1
local BATTLE<const> = 2
local OVER<const> = 3
local RED<const> = 1
local BLUE<const> = 2
local roomid_start

function M:new(name, p)
	local uid = p.uid
	local id = #rooms + 1
	local roomid = id + roomid_start
	local r = remove(room_cache)
	if not r then
		r = setmetatable({
			roomid = roomid,
			frame = 0,
			redcount = 0,
			status = IDLE,
			name = name,
			npcidx = 0,
			uidlist = {uid},
			readylist = {},
			[RED] = {},
			[BLUE] = {},
		}, mt)
	else
		r.roomid = roomid
		r.status = IDLE
		r.name = name
		r.frame = 0
		r.npcidx = 0
		r.redcount = 0
		r.uidlist[1] = uid
	end
	local side = p.side
	r[side][1] = p
	if side == RED then
		r.redcount = 1
	end
	rooms[id] = "" --shadow
	local ack, err = room.call("roomcreate_c", {
		roomid = roomid,
		name = name,
		owner = uid,
	})
	if ack then
		rooms[id] = r
		log("[room] create uid:", uid, "room", roomid)
		return r
	end
	log("[room] create uid:", uid, "room", roomid, "error", err)
	return nil
end

local function del(self)
	local roomid = self.roomid
	local uidlist = self.uidlist
	local readylist = self.readylist
	for i = 1, #self do
		local players = self[i]
		for j = 1, #players do
			local p = players[j]
			p:del()
			players[j] = nil
		end
	end
	for i = 1, #uidlist do
		readylist[uidlist[i]] = nil
		uidlist[i] = nil
	end
	local l = self[RED]
	for i = 1, #l do
		l[i] = nil
	end
	l = self[BLUE]
	for i = 1, #l do
		l[i] = nil
	end
	rooms[roomid - roomid_start] = nil
	room.call("roomclear_c", self)
	room_cache[#room_cache + 1] = self
	log("[room] del room:", roomid)
end

local function join(r, p)
	local side = p.side

end

function M:enter(roomid, p)
	local r = rooms[roomid]
	if not r then
		log("[room] enter uid:", p.uid, "room", roomid, "not exist")
		return nil, errno.NOROOM
	end
	local roomid = r.roomid
	local uid, side = p.uid, p.side
	local ack, err = room.call("roomjoin_c", {
		roomid = roomid, uid = uid, side = side
	})
	if not ack then
		log("[room] enter uid:", uid, "room", roomid, "error:", err)
		return nil, errno.SYSTEM
	end
	local req = {
		roomid = roomid,
		uid = uid,
		side = side,
	}

	multicast(r.uidlist, "battleenter_n", req)
	local uidlist = r.uidlist
	local players = r[side]
	if side == RED then
		local n = r.redcount + 1
		r.redcount = n
		insert(uidlist, n, uid)
	else
		uidlist[#uidlist + 1] = uid
	end
	players[#players + 1] = p
	log("[room] enter uid:", uid, "room", roomid, "count", #uidlist)
	return r, nil
end

function M:leave(p)
	if self.status == OVER then
		return
	end
	local s, e
	local uid = p.uid
	local side = p.side
	local uidlist = self.uidlist
	if side == RED then
		local n = self.redcount
		self.redcount = n - 1
		s = 1
		e = n
	else
		s = self.redcount + 1
		e = #uidlist
	end
	for i = s, e do
		if uid == uidlist[i] then
			remove(uidlist, i)
			remove(self[side], i - s + 1)
			self.readylist[uid] = nil
			break
		end
	end
	if #uidlist == 0 then
		self.status = OVER
		del(self)
	else
		multicast(uidlist, "battleleave_a", {
			uid = uid, roomid = self.roomid
		})
		room.call("roomleave_c", p)
	end
end

local function born(room)
	local n = room.npcidx
	local red = room[RED]
	local blue = room[BLUE]
	for i = 1, 1 do
		n = n + 1
		local b = npc:new(room, n, 1, BLUE)
		blue[#blue + 1] = b
	end
	room.npcidx = n
end

local function build_battlestart_n(self)
	local l = {}
	for i = 1, #self do
		local players = self[i]
		for j = 1, #players do
			l[#l + 1] = players[j]
		end
	end
	return {players = l}
end

function M:ready(p)
	local uid = p.uid
	local readylist = self.readylist
	if readylist[uid] then
		return
	end
	local n = 0
	local uidlist = self.uidlist
	local total = #uidlist
	readylist[uid] = true
	for _, v in pairs(readylist) do
		if v then
			n = n + 1
		end
	end
	log("[room] battleready uid:", uid, n, "/", total)
	if n == total then
		self.status = BATTLE
		born(self)
		multicast(uidlist, "battlestart_n", build_battlestart_n(self))
	end
	local ack = {
		current = n,
		total = total,
	}
	return "battleready_a", ack
end

function M:broadcast(cmd, ack)
	multicast(self.uidlist, cmd, ack)
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

function M:checkover()
	if not exist_alive(self, RED) then
		self.status = OVER
		gate.multicast(self.uidlist, "battleover_n", {winner = BLUE})
	elseif not exist_alive(self, BLUE) then
		self.status = OVER
		gate.multicast(self.uidlist, "battleover_n", {winner = RED})
	end
end

function M:restore()
	if self.status == IDLE then
		return "battleenter_a", self
	else
		return "battlestart_n", build_battlestart_n(self)
	end
end

function M:select_nearest(x, z, side)
	local dist = math.maxinteger
	local target = nil
	local players = self[side]
	print("**select side:", side)
	for i = 1, #players do
		local p = players[i]
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

local battleskill_a = {
	uid = nil,
	skill = nil,
	mp = nil,
	target = nil,
	targethp = nil
}


function M:fire_skill(atk, target, skill)
	local room = self
	local t
	for i = 1, #self do
		local players = self[i]
		for j = 1, #players do
			local p = players[j]
			if p.uid == target then
				t = p
				break
			end
		end
	end

	local hp = t.hp
	hp = hp - 10
	if hp < 0 then
		hp = 0
	end
	t.hp = hp
	atk.mp = atk.mp - 1
	battleskill_a.uid = atk.uid
	battleskill_a.skill = skill
	battleskill_a.mp = atk.mp
	battleskill_a.target = t.uid
	battleskill_a.targethp = t.hp
	print("fire_skill", skill)
	multicast(self.uidlist, "battleskill_a", battleskill_a)
	if hp == 0 then
		room:checkover()
	end

end

function M:tick(delta)
	local status = self.status
	if status == IDLE then
		return
	end
	if status == OVER then
		return
	end
	for i = 1, #self do
		local players = self[i]
		for j = 1, #players do
			print("tick:", j)
			players[j]:tick(delta)
		end
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
	core.timeout(1000, timer_tick)
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

---------------------------------
function M.start(slot)
	roomid_start = slot * const.ROOM_PER_BATTLE
	timer_tick()
end


return M

