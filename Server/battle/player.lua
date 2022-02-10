local core = require "sys.core"
local router = require "router"
local errno = require "errno.battle"
local gate = require "agent.gate"
local player_cache = require "cache" ()
local room = require "room"
local E = require "E"

local RED<const> = 1
local BLUE<const> = 2

local M = {}
local players = {}
local mt = {__index = M}

local log = core.log
local remove = table.remove
local setmetatable = setmetatable


local function new(gateid, uid, hero, side)
	local p = players[uid]
	if p then
		p:del()
	end
	local p = remove(player_cache)
	if not p then
		p = setmetatable({
			uid = uid,
			hero = hero,
			hp = 10000,
			mp = 100,
			px = -4.6,
			pz = -5.8,
			vx = 0,
			vz = 0,
			room = nil,
			side = side,
		}, mt)
	else
		p.uid = uid
		p.hero = hero
		p.hp = 10000
		p.mp = 100
		p.px = -4.6
		p.pz = -5.8
		p.vx = 0
		p.vz = 0
		p.room = nil
		p.side = side
	end
	gate.online(uid, gateid)
	players[uid] = p
	return p
end

function M:del()
	local r = self.room
	if r then
		self.room = nil
		local uid = self.uid
		gate.offline(uid, nil)
		players[uid] = nil
		r:leave(self)
	end
	player_cache[#player_cache + 1] = self
end

function M:tick(delta)

end

--------------------------------------------socket handler

function router.battlerestore_c(req)
	local p = players[req.uid]
	local room = p and p.room
	if not room then
		req.list = req
		return "roomlist_a", req
	end
	return room:restore()
end

function router.battlecreate_c(req)
	local uid = req.uid
	local p = new(req.gate, uid, 1000, RED)
	local r = room:new(req.name, p)
	if r then
		p.room = r
		log("[player] battlecreate uid:", uid, "room", r.roomid)
		return "battlecreate_a", r
	end
	p:del()
	log("[player] battlecreate uid:", uid, "error")
	return "error", {errno = errno.SYSTEM}
end

function E.battleenter_c(req)
	local uid, side = req.uid, req.side
	local roomid = req.roomid
	local p = new(req.gate, uid, 1000, side)
	local r, err = room:enter(roomid, p)
	if not r then
		p:del()
		return "error", {errno = err}
	end
	p.room = r
	return "battleenter_a", r
end

function E.battleleave_r(req)
	local uid = req.uid_
	local p = players[uid]
	if p then
		p:del()
	end
	log("[player] battleleave uid:", uid)
	return "battleleave_a", req
end

function E.battleready_r(req)
	local uid = req.uid_
	local p = players[uid]
	if not p then
		log("[player] play uid:", uid, "no room")
		return "error", {errno = errno.NOROOM}
	end
	p.room:ready(p)
	log("[player] battleready_r", uid, "room", p.room.roomid)
	return "battleready_a", req
end

function E.battlemove_r(req)
	local uid = req.uid_
	local p = players[uid]
	if p then
		p.px = req.px
		p.pz = req.pz
		p.vx = req.vx
		p.vz = req.vz
		p.room:broadcast("battlemove_a", p)
	end
end

function E.battleskill_r(req)
	local uid = req.uid_
	local p = players[uid]
	if p then
		p.room:fire_skill(p, req.target, req.skill)
		return
	end
end

return M

