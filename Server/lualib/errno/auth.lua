local AUTH = require "module".auth
local common = require "errno.common"

local M = setmetatable({
	PASSWD		= 1 + AUTH,		--密码错误
	SYSTEM		= 2 + AUTH,		--系统错误
	BUSY		= 3 + AUTH,		--服务器忙
	FORBID		= 4 + AUTH,		--被封号
	PARAM		= 5 + AUTH,		--错误参数
	FULL		= 6 + AUTH,		--服务器已满
	EXIST		= 7 + AUTH,		--账户名已存在
	LOGINFIRST	= 8 + AUTH,		--需要先登录
	TOKEN		= 9 + AUTH,		--令牌失效
	NEWLOGIN	= 10 + AUTH,	--用户在其他地方登录
}, common)


return M

