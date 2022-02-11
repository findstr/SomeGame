local core = require "sys.core"
local router = require "router"
local errno = require "errno.battle"
local gate = require "agent.gate"
local property = require "property"
local nskill = require "skill.normal"
local Hero = require "conf.Hero"
local E = require "E"

local M = {}
local mt = {__index = M}
local cache = require "cache" ()

local log = core.log
local pairs = pairs
local remove = table.remove
local setmetatable = setmetatable

local HP<const> = property.HP
local MP<const> = property.MP
local HPMAX<const> = property.HPMAX
local MPMAX<const> = property.MPMAX


function M:new(uid, heroid, x, z, side, broadcast)
	local conf = Hero[heroid][1]
	local e = remove(cache)
	if not e then
		e = setmetatable({}, mt)
	end
	e.uid = uid
	e.heroid = heroid
	e.level = 1
	e.px = x
	e.pz = z
	e.vx = 0
	e.vz = 0
	e.homex = x
	e.homez = z
	e.side = side
	e.skills = {nskill:new(1, conf.NormalSkill)}
	e.broadcast = broadcast
	for k, id in pairs(property) do
		e[id] = conf[k]
	end
	e[HPMAX] = e[HP]
	e[MPMAX] = e[MP]
	return e
end

function M:del()
	for k, _ in pairs(self) do
		self[k] = nil
	end
	cache[#cache + 1] = self
end

function M:tick(room, delta)

end

return M

