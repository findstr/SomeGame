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

local room_rpc = nil
local room_count

function M.join(conns, count)
	if not room_count then
		room_count = count
	end
	assert(room_count == 1)
	local w = conns[1]
	if w then
		room_rpc = w.rpc
	end
end

function M.call(cmd, obj)
	if not room_rpc then
		return nil, "slot is not ready"
	end
	local ack, cmd = room_rpc:call(cmd, obj)
	return ack, cmd
end

return M

