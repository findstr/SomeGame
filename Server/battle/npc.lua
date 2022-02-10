local core = require "sys.core"
local bt = require "bt"
local bt_npc = require "bt.npc"
local router = require "router"
local npc_cache = require "cache" ()
local E = require "E"
local abs = math.abs
local sqrt = math.sqrt

local RED<const> = 1
local BLUE<const> = 2

local M = {}
local mt = {__index = M}

local log = core.log
local remove = table.remove
local setmetatable = setmetatable

local IDLE<const> = 0
local GOHOME<const> = 1
local FOLLOW<const> = 2

function M:new(room, uid, hero, side)
	local p = remove(npc_cache)
	if not p then
		p = setmetatable({
			uid = uid,
			hero = hero,
			hp = 100,
			mp = 100,
			hpmax = 100,
			mpmax = 100,
			homex = -4.6,
			homez = -5.8,
			px = -4.6,
			pz = -5.8,
			vx = 0,
			vz = 0,
			room = room,
			side = side,
			target = nil,
			status = IDLE,
		}, mt)
	else
		p.uid = uid
		p.hero = hero
		p.hp = 100
		p.mp = 100
		p.hpmax = 100
		p.mpmax = 100
		p.homex = -4.6
		p.homez = -5.8
		p.px = -4.6
		p.pz = -5.8
		p.vx = 0
		p.vz = 0
		p.room = room
		p.side = side
		p.target = nil
		p.status = IDLE
	end
	print("newroom", room, room.select_nearest)
	return p
end

function M:del()
	local r = self.room
	if r then
		self.room = nil
	end
	npc_cache[#npc_cache + 1] = self
end

--[[
local battleskill_a = {
	uid = nil,
	skill = nil,
	mp = nil,
	target = nil,
	targethp = nil
}
function M:fire_skill(skill, t)
	local room = skill.room
	local hp = t.hp
	hp = hp - 10
	if hp < 0 then
		hp = 0
	end
	t.hp = hp
	self.mp = self.mp - 1
	battleskill_a.uid = self.uid
	battleskill_a.skill = skill
	battleskill_a.mp = self.mp
	battleskill_a.target = t.uid
	battleskill_a.targethp = t.hp
	room:multicast("battleskill_a", battleskill_a)
	if hp == 0 then
		room:checkover()
	end
end
]]

function M:tick(delta)
	print("npc tick")
	bt(bt_npc, self, self, delta)
end

----------------BT action

local function dist(x1, y1, x2, y2)
	local x = x1 - x2
	local y = y1 - y2
	return x*x + y*y
end

function M:bt_is_lock_target(args)
	local t = self.target
	print("is_lock_target1")
	if not t then
		return false
	end
	local d = dist(t.px, t.pz, self.px, self.pz)
	print("is_lock_target2", d)
	if d < 50 then
		return true
	end
	self.target = nil
	self.vx = 0
	self.vz = 0
	self.room:broadcast("battlemove_a", self)
	return false
end

function M:bt_is_hp_less(args)
	local v = args.hp
	return self.hp < v
end

local function move_to(x, z, dx, dz)
	dx = dx - x
	dz = dz - z
	local d = sqrt(dx * dx + dz * dz)
	local vx = dx / d * 1
	local vz = dz / d * 1
	return vx, vz
end

function M:bt_gohome(_, delta)
	if self.status == GOHOME then
		local vx, vz = self.vx, self.vz
		self.px = self.px + vx * delta
		self.pz = self.pz + vz * delta
		local dx = self.px - self.homex
		local dz = self.pz - self.homez
		local d = dx * dx + dz * dz
		if d < 0.01 then
			self.vx = 0
			self.vz = 0
		end
		print("**gohome", d)
		self.room:broadcast("battlemove_a", self)
		return true
	end
	self.status = GOHOME
	self.vx, self.vz = move_to(self.px, self.pz, self.homex, self.homez)
	self.room:broadcast("battlemove_a", self)
	return nil
end

function M:bt_follow_target(_, delta)
	self.status = FOLLOW
	local t = self.target
	print("**bt_follow_target", t)
	if not t then
		self.vx = 0
		self.vz = 0
		self.room:broadcast("battlemove_a", self)
		return false
	end
	local vx, vz = move_to(self.px, self.pz, t.px, t.pz)
	self.vx = vx
	self.vz = vz
	self.px = self.px + vx * delta
	self.pz = self.pz + vz * delta
	self.room:broadcast("battlemove_a", self)
	print("**follow_target", self.vx, self.vz)
	return nil
end

function M:bt_stop_follow(_, delta)
	self.status = IDLE
	self.vx = 0
	self.vz = 0
	self.room:broadcast("battlemove_a", self)
	return true
end

function M:bt_lock_nearest()
	local p, d = self.room:select_nearest(self.px, self.pz, self.side % 2 + 1)
	if not p then
		return false
	end
	if d > 1 then
		return false
	end
	print("=========lock target:", p.uid)
	self.target = p
	return true
end

function M:bt_atk_target()
	local t = self.target
	local d = dist(self.px, self.pz, t.px, t.pz)
	if d > 1 then
		return false
	end
	self.room:fire_skill(self, t.uid, 1)
	return true
end

return M

