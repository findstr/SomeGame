local core = require "sys.core"
local json = require "sys.json"
local router = require "router"
local errno = require "errno.auth"
local msgserver = require "cluster.msg"
local proto = require "proto.client"

local assert = assert
local pairs = pairs
local ipairs = ipairs
local type = type
local next = next
local rand = math.random
local tremove = table.remove
local lprint = core.log
local room_rpc = nil

local gate_slot
local gate_server
local uid_token = {}
local fd_to_uid = {}
local fd_cmd_queue = setmetatable({}, {__index = function(t, k)
	local v = {}
	t[k] = v
	return v
end})

local uid_info = {
	--roomid,
}
local msg = {}
local gate_addr = assert(core.envget("gate_addr"))

local function clear_uid(uid)
	--TODO:
end

local function kick(uid)
	--TODO:
end

function router.gatekick_c(req)
	local uid = req.uid
	kick(uid)
	lprint("[gate] gatekick_c:",uid)
	return "gatekick_a", {}
end

function router.gatetoken_c(req)
	local uid = req.uid
	local tk = rand(1, 65535)
	if uid_token[uid] then
		kick(uid)
	end
	uid_token[uid] = tk
	lprint("[gate] gatetoken_c uid:", uid, "token", tk)
	return "gatetoken_a", {token = tk, addr = gate_addr}
end

function router.gateonline_c(req)
	local l, i = {}, 0
	for uid, _ in pairs(uid_token) do
		i = i + 1
		l[i] = uid
	end
	return "gateonline_a", {uids = l}
end

local function login_r(fd, req)
	local uid = req.uid
	local token = uid_token[uid]
	if token and token == req.token then
		uid_token[uid] = token + 1
		gate_server:send(fd, "login_a", req)
		lprint("[gate] login_r", fd, uid, "ok")
	else
		gate_server:send(fd, "error_a", {
			cmd = proto:tag("login_a"),
			errno = errno.TOKEN
		})
		lprint("[gate] login_r", fd, uid,
			"token invalid", req.token, token)
	end
end

do
	local tbl = {}
	for k, v in pairs(msg) do
		tbl[proto:tag(k)] = v
	end
	msg = tbl
end

local forward = {
	["room"] = function(fd, uid, req, cmdx)
		local u = uid_info[uid]
		local roomid = u.roomid
		req.uid_ = uid
		local ack, cmd = room_rpc.call(cmdx, req)
		if not ack then
			lprint("[gate] cmd:", name, "fail", cmd)
			return
		end
		print("-------ack", json.encode(ack), cmd)
		local errno = ack.errno
		if errno then
			gate_server:send(fd, "error_a", {
				cmd = cmdx+1,
				errno = errno
			})
		else
			gate_server:send(fd, cmd, ack)
		end
	end
}

function router.handle_c(req)
	print("handle_c", json.encode(req))
	local call = forward[req.type]
	for _, name in ipairs(req.list) do
		local id = assert(proto:tag(name), name)
		if not msg[id] then
			msg[id] = call
		end
	end
	return "handle_c", {}
end

----------------------------------------------------

local M = {}

local cmd_login_r = proto:tag("login_r")

function M.roomjoin(workers, count)
	room_rpc = workers[1]
end

function M.start(slot)
	gate_slot = slot
	gate_server = msgserver.listen {
		proto = proto,
		addr = gate_addr,
		accept = function(fd, addr)
			lprint("[gate] gate_server accept", fd, addr)
		end,
		close = function(fd, errno)
			fd_cmd_queue[fd] = nil
			local uid = fd_to_uid[fd]
			if uid then
				clear_uid(uid)
			end
			lprint("[gate] gate_server close", fd,
				"uid", uid, errno, "online")
		end,
		data = function(fd, cmd, req)
			local uid = fd_to_uid[fd]
			if not uid then
				if cmd ~= cmd_login_r then
					gate_server:send(fd, "error_a", {
						cmd = cmd + 1,
						errno = errno.LOGINFIRST
					})
				else
					login_r(fd, req)
				end
				return
			end
			lprint("MSG", fd, cmd, req)
			local u = fd_cmd_queue[fd]
			if u[1] then
				print("----------pending", cmd)
				req.cmd_ = cmd
				u[#u + 1] = req
			else
				u[1] = true
				local func = msg[cmd]
				if func then
					func(fd, uid, req, cmd)
				end
				while true do
					local req = tremove(u, 2)
					if not req then
						break
					end
					local cmd = req.cmd_
					local func = msg[cmd]
					if func then
						func(fd, uid, req, cmd)
					end
				end
				u[1] = nil
			end
		end,
	}
	lprint("[gate] start", gate_addr, gate_slot)
end


return M

