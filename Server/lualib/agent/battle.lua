local core = require "sys.core"
local json = require "sys.json"
local proto = require "proto.client"
local assert = assert
local pairs = pairs
local ipairs = ipairs
local match = string.match
local tonumber = tonumber
local maxinteger = math.maxinteger
local lprint = core.log
local M = {}

local battle_rpc = {}
local battle_count
local round_robin = 0

function M.join(conns, count)
	if not battle_count then
		battle_count = count
	else
		assert(battle_count == count)
	end
	for i = 1, count do
		local w = conns[i]
		if w then
			battle_rpc[i] = w.rpc
		end
	end
end

function M.new(uids)
	local slot = round_robin % battle_count + 1
	round_robin = slot
	local rpc = battle_rpc[slot]
	if not rpc then
		core.log("[agent.battle] new slot", slot, "is empty")
		return nil
	end
	local ack, cmd = rpc:call("battlenew_c", { uids = uids })
	if not ack then
		core.log("[agent.battle] new slot", slot, " error", cmd)
		return nil
	end
	return slot
end

function M.call(slot, cmd, obj)
	local rpc = battle_rpc[slot]
	if not rpc then
		return nil, "slot is not ready"
	end
	local ack, cmd = rpc:call(cmd, obj)
	return ack, cmd
end

return M

