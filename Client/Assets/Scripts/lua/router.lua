local proto = require "proto"
local rawset = rawset
local M = setmetatable({}, {__newindex = function(t, k, v)
	k = proto:tag(k)
	rawset(t, k, v)
end})


return M
