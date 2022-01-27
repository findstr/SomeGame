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
local battle_epoch = {}
local battle_count
local round_robin = 0
local join_cb

function M.join(conns, count)
	if not battle_count then
		battle_count = count
	else
		assert(battle_count == count)
	end
	for i = 1, count do
		local w = conns[i]
		if w then
			if join_cb then
				local e = battle_epoch[i]
				if not e or w.epoch > e then
					join_cb(i)
				end
			end
			battle_epoch[i] = w.epoch
			battle_rpc[i] = w.rpc
		end
	end
end

function M.call(slot, cmd, obj)
	local rpc = battle_rpc[slot]
	if not rpc then
		return nil, "slot is not ready"
	end
	local ack, cmd = rpc:call(cmd, obj)
	return ack, cmd
end

function M.restart_cb(cb)
	join_cb = cb
end

function M.restore()
	local buf = {}
	while not battle_count do
		core.sleep(100)
	end
	for i = 1, battle_count do
		while not battle_rpc[i] do
			core.sleep(100)
		end
		while true do
			local rpc = battle_rpc[i]
			local ack, err = rpc:call("battleplayers_c")
			if ack then
				buf[i] = ack.rooms
				break
			else
				lprint(TAG, "restore_online", i, "error", err)
				core.sleep(500)
			end
		end
	end
	return buf
end

return M

