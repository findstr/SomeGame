local proto = require "proto"
local json = require "zx.json"
local rawset = rawset
local assert = assert
local M = setmetatable({}, {__newindex = function(t, kk, v)
	local x
	local k = assert(proto:tag(kk), kk)
	if kk == "battlemove_a" then
		x = v
	else	
		x = function(obj, cmd)
			print("RECV:" .. json.encode(obj) .. string.format("%02x", cmd))
			v(obj, cmd)
		end
	end
	rawset(t, k, x)
end})


return M
