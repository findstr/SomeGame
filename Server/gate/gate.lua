local core = require "sys.core"
local json = require "sys.json"
local router = require "router"
local errno = require "errno.auth"
local battle_errno = require "errno.battle"
local msgserver = require "cluster.msg"
local proto = require "proto.client"

local pcall = core.pcall
local assert = assert
local pairs = pairs
local ipairs = ipairs
local type = type
local next = next
local rawget = rawget
local rand = math.random
local tremove = table.remove
local lprint = core.log
local room_rpc = nil
local battle_rpc = {}
local battle_count = 1
local battle_roundrobin = 0

local gate_slot
local gate_server
local fd_to_uid = {}
local fd_cmd_queue = setmetatable({}, {__index = function(t, k)
	local v = {}
	t[k] = v
	return v
end})

local msg = {}
local uid_info = {}
local gate_addr = assert(core.envget("gate_addr"))

local function clear_fd(fd)
	fd_cmd_queue[fd] = nil
	fd_to_uid[fd] = nil
end

function router.gatetoken_c(req)
	local uid = req.uid
	local tk = rand(1, 65535)
	local u = uid_info[uid]
	if not u then
		u = {
			fd = nil,
			token = nil,
			battle = nil,
		}
		uid_info[uid] = u
	else
		local fd = u.fd
		if fd then
			u.fd = nil
			clear_fd(fd)
			gate_server:send(fd, "kick_n", {errno = errno.NEWLOGIN})
		end
		u.battle = nil
	end
	u.token = tk
	lprint("[gate] gatetoken_c uid:", uid, "token", tk)
	return "gatetoken_a", {token = tk, addr = gate_addr}
end

function router.gatekick_c(req)
	local uid = req.uid
	local u = uid_info[uid]
	if u then
		local fd = u.fd
		if fd then
			clear_fd(fd)
			gate_server:send(fd, "kick_n", {errno = errno.NEWLOGIN})
		end
	end
	lprint("[gate] gatekick_c:",uid)
	return "gatekick_a", nil
end

function router.gateonline_c(req)
	local l, i = {}, 0
	for uid, _ in pairs(uid_info) do
		i = i + 1
		l[i] = uid
	end
	return "gateonline_a", {uids = l}
end

local function error_a(fd, cmd, errno)
	gate_server:send(fd, "error_a", {
		cmd = proto:tag(cmd),
		errno = errno
	})
end

local function login_r(fd, req)
	local uid = req.uid
	local u = uid_info[uid]
	local token = u and u.token
	if not token or token ~= req.token then
		error_a(fd, "login_a", errno.TOKEN)
		lprint("[gate] login_r", fd, uid,
			"token invalid", req.token, token)
		return
	end
	u.token = token + 1
	u.fd = fd
	local ack, err = room_rpc:call("whichbattle_c", req)
	if not ack then
		error_a(fd, "login_a", errno.SYSTEM)
		lprint("[gate] login_r", fd, uid, "whichbattle_c error:", err)
		return
	end
	local battle = ack.battle
	u.battle = battle
	fd_to_uid[fd] = uid
	gate_server:send(fd, "login_a", req)
	lprint("[gate] login_r", fd, uid, "battle", battle, "ok")
end

------------------------------------------------ROOM

local function forward_room(cmdr, cmda)
	return function(fd, uid, req, cmdx)
		req.uid = uid
		req.gate = gate_slot
		print("forward_room fd", fd, "uid", uid)
		local ack, cmd = room_rpc:call(cmdr, req)
		if not ack then
			lprint("[gate] cmd:", cmdr, "fail", cmd)
			return
		end
		print("-------ack room", json.encode(ack), cmd)
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
end

local function forward_battle(cmdr)
	return function(fd, uid, req, cmdx)
		req.uid = uid
		req.gate = gate_slot
		print("forward_room fd", fd, "uid", uid)
		local ack, cmd = battle_rpc[uid_info[uid].battle]:call(cmdr, req)
		if not ack then
			lprint("[gate] cmd:", cmdr, "fail", cmd)
			return
		end
		print("-------ack room", json.encode(ack), cmd)
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

end

msg.roomlist_r = function(fd, uid, req, cmdx)
	local u = uid_info[uid]
	local battle = u.battle
	if battle then
		req.uid = uid
		local ack, cmd = battle_rpc[battle]:call("battlerestore_c", req)
		if not ack then
			lprint("[gate] cmd:", cmdx, "fail", cmd)
			return
		end
		gate_server:send(fd, cmd, ack)
	else
		lprint("[gate] roomlist_r uid:", uid, "in", battle)
		local ack, cmd = room_rpc:call(cmdx)
		if not ack then
			lprint("[gate] cmd:", cmdx, "fail", cmd)
			return
		end
		gate_server:send(fd, "roomlist_a", ack)
	end
end

msg.battlecreate_r = function(fd, uid, req, cmdx)
	local u = uid_info[uid]
	if u.battle then
		lprint("[gate] battlecreate uid:", uid, "already in", u.battle)
		gate_server:send(fd, "error_a", {
			cmd = cmdx+1,
			errno = battle_errno.INROOM
		})
		return
	end
	req.uid = uid
	req.gate = gate_slot
	local battle = battle_roundrobin % battle_count + 1
	battle_roundrobin = battle
	u.battle = battle
	local ack, cmd = battle_rpc[battle]:call("battlecreate_c", req)
	if not ack then
		lprint("[gate] battlecreate_c fail", cmd)
		return
	end
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

msg.battleenter_r = function(fd, uid, req, cmdx)
	local u = uid_info[uid]
	if u.battle then
		lprint("[gate] enter uid:", uid, "already in", u.battle)
		gate_server:send(fd, "error_a", {
			cmd = cmdx+1,
			errno = battle_errno.INROOM
		})
		return
	end
	local battle = req.battle
	req.uid = uid
	req.gate = gate_slot
	req.side = req.side
	u.battle = battle
	local ack, cmd = battle_rpc[battle]:call("battleenter_c", req)
	if not ack then
		u.battle = nil
		lprint("[gate] battleenter_c fail", cmd)
		return
	end
	local errno = ack.errno
	if errno then
		u.battle = nil
		gate_server:send(fd, "error_a", {
			cmd = cmdx+1,
			errno = errno
		})
	else
		print("battleenter", fd, cmd, ack)
		gate_server:send(fd, cmd, ack)
	end
end

msg.battleleave_r = function(fd, uid, req, cmdx)
	local u = uid_info[uid]
	local battle = u.battle
	if not battle then
		gate_server:send(fd, "error_a", {
			cmd = cmdx+1,
			errno = battle_errno.OUTROOM
		})
		return
	end
	req.uid_ = uid
	local ack, cmd = battle_rpc[battle]:call(cmdx, req)
	if not ack then
		lprint("[gate] battleleave_r fail", cmd)
		return
	end
	local errno = ack.errno
	if errno then
		gate_server:send(fd, "error_a", {
			cmd = cmdx+1,
			errno = errno
		})
	else
		u.battle = nil
		print("battleleave", fd, cmd, ack)
		gate_server:send(fd, cmd, ack)
	end
end



msg.battlemove_r = function(fd, uid, req, cmdx)
	req.uid_ = uid
	local u = uid_info[uid]
	local battle = u.battle
	print("battlemove_r")
	if battle then
		battle_rpc[battle]:send(cmdx, req)
	end
end
print("msg.battlemove_r", msg.battlemove_r)
msg.battleskill_r = msg.battlemove_r


---------------------------------------------------

do
	local tbl = {}
	for k, v in pairs(msg) do
		tbl[assert(proto:tag(k), k)] = v
	end
	msg = tbl
end

local forward = {
	["room"] = function(fd, uid, req, cmdx)
		req.uid_ = uid
		print("------req room", fd, uid, req, cmdx)
		local ack, cmd = room_rpc:call(cmdx, req)
		if not ack then
			lprint("[gate] cmd:", cmdx, "fail", cmd)
			return
		end
		print("-------ack room", json.encode(ack), cmd)
		local errno = ack.errno
		if errno then
			gate_server:send(fd, "error_a", {
				cmd = cmdx+1,
				errno = errno
			})
		else
			gate_server:send(fd, cmd, ack)
		end
	end,
	["battle"] = function(fd, uid, req, cmdx)
		req.uid_ = uid
		local u = uid_info[uid]
		local battle = u.battle
		if not battle then
			return
		end
		print("------req battle", fd, uid, req, cmdx)
		local ack, cmd = battle_rpc[battle]:call(cmdx, req)
		if not ack then
			lprint("[gate] cmd:", cmdx, "fail", cmd)
			return
		end
		print("-------ack battle", json.encode(ack), cmd)
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

function router.forward_n(req)
	local uid = req.uid
	local u = uid_info[uid]
	local fd = u and u.fd
	if not fd then
		lprint("[gate] forward", uid, "cmd", cmd, "offline")
		return
	end
	local cmd, bin = req.cmd, req.dat
	gate_server:sendbin(fd, cmd, bin)
end

function router.multicast_n(req)
	local uids = req.uids
	local cmd, bin = req.cmd, req.dat
	for _, uid in pairs(uids) do
		local u = uid_info[uid]
		local fd = u and u.fd
		if fd then
			gate_server:sendbin(fd, cmd, bin)
		else
			lprint("[gate] forward", uid, "cmd", cmd, "offline")
		end
	end
end

----------------------------------------------------

local M = {}

local cmd_login_r = proto:tag("login_r")

function M.room_join(workers, count)
	print("room_join", workers[1], count)
	if workers[1] then
		room_rpc = workers[1].rpc
	end
end

function M.battle_join(workers, count)
	battle_count = count
	for i = 1, count do
		local w = workers[i]
		if w then
			print("battle_join", i, w.rpc)
			battle_rpc[i] = w.rpc
		end
	end
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
				clear_fd(fd)
				uid_info[uid].fd = nil
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
			local u = fd_cmd_queue[fd]
			print("MSG", fd, cmd, json.encode(req), u[1], msg[cmd])
			if u[1] then
				print("----------pending", cmd)
				req.cmd_ = cmd
				u[#u + 1] = req
			else
				u[1] = true
				local func = msg[cmd]
				if func then
					local ok, err = pcall(func, fd, uid, req, cmd)
					if not ok then
						lprint("[MSG] cmd:", cmd, err)
					end
				end
				while true do
					local req = tremove(u, 2)
					if not req then
						break
					end
					local cmd = req.cmd_
					local func = msg[cmd]
					if func then
						local ok, err = func(fd, uid, req, cmd)
						if not ok then
							lprint("[MSG] cmd:", cmd, err)
						end
					end
				end
				u[1] = nil
			end
		end,
	}
	lprint("[gate] start", gate_addr, gate_slot)
end


return M

