local c = require "zx.socket.c"
local core = require "zx.core"
local zproto = require "zproto"
local M = {}
local mt = {__index = M}
local assert = assert
local type = type
local setmetatable = setmetatable
local send = c.send
local recv = c.recv
local close = c.close
local nodelay = c.nodelay
local pcall = core.pcall
local format = string.format

local function socket_poll(s)
	local fd = s.fd
	for i = 1, 1 do
		local cmd, dat = recv(fd)
		if not cmd then
			if dat then
				print("[zx.socket] close", dat)
				core.lateupdate(s, nil)
				local close = s.__close
				if close then
					local ok, err = pcall(close, dat)
					if not ok then
						print("[zx.socket] socket closed", err)
					end
				end
			end
			return
		end
		local cb = s.router[cmd]
		if not cb then
			print("[zx.socket] unsupport cmd", format("%02x", cmd))
		else
			local proto = s.proto
			local dat, sz = proto:unpack(dat, true)
			local obj = proto:decode(cmd, dat, sz)
			local ok, err = pcall(cb, obj, cmd)
			if not ok then
				print("[zx.socket] socket message:", cmd, err)
			end
		end
	end
end

function M:connect(conf)
	local ip = conf.ip
	local port = conf.port
	local fd, errno = c.connect(ip, port)
	if not fd then
		return nil, errno
	end
	nodelay(fd)
	local proto = conf.proto
	local buf = {}
	for k, v in pairs(conf.router) do
		buf[#buf + 1] = string.format("%s", k)
	end
	local s = setmetatable({
		fd = fd,
		proto = proto,
		router = conf.router,
		__close = conf.close,
	}, mt)
	core.lateupdate(s, socket_poll)
	return s, "ok"
end

function M:close()
	local fd = self.fd
	if not fd then
		return
	end
	print("[zx.socket] close", fd)
	self.fd = nil
	core.lateupdate(self, nil)
	close(fd)
end
local NIL = {}
function M:send(cmd, obj)
	local proto = self.proto
	cmd = proto:tag(cmd)
	local dat, sz = proto:encode(cmd, obj or NIL, true)
	dat= proto:pack(dat, sz)
	send(self.fd, cmd, dat)
end

return M
