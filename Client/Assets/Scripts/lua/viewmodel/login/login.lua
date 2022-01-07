local ui = require "zx.ui"
local bind = require "binder.login".login
local server = require "server"
local tips = require "tips"
local log = print

local M = {}
local mt = {__index = M}
local setmetatable = setmetatable

local function login_finish(uid, status)
	if uid then
		ui.inplace("lobby.lobby")
	else
		tips.show("密码错误(" .. status .. ")")
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
	
	log("[login] start")
	return 
end

function M:stop()
	log("[login] stop")
end

return M