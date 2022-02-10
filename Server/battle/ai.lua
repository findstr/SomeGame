local core = require "sys.core"
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

function M:newctx(e, name, broadcast, room)
	print("****newctx", broadcast)
	local p = remove(cache)
	if not p then
		p = setmetatable({
			host = e,
			tree = npc,
			room = room,
			target = nil,
			broadcast = broadcast,
			status = IDLE,
		}, mt)
	else
		p.host = e
		p.room = room
		p.tree = npc
		p.target = nil
		p.broadcast = broadcast
		p.status = IDLE
	end
	return p
end

function M:del()
	p.host = nil
	p.tree = nil
	p.target = nil
	p.broadcast = nil
	cache[#cache + 1] = self
end

function M:tick(delta)
	DELTA = delta
	bt(self.tree, AI, self)
end

----------------BT action

local function dist(x1, y1, x2, y2)
	local x = x1 - x2
	local y = y1 - y2
	return x*x + y*y
end

function AI:bt_is_lock_target(args)
	local t = self.target
	print("is_lock_target1")
	if not t then
		return false
	end
	local host = self.host
	local d = dist(t.px, t.pz, host.px, host.pz)
	print("is_lock_target2", d)
	if d < 50 then
		return true
	end
	self.target = nil
	host.vx = 0
	host.vz = 0
	self.broadcast("battlemove_a", host)
	return false
end

function AI:bt_is_hp_less(args)
	local v = args.hp
	return self.host.hp < v
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
		local delta = DELTA
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
		host.broadcast("battlemove_a", host)
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
		self.broadcast("battlemove_a", host)
		return false
	end
	local vx, vz = move_to(host.px, host.pz, t.px, t.pz)
	if vx ~= 0 or vz ~= 0 then
		host.vx = vx
		host.vz = vz
		local delta = DELTA
		host.px = host.px + vx * delta
		host.pz = host.pz + vz * delta
		self.broadcast("battlemove_a", host)
	end
	print("**follow_target", host.vx, host.vz)
	return nil
end

function AI:bt_stop_follow(_)
	self.status = IDLE
	local host = self.host
	host.vx = 0
	host.vz = 0
	self.broadcast("battlemove_a", host)
	return true
end

function AI:bt_lock_nearest()
	local host = self.host
	local p, d = self.room:select_nearest(host.px, host.pz, host.side % 2 + 1)
	print("lock_nearest", p, d)
	if not p then
		return false
	end
	if d > 2 then
		return false
	end
	print("=========lock target:", p.uid)
	self.target = p
	return true
end

function AI:bt_atk_target()
	local t = self.target
	local host = self.host
	local d = dist(host.px, host.pz, t.px, t.pz)
	if d > 2 then
		return false
	end
	self.room:fire_skill(host, t, 1)
	return true
end

return M

