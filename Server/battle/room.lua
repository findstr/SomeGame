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
local ms = core.monotonic
local tostring = tostring
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

local ROAD_UP<const> = 1
local ROAD_MID<const> = 2
local ROAD_DOWN<const> = 3

local CHARACTER<const> = 1
local TOWER<const> = 2
local CRYSTAL<const> = 3

local NPC_BLUE<const> = 500

local HP<const> = property.HP
local MP<const> = property.MP
local HPMAX<const> = property.HPMAX
local MPMAX<const> = property.MPMAX
local SPEED<const> = property.SPEED


local roomid_start

local function new(name, uid)
	local id = #rooms + 1
	local roomid = id + roomid_start
	local r = nil --TODO: remove(room_cache)
	if not r then
		r = setmetatable({
			roomid = nil,
			status = IDLE,
			name = nil,
			npcidx = 0,
			redcount = 0,
			uidlist = {},
			readylist = {},
			brains = {},
			depend = {},
			redcrystal = nil,
			bluecrystal = nil,
			redup = {},
			redmiddle = {},
			reddown = {},
			blueup = {},
			bluemiddle = {},
			bluedown = {},
			reborn = {},
			entities = {},
			[RED] = {},
			[BLUE] = {},
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
		rooms[id] = r
		log("[room] create uid:", uid, "room", roomid)
		return r
	end
	room_cache[#room_cache + 1] = r
	log("[room] create uid:", uid, "room", roomid, "error", err)
	return nil
end

local function del(self)
	--TODO: recycle
	local roomid = self.roomid
	rooms[roomid - roomid_start] = nil
	log("[room] del room:", roomid)
end

local function enter(room, uid, side, gate)
	local uidlist = room.uidlist
	if side == RED then
		local redcount = room.redcount + 1
		room.redcount = redcount
		insert(uidlist, redcount, uid)
	else
		uidlist[#uidlist + 1] = uid
	end
	online(uid, gate)
	uid_to_room[uid] = room
end


local function leave(room, uid)
	local uid = e.uid
	local side = BLUE
	local uidlist = room.uidlist
	for i = 1, #uidlist do
		if uidlist[i] == uid then
			remove(uidlist, i)
			local redcount = room.redcount
			if i <= redcount then
				side = RED
				room.redcount = redcount - 1
			end
			break
		end
	end
	offline(uid, nil)
	if room.status ~= BATTLE then
		room.entities[uid] = nil
		room[SIDE][uid] = nil
	end
	if #uidlist == 0 then
		del(room)
	else
		local ack = {
			uid = uid,
			side = side,
			roomid = room.roomid
		}
		multicast(uidlist, "battleleave_a", ack)
		room.call("roomleave_c", ack)
	end
end

local scene = require "conf.Scene"
local building = require "conf.Building"
local conf_red_tower = {
	"RedCrystal",
	"RedUpTower",
	"RedMidTower",
	"RedDownTower",
}
local red_tower = {
	"redcrystal",
	"redup",
	"redmiddle",
	"reddown",
}
local conf_blue_tower = {
	"BlueCrystal",
	"BlueUpTower",
	"BlueMidTower",
	"BlueDownTower",
}
local blue_tower = {
	"bluecrystal",
	"blueup",
	"bluemiddle",
	"bluedown",
}

local function from_entity(e)
	return {
		uid = e.uid,
		name = e.name,
		heroid = e.heroid,
		level = e.level,
		px = e.px,
		pz = e.pz,
		hp = e[HP],
		mp = e[MP],
		side = e.side,
		hpmax = e[HPMAX],
		mpmax = e[MPMAX],
		speed = e[SPEED],
	}
end

local function collect_list(list, l)
	for j = 1, #list do
		l[#l + 1] = from_entity(list[j])
	end
	return l
end

local function battlestart_n(room)
	local entities = {}
	for _, e in pairs(room.entities) do
		if e.type == CHARACTER then
			entities[#entities + 1] = from_entity(e)
		end
	end
	return {
		entities = entities,
		redcrystal = from_entity(room.redcrystal),
		bluecrystal = from_entity(room.bluecrystal),
		redup = collect_list(room.redup, {}),
		redmiddle = collect_list(room.redmiddle, {}),
		reddown = collect_list(room.reddown, {}),
		blueup = collect_list(room.blueup, {}),
		bluemiddle = collect_list(room.bluemiddle, {}),
		bluedown = collect_list(room.bluedown, {}),
	}
end


local function born_building(room, side, conf, tower)
	local depend = room.depend
	local id = room.npcidx + 1
	local team = room[side]
	local entities = room.entities
	-- create building
	local s = scene[conf[1]].Building
	local b = building[s]
	local crystal = entity:new(id, b.Desc, b.HeroID, b.Coord, side, CRYSTAL)
	room[tower[1]] = crystal
	for i = 2, #conf do
		local parent = crystal
		local l = room[tower[i]]
		local s = scene[conf[i]].Building
		for j = 1, #s do
			id = id + 1
			local b = building[s[j]]
			local e = entity:new(id, b.Desc, b.HeroID,
				b.Coord, side, TOWER)
			print("depend", e.uid, e.name, "=>", parent.name)
			l[#l + 1] = e
			depend[e] = parent
			parent = e
		end
		entities[id] = parent
		team[id] = parent
	end
	room.npcidx = id
end

local function born_character(room)
	local uidlist = room.uidlist
	local redcount = room.redcount
	local red = room[RED]
	local blue = room[BLUE]
	local entities = room.entities
	for i = 1, redcount do
		local uid = uidlist[i]
		local e = entity:new(uid, tostring(uid), 10000, {-6, -6}, RED, CHARACTER)
		entities[uid] = e
		red[uid] = e
	end
	for i = redcount + 1, #uidlist do
		local uid = uidlist[i]
		local e = entity:new(uid, tostring(uid), 10000, {-6, -6}, BLUE, CHARACTER)
		entities[uid] = e
		blue[uid] = e
	end
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
		born_building(room, RED, conf_red_tower, red_tower)
		born_building(room, BLUE, conf_blue_tower, blue_tower)
		born_character(room)
		multicast(uidlist, "battlestart_n", battlestart_n(room))
	end
	local ack = {
		current = n,
		total = total,
	}
	return "battleready_a", ack
end


function M:killed(e)
	local t = e.type
	print("killed", e.uid, t)
	if t == CRYSTAL then
		if self.redcrystal == e then
			self.status = OVER
			gate.multicast(self.uidlist, "battleover_n", {winner = BLUE})
		else
			self.status = OVER
			gate.multicast(self.uidlist, "battleover_n", {winner = RED})
		end
	else
		local entities = self.entities
		local team = self[e.side]
		local uid = e.uid
		entities[uid] = nil
		team[uid] = nil
		if t == CHARACTER then
			self.reborn[e] = ms() + 6000
		else
			local depend = self.depend
			local p = depend[e]
			if p then
				local xuid = p.uid
				depend[e] = nil
				entities[xuid] = p
				team[xuid] = p
			end
		end
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
---------------------helper

function M:broadcast(cmd, ack)
	multicast(self.uidlist, cmd, ack)
end

function M:select_nearest_enemy(uid, x, z)
	local target = nil
	local dist = maxinteger
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

---------------------tick

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
		enter(r, uid, side, req.gate)
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
	local req = {
		roomid = roomid,
		uid = uid,
		side = side,
	}
	local uidlist = r.uidlist
	multicast(uidlist, "battleenter_n", req)
	enter(r, uid, side, req.gate)
	log("[room] enter uid:", uid, "room", roomid, "count", #uidlist)
	return "battleenter_a" ,r
end

function E.battleleave_r(req)
	local uid = req.uid_
	local r = uid_to_room[uid]
	if r then
		leave(r, uid)
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
		print("ATK", atk, target, req.target, req.skill)
		if target then
			local s = atk.skills[req.skill]
			s:fire(r, atk, target)
		end
	end
end

---------------------------------
function M.start(slot)
	roomid_start = slot * const.ROOM_PER_BATTLE
	timer_tick()
end


return M

