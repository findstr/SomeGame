local core = require "sys.core"
local json = require "sys.json"
local crypto = require "sys.crypto"
local router = require "router"
local zproto = require "zproto"
local msgserver = require "cluster.msg"
local auth_proto = require "proto.client"
local errno = require "errno.auth"
local gate = require "agent.gate"
local format = string.format
local tonumber = tonumber
local log = core.log
local auth_addr = assert(core.envget("auth_addr"))
local gate_balance_slotid

local db
local auth_server

local serverid = 1
local round_robin = 0
local takeover = {[1] = true}
local uid_begin = 100000
local uid_end = 999999

local dbk_uidx = setmetatable({}, {__index = function(t, k)
	local v = format("account:%d:idx", k)
	t[k] = v
	return v
end})

local dbk_nameuid = setmetatable({}, {__index = function(t, k)
	local v = format("account:%d:nameuid", k)
	t[k] = v
	return v
end})

local dbk_pwd = "account:passwd"

local function error_a(fd, cmd, errno)
	cmd = auth_proto:tag(cmd)
	auth_server:send(fd, "error_a", {
		cmd = cmd,
		errno = errno
	})
end

local function auth_r(fd, cmd, req)
	local usr = req.account
	local pwd = req.passwd
	local sid = req.server
	if not usr or #usr == 0 or not pwd or #pwd == 0 or not sid or not takeover[sid] then
		log("[auth] auth_r invalid param", usr, pwd, sid)
		error_a(fd, "auth_a", errno.PARAM)
		return
	end
	local ok, pwd_check = db:hget(dbk_pwd, usr)
	if not ok then
		log("[auth] auth_r get pwd error", dbk_pwd, usr, pwd_check)
		error_a(fd, "auth_a", errno.SYSTEM)
		return
	end
	local uid
	local md5 = crypto.md5(pwd)
	if not pwd_check then
		local ok, n = db:hsetnx(dbk_pwd, usr, md5)
		if not ok or n == 0 then
			log("[auth] auth_r create user exist", usr)
			error_a(fd, "auth_a", errno.EXIST)
			return
		end
		local dbk = dbk_uidx[sid]
		local ok, idx = db:incr(dbk)
		if not ok then
			log("[auth] auth_r uidx error", dbk, usr, idx)
			error_a(fd, "auth_a", errno.SYSTEM)
			return
		end
		idx = tonumber(idx)
		if idx < uid_begin then
			idx = uid_begin + idx
			db:set(dbk, idx)
		elseif idx > uid_end then
			log("[auth] auth_r server full", usr, dbk, idx)
			error_a(fd, "auth_a", errno.FULL)
			return
		end
		db:hset(dbk_nameuid[sid], usr, idx)
		uid = idx
	elseif pwd_check == md5 then
		local dbk = dbk_nameuid[sid]
		local ok, id = db:hget(dbk, usr)
		if not ok then
			log("[auth] auth_r getuid error", dbk, usr, id)
			error_a(fd, "auth_a", errno.SYSTEM)
			return
		end
		uid = tonumber(id)
	else
		log("[auth] auth_r password error", usr)
		error_a(fd, "auth_a", errno.PASSWD)
		return
	end
	local ok = gate.kick(uid)
	if not ok then
		log("[auth] auth_r kick", uid, "fail")
		error_a(fd, "auth_a", errno.SYSTEM)
	end
	local slot = round_robin % gate.count + 1
	round_robin = slot
	local token, addr = gate.assign(slot, uid)
	if not token then
		log("[auth] auth_r assign gate", slot, "fail", addr)
		error_a(fd, "auth_a", errno.SYSTEM)
		return
	end
	log("[auth] auth_r assign uid", uid, "gate", slot, "token", token, addr)
	return auth_server:send(fd, "auth_a", {
		uid = uid,
		token = token,
		gate = addr
	})
end

local function start()
	local redis = require "sys.db.redis"
	local addr = assert(core.envget("redis_addr"), "redis_addr")
	local dbid = assert(core.envget("redis_db"), "redis_db")
	local err
	db, err= redis:connect{
		addr = addr, "127.0.0.1:6379",
		db = dbid,
	}
	auth_server = msgserver.listen {
		proto = auth_proto,
		addr = auth_addr,
		accept = function(fd, addr)
			core.log("[auth] auth_server accept", fd, addr)
		end,
		close = function(fd, errno)
			core.log("[auth] auth_server close", fd, errno)
		end,
		data = auth_r
	}
	core.log("[auth] start redis", addr, db,"auth_server", auth_addr)
end

return start


