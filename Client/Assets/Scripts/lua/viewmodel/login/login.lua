local ui = require "zx.ui"
local router = require "router":new()
local bind = require "binder.login".login
local battle = require "battle"
local server = require "server"
local tips = require "tips"
local log = print

local M = {}
local mt = {__index = M}
local setmetatable = setmetatable

local ROOM_IDLE<const> = 1   
local ROOM_BATTLE<const> = 2 

function router.battleenter_a(ack)
	print("battleenter")
	ui.inplace("room.room", ack.roomid, ack.name, ack.uidlist, ack.redcount)
end

function router.battlestart_n(ack)
	print("battlestart_n")
	ui.clear()
	battle.start(ack)
end

local function login_finish(ack, status)
	if ack then
		ui.inplace("lobby.lobby")
		server.send("roomlist_r")
	end
end


local function login()
	local user = M.account_input.text
	local passwd = M.password_input.text
	if #user == 0 or #passwd == 0 then
		tips.show("账号或密码不能为空")
		return
	end
	server.login(user, passwd, login_finish)
end

function M:start(view)
	bind(M, view)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	

	M.account_input.text = "333"
	M.password_input.text = "333"
	M.login_button.onClick:Add(login)
	M.register_button.onClick:Add(login)
	router:attach()
	log("[login] start")
	return 
end

function M:stop()
	router:detach()
	log("[login] stop")
end

return M
