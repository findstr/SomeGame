local E = require "E"
local proto = require "proto.client" --TODO: reduce proto
local core = require "sys.core"
local gate = require "agent.gate"
local errno = require "errno.battle"

local uid_to_scene = {}
local scenes = {}

local lprint = core.log
local concat = table.concat
local remove = table.remove

function E.battlenew_c(req)
	local id = #scenes + 1
	local uids = req.uids
	local s = {
		members = uids
	}
	scenes[id] = s
	for _, uid in pairs(uids) do
		uid_to_scene[uid] = s
	end
	lprint("[battle] battlecreate:", concat(uids), "ok")
	return "battlenew_a", req
end

function E.battleenter_c(req)
	local uid = req.uid
	local s = uid_to_scene[uid]
	lprint("[battle] battleenter:", uid, "scene", s)
	if not s then
		return "error", { errno = errno.OUTSCENE }
	end
	gate.online(uid, req.gate)
	local exist = false
	local mem = s.members
	for i = 1, #mem do
		if mem[i] == uid then
			exist = true
			break
		end
	end
	if not exist then
		mem[#mem + 1] = uid
	end
	return "battleenter_a", req
end

function E.battlemove_r(req)
	local uid = req.uid_
	req.uid = uid
	local s = uid_to_scene[uid]
	gate.multicast(s.members, "battlemove_a", req)
end

function E.battleskill_r(req)
	local uid = req.uid_
	req.uid = uid
	local s = uid_to_scene[uid]
	gate.multicast(s.members, "battleskill_a", req)
end

