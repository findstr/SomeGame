local E = require "E"
local router = require "router"
local json = require "sys.json"
local proto = require "proto.client" --TODO: reduce proto
local core = require "sys.core"
local gate = require "agent.gate"
local battle = require "agent.battle"
local errno = require "errno.room"

local rooms = {}
local uid_to_battle

local pairs = pairs
local ipairs = ipairs
local remove = table.remove
local log = core.log
local jencode = json.encode

function router.roomshow_c(req)
	local battle = req.battle
	local id = req.roomid * 2000 + req.battle
	local owner = req.owner
	rooms[id] = req
	if owner then
		uid_to_battle[owner] = battle
	end
	log("[room] roomshow_c", id, jencode(req))
	return "roomshow_a", req
end

function router.roomhide_c(req)
	local id = req.roomid * 2000 + req.battle
	rooms[id] = req
	log("[room] roomhide_c", id)
	return "roomhide_a", req
end

function router.battlejoin_c(req)
	local uid, battle = req.uid, req.battle
	uid_to_battle[uid] = battle
	log("[room] battlejoin uid:", uid, "battle:", battle)
	return "battlejoin_a", nil
end

function router.battleleave_c(req)
	local uid = req.uid
	local battle = uid_to_battle[uid]
	uid_to_battle[uid] = nil
	log("[room] battleleave uid:", uid, "battle:", battle)
	return "battleleave_a", nil
end

function router.whichbattle_c(req)
	req.battle = uid_to_battle[req.uid]
	log("[room] whichbattle_c uid:", req.uid, "battle", req.battle)
	return "whichbattle_a", req
end

local function battleclear(battle)
	for k, v in pairs(rooms) do
		if v.battle == battle then
			rooms[k] = nil
		end
	end
end

function E.roomlist_r(req)
	local l = {}
	for k, v in pairs(rooms) do
		l[#l + 1] = v
	end
	return "roomlist_a", {list = l}
end

local function start()
	uid_to_battle = battle.restore(battleclear)
end

return start
