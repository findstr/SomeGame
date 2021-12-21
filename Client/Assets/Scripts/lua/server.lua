local socket = require "zx.socket"
local proto = require "proto"
local router = require "router"
local tonumber = tonumber
local auth_server
local gate_server
local login_cb
local auth = {}
local uid = nil
local log = print
local tostring = tostring

local function login_fail(reason)
		uid = nil
		if login_cb then
			login_cb(nil, reason)
			login_cb = nil
		end
end

local function auth_close(fd)
	log("[server] auth_close", fd)
	auth_server = nil
	if not gate_server then
		login_fail("auth close")
	end
end

local function gate_close(fd)
	log("[server] gate_close", fd)
	gate_server = nil
	login_fail("gate close")
end

function router.error_a(obj, _)
	local cmd = obj.cmd
	log("[server] error cmd:", obj.cmd, "errno:", obj.errno)
	local cb = router[obj.cmd]
	if cb then
		cb(nil, obj.errno)
	end
end

function router.login_a(obj, errno)
	log("[server] login_a", uid, errno)
	if login_cb then
		if obj then
			login_cb(uid, nil)
		else
			login_fail(errno)
		end
	end
end

function router.roomlist_a(obj, errno)
	log("roomlist_a", obj and require "zx.json".encode(obj) or errno)
end

function auth.error_a(obj, _)
	log("[server] error cmd:", obj.cmd, "errno:", obj.errno)
	if login_cb then
		login_cb(nil, tostring(obj.errno))
	end
	auth_server:close()
	login_cb = nil
	auth_server = nil
end

function auth.auth_a(obj, _)
	log("[server] auth_a uid:", obj.uid, obj.gate, obj.token)
	auth_server:close()
	auth_server = nil
	local ip, port = obj.gate:match("([^:]+):(%d+)")
	log(ip, port)
	port = tonumber(port)
	gate_server = socket:connect {
		ip = ip,
		port = port,
		proto = proto,
		router = router,
		close = gate_close
	}
	if not gate_server then
		cb(nil, "connect auth fail")
		return
	end
	uid = obj.uid
	log("[server] connect gate", ip, port)
	gate_server:send("login_r", {
		uid = obj.uid,
		token = obj.token,
	})
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
		cb(nil, "connect auth fail")
		return
	end
	log("[server] connect auth", ip, port)
	auth_server:send("auth_r", {
		account = user,
		passwd = pwd,
		server = 1
	})
	return
end

function M.send(cmd, obj)
	gate_server:send(cmd, obj)
end

return M
