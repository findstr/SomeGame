local ui = require "zx.ui"
local bind = require "binder.login"
local server = require "server"

local M = {}
local mt = {__index = M}
local setmetatable = setmetatable

function M:start(view)
	local vm = {
		view = view,
	}
	bind(vm, view)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	local login_finish = function(uid, status)
		print("++++loin_finish", uid, status)
		ui.close(vm)
	end
	local login = function()
		local user = vm.account_input.text
		local passwd = vm.password_input.text
		if #user == 0 or #passwd == 0 then
			print(vm.login_tips)
			vm.login_tips.text = "账号或密码不能为空"
			return
		end
		vm.login_tips.text = ""
		server.login(user, passwd, login_finish)
	end
	vm.account_input.text = "333"
	vm.password_input.text = "333"
	vm.login_button.onClick:Add(login)
	vm.register_button.onClick:Add(login)
	return vm
end

function M:stop()
	print("close")
end

return M