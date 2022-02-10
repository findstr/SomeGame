local core = require "sys.core"
local router = require "router"
local errno = require "errno.battle"
local gate = require "agent.gate"
local bt = require "bt"
local ai = require "ai"
local npc = require "bt.npc"
local E = require "E"

local M = {}
local mt = {__index = M}
local cache = require "cache" ()

local log = core.log
local remove = table.remove
local setmetatable = setmetatable


function M:new(uid, hero, x, z, side, broadcast)
	local p = remove(cache)
	if not p then
		p = setmetatable({
			uid = uid,
			hero = hero,
			hp = 100,
			mp = 100,
			px = x,
			pz = z,
			homex = x,
			homez = z,
			vx = 0,
			vz = 0,
			side = side,
			broadcast = broadcast,
		}, mt)
	else
		p.uid = uid
		p.hero = hero
		p.hp = 100
		p.mp = 100
		p.px = x
		p.pz = z
		p.vx = 0
		p.vz = 0
		p.homex = x
		p.homez = z
		p.side = side
		p.broadcast = broadcast
	end
	return p
end

function M:del()
	self.broadcast = nil
	cache[#cache + 1] = self
end

function M:tick(delta)

end

return M

