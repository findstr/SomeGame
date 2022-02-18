local core = require "sys.core"
local conf = require "conf.Skill"
local helper = require "helper"
local property = require "property"
local M = {}

M.__index = M

local HP<const> = property.HP
local MP<const> = property.MP
local PATK<const> = property.PATK
local PTH<const> = property.PTH
local PDEF<const> = property.PDEF
local ms = core.monotonic
local dist2 = helper.dist2
local setmetatable = setmetatable

function M:new(slot, skillid)
	local s = conf[skillid][1]
	local dist = s.Distance
	return setmetatable({
		data = s,
		level = 1,
		cd = s.CD,
		time = 0,
		slot = slot,
		dist2 = dist * dist
	}, M)
end

local battleskill_a = {
	uid = nil,
	skill = nil,
	mp = nil,
	target = nil,
	targethp = nil
}



function M:fire(room, atk, target)
	local now = ms()
	if self.time > now then
		return nil
	end
	if dist2(atk.px, atk.pz, target.px, target.pz) > self.dist2 then
		return false
	end
	self.time = now + self.cd
	local data = self.data
	local patk = atk[PATK] + data.PATK
	local pdef = target[PDEF] - atk[PTH] - data.PTH
	print("***", patk, pdef)
	if pdef < 0 then
		pdef = 0
	end
	patk = patk - patk * pdef // (pdef + 603)
	local n = target[HP] - patk
	print("***==", target[HP], n)
	if n < 0 then
		n = 0
	end
	target[HP] = n
	battleskill_a.uid = atk.uid
	battleskill_a.skill = self.slot
	battleskill_a.mp = atk[MP]
	battleskill_a.target = target.uid
	battleskill_a.targethp = n
	room:broadcast("battleskill_a", battleskill_a)
	if n == 0 then
		room:killed(target)
	end
	return true
end


return M

