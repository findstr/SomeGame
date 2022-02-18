local core = require "sys.core"
local property = require "property"
local helper = require "helper"
local bt = require "bt"
local npc = require "bt.npc"
local cache = require "cache" ()

local M = {}
local AI = {}
local mt = {__index = M}

local log = core.log
local remove = table.remove
local setmetatable = setmetatable
local abs = math.abs
local sqrt = math.sqrt

local IDLE<const> = 0
local GOHOME<const> = 1
local FOLLOW<const> = 2

local DELTA = 0
local ROOM = nil

local HP<const> = property.HP
local SPEED<const> = property.SPEED

function M:newctx(e, name)
	local p = remove(cache)
	if not p then
		p = setmetatable({
			host = e,
			tree = npc,
			target = nil,
			status = IDLE,
		}, mt)
	else
		p.host = e
		p.tree = npc
		p.target = nil
		p.status = IDLE
	end
	return p
end

function M:del()
	for k, _ in pairs(self) do
		self[k] = nil
	end
	cache[#cache + 1] = self
end

function M:tick(room, delta)
	ROOM = room
	DELTA = delta
	bt(self.tree, AI, self)
end

----------------BT action

local dist = helper.dist

function AI:bt_is_lock_target(args)
	local t = self.target
	print("is_lock_target1")
	if not t then
		return false
	end
	local host = self.host
	local d = dist(t.px, t.pz, host.px, host.pz)
	print("is_lock_target2", d)
	if d < args.range then
		return true
	end
	self.target = nil
	host.vx = 0
	host.vz = 0
	ROOM:broadcast("battlemove_a", host)
	return false
end

function AI:bt_is_hp_less(args)
	print("bt_is_hp_less", self.host[HP], args.hp)
	return self.host[HP] < args.hp
end

local function move_to(x, z, dx, dz)
	dx = dx - x
	dz = dz - z
	local d = dx * dx + dz * dz
	if d <= 0.0001 then
		return 0, 0
	end
	d = sqrt(d)
	local vx = dx / d * 1
	local vz = dz / d * 1
	return vx, vz
end

function AI:bt_gohome(_)
	local host = self.host
	if self.status == GOHOME then
	end
	local vx, vz = move_to(host.px, host.pz, host.homex, host.homez)
	if vx ~= 0 or vz ~= 0 then
		local ret
		host.vx, host.vz = vx, vz
		local delta = DELTA * host[SPEED]
		host.px = host.px + vx * delta
		host.pz = host.pz + vz * delta
		local dx = host.px - host.homex
		local dz = host.pz - host.homez
		local d = dx * dx + dz * dz
		if d < 0.1 then
			host.vx = 0
			host.vz = 0
			ret = true
		end
		ROOM:broadcast("battlemove_a", host)
		return ret
	end
	return true
end

function AI:bt_follow_target(_)
	self.status = FOLLOW
	local t = self.target
	print("**bt_follow_target", t)
	local host = self.host
	if not t then
		host.vx = 0
		host.vz = 0
		ROOM:broadcast("battlemove_a", host)
		return false
	end
	local vx, vz = move_to(host.px, host.pz, t.px, t.pz)
	if vx ~= 0 or vz ~= 0 then
		host.vx = vx
		host.vz = vz
		local delta = DELTA
		host.px = host.px + vx * delta
		host.pz = host.pz + vz * delta
		ROOM:broadcast("battlemove_a", host)
	end
	print("**follow_target", host.vx, host.vz)
	return nil
end

function AI:bt_stop_follow(_)
	self.status = IDLE
	local host = self.host
	host.vx = 0
	host.vz = 0
	ROOM:broadcast("battlemove_a", host)
	return true
end

function AI:bt_lock_nearest(args)
	local host = self.host
	local p, d = ROOM:select_nearest_enemy(host.uid, host.px, host.pz)
	if not p then
		return false
	end
	if d > args.range then
		return false
	end
	print("=========lock target:", p.uid)
	self.target = p
	return true
end

function AI:bt_atk_target()
	return self.host.skills[1]:fire(ROOM, self.host, self.target)
end

return M

