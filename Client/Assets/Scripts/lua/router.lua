local proto = require "proto"
local json = require "zx.json"
local rawset = rawset
local assert = assert
local type = type
local setmetatable = setmetatable
local M = {}
local function transfer(t, kk, v)
	local x, k
	if type(kk) == "string" then
		k = assert(proto:tag(kk), kk)
	else
		k = kk
	end
	if kk == "battlemove_a" then
		x = v
	else
		x = function(obj, cmd)
			if cmd ~= 0x1302 then
				print("RECV:" .. json.encode(obj) .. string.format("%02x", cmd))
			end
			v(obj, cmd)
		end
	end
	rawset(t, k, x)
end

local mt = {
	attach = function(self)
		for k, v in pairs(self) do
			M[k] = v
		end
	end,
	detach = function(self)
		for k, _ in pairs(self) do
			M[k] = nil
		end
	end,
	__index = nil,
	__newindex = transfer,
}
mt.__index = mt


function M.new()
	return setmetatable({}, mt)
end

setmetatable(M, {__newindex = transfer})


return M
