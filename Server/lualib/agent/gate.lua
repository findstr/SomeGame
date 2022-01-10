local core = require "sys.core"
local json = require "sys.json"
local proto = require "proto.client"
local assert = assert
local pairs = pairs
local ipairs = ipairs
local match = string.match
local tonumber = tonumber
local concat = table.concat
local maxinteger = math.maxinteger
local lprint = core.log
local M = {}

local gate_rpc = {}
local uid_slot = {}
local slot_buf = {}
local worker_type
local worker_handler

local TAG = ""

local function gate_join(slotid, rpc)
	gate_rpc[slotid] = rpc
	if not slot_buf[slotid] then
		slot_buf[slotid] = {}
	end
	if worker_type then
		local req = {
			type = worker_type,
			list = worker_handler
		}
		local ack, err = rpc:call("handle_c", req)
		if not ack then
			lprint(TAG, "gate", slotid, "handle fail", err)
		else
			lprint(TAG, "gate", slotid, "handle ok")
		end
	end
	return true
end

function M.join(conns, count)
	if not M.count then
		M.count = count
	else
		assert(M.count == count)
	end
	for i = 1, count do
		local w = conns[i]
		if w then
			gate_join(i, w.rpc)
		end
	end
end

function M.restore_online(filter)
	for i = 1, M.count do
		while not gate_rpc[i] do
			core.sleep(100)
		end
		while true do
			local rpc = gate_rpc[i]
			local ack, err = rpc:call("gateonline_c")
			if ack then
				for _, uid in pairs(ack.uids) do
					if not filter or filter(uid) then
						uid_slot[uid] = i
					end
				end
				break
			else
				lprint(TAG, "restore_online", i, "error", err)
				core.sleep(500)
			end
		end
	end
end

function M.handle(typ, router)
	worker_type = typ
	worker_handler = {}
	TAG = "[agent.gate] " .. typ
	for name, _ in pairs(router) do
		worker_handler[#worker_handler+ 1] = name
	end
	if not M.count then
		return
	end
	local req = {type = worker_type, list = worker_handler}
	for i = 1, M.count do
		repeat
			local rpc = gate_rpc[i]
			if not rpc then
				break
			end
			local ack, err = rpc:call("handle_c", req)
			if not ack then
				lprint(TAG, "gate", i, "handle fail", err)
			else
				lprint(TAG, "gate", i, "handle ok")
				break
			end
			core.sleep(500)
		until ack
	end
end

function M.online(uid, slot)
	assert(slot)
	uid_slot[uid] = slot
end

function M.offline(uid, slot)
	local n = uid_slot[uid]
	assert(not slot or not n or n == slot, slot)
	uid_slot[uid] = nil
end

function M.kick(uid)
	local slot = uid_slot[uid]
	if not slot then
		lprint(TAG, "kick", uid, "offline")
		return true
	end
	local rpc = gate_rpc[slot]
	if not rpc then
		lprint(TAG, "kick", uid, "gate", slot, "offline")
		return false
	end
	local ack, err = rpc:call("gatekick_c", {uid = uid})
	if not ack then
		lprint(TAG, "kick", uid, "gate", slot, "error", err)
		return false
	end
	uid_slot[uid] = nil
	lprint(TAG, "kick", uid, "in gate", slot, "ok")
	return true
end

function M.assign(slot, uid)
	assert(not uid_slot[uid])
	local rpc = gate_rpc[slot]
	if not rpc then
		lprint(TAG, "gate", slot, "not joined")
		return false
	end
	local ack, err = rpc:call("gatetoken_c", {uid = uid})
	uid_slot[uid] = slot
	if not ack then
		lprint(TAG, "assign gate fail", err)
		return false
	end
	lprint("[agent.gate] gatetoken_c uid:", uid, "gate_ip:", ack.token)
	return ack.token, ack.addr
end

function M.send(uid, cmd, obj)
	local slot = uid_slot[uid]
	if not slot then
		return
	end
	local rpc = gate_rpc[slot]
	if not rpc then
		lprint(TAG, "send", uid, cmd, "gate", slot, "missing")
		return
	end
	local dat, sz = proto:encode(cmd, obj, true)
	dat = proto:pack(dat, sz)
	rpc:send("forward_n", {uid = uid, cmd = proto:tag(cmd), dat = dat})
end

local cache = {}

function M.multicast(uids, cmd, obj)
	local dat, sz = proto:encode(cmd, obj, true)
	dat = proto:pack(dat, sz)
	local req = {
		uids = uids,
		cmd = proto:tag(cmd),
		dat = dat
	}
	for _, uid in ipairs(uids) do
		local slot = uid_slot[uid]
		if slot then
			cache[slot] = true
		end
	end
	for slot, _ in pairs(cache) do
		cache[slot] = nil
		local rpc = gate_rpc[slot]
		if rpc then
			rpc:send("multicast_n", req)
		end
	end
end

return M

