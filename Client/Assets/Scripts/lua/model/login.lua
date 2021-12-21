local socket = require "zx.socket"
local proto = require "proto"
local router = require "router"
local tonumber = tonumber
local auth_server
local gate_server
local login_cb
local auth = {}
local tostring = tostring

local function socket_close(fd)
	print("[model.login] socket_close", fd)
	if login_cb then
		login_cb(nil, "closed")
	end
	if auth_server then
		auth_server:close()
	end
	if gate_server then
		gate_server:close()
	end
	login_cb = nil
	auth_server = nil
end

function router.error_a(obj, _)
	local cmd = obj.cmd
	print("[model.login] error cmd:", obj.cmd, "errno:", obj.errno)
	local cb = router[obj.cmd]
	if cb then
		cb(nil, obj.errno)
	end
end

function router.login_a(obj, errno)
	print("login_a", obj and require "zx.json".encode(obj) or errno)
end

function auth.error_a(obj, _)
	print("[model.login] error cmd:", obj.cmd, "errno:", obj.errno)
	if login_cb then
		login_cb(nil, tostring(obj.errno))
	end
	auth_server:close()
	login_cb = nil
	auth_server = nil
end

function auth.auth_a(obj, _)
	print("[model.login] auth_a uid:", obj.uid, obj.gate, obj.token)
	auth_server:close()
	auth_server = nil
	local ip, port = obj.gate:match("[^:]+:(%d+)")
	port = tonumber(port)
	gate_server = socket:connect {
		ip = ip,
		port = port,
		proto = proto,
		router = router,
		close = 
end


local M = {}
function M.login(user, pwd, cb)
	if auth_server then
		cb(nil, "login_repeat")
		return
	end
	login_cb = cb
	local ip = "192.168.2.118"
	local port = 7000
	auth_server = socket:connect {
		ip = ip,
		port = port,
		proto = proto,
		router = auth,
		close = socket_close,
	}
	if not auth_server then
		cb(nil, "connect fail")
		return
	end
	print("[model.login] socket connect", ip, port)
	auth_server:send("auth_r", {
		account = user,
		passwd = pwd,
		server = 1
	})
	return
end

return M
