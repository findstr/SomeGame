local common = require "errno.common"
local ROOM = require "module".room

local M = setmetatable({
	NOROOM	= 1 + ROOM,	--房间号不存在
	NORIGHT = 2 + ROOM,	--没有房间权限
}, common)

return M


