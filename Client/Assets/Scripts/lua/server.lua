local socket = require "zx.socket"
local json = require "zx.json"
local proto = require "proto"
local router = require "router"
local errno = require "conf.Errno"
local tips = require "tips"
local tonumber = tonumber
local auth_server
local gate_server
local login_cb
local auth = {}
local log = print
local tostring = tostring

local M = {}

local function login_fail(reason)
		M.uid = nil
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
	tips.show("GateClose", function()
		CS.UnityEngine.GameObject.Find("ZXMain"):GetComponent(typeof(CS.ZXMain)):Restart()
	end)
end

function router.error_a(obj, _)
	local cmd, err = obj.cmd, obj.errno
	local s = errno[err]
	if s then
		s = s.Value
	else
		s = "error:" + err
	end
	tips.show(s)
	log("[server] error cmd:", obj.cmd, "errno:", string.format("%02x", obj.errno))
	local cb = router[obj.cmd]
	if cb then
		cb(nil, obj.errno)
	end
end

function router.login_a(obj, errno)
	log("[server] login_a", M.uid, obj.members, obj.members and table.concat(obj.members) or "")
	if login_cb then
		if obj then
			login_cb(obj, nil)
		else
			login_fail(errno)
		end
	end
end

function router.roomlist_a(obj, errno)
	log("roomlist_a", obj and require "zx.json".encode(obj) or errno)
end

function router.kick_n(obj)
	tips.show("账号在其他地方登录", function()
		CS.UnityEngine.GameObject.Find("ZXMain"):GetComponent(typeof(CS.ZXMain)):Restart()
	end)
end

auth[proto:tag("error_a")] = function(obj, _)
	log("[server] error cmd:", obj.cmd, "errno:", obj.errno)
	local cmd, err = obj.cmd, obj.errno
	local s = errno[err]
	if s then
		s = s.Value
	else
		s = "error:" + err
	end
	tips.show(s)
	if login_cb then
		login_cb(nil, tostring(obj.errno))
	end
	auth_server:close()
	login_cb = nil
	auth_server = nil
end

auth[proto:tag("auth_a")] = function(obj, _)
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
	M.uid = obj.uid
	log("[server] connect gate", ip, port)
	gate_server:send("login_r", {
		uid = obj.uid,
		token = obj.token,
	})
end


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
	if cmd ~= "battlemove_r" then
		print("Send:" .. cmd .. (obj and json.encode(obj) or "[]"))
	end
	gate_server:send(cmd, obj)
end

return M
