local BATTLE = require "module".battle
local common = require "errno.common"

local M = setmetatable({
	NOROOM	= 1 + BATTLE,	--房间号不存在
	NORIGHT = 2 + BATTLE,	--没有房间权限
	INROOM = 3 + BATTLE,	--已经在房间中
	OUTROOM = 4 + BATTLE,	--不在房间中
}, common)

return M


