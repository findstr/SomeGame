local M = {}
local weakmt = {__mode = "kv"}
local tostring = tostring
local traceback = debug.traceback
local fixed_queue = setmetatable({}, weakmt)
local update_queue = setmetatable({}, weakmt)
local late_queue = setmetatable({}, weakmt)

local function errmsg(msg)
	return traceback("error: " .. tostring(msg), 2)
end

local function core_pcall(f, ...)
	return xpcall(f, errmsg, ...)
end

function M.fixedupdate(k, func)
	fixed_queue[k] = func
end

function M.update(k, func)
	update_queue[k] = func
end

function M.lateupdate(k, func)
	late_queue[k] = func
end

local function update_wrap(list)
	return function()
		local pcall = core_pcall
		for t, func in pairs(list) do
			local ok, err = pcall(func, t)
			if not ok then
				print("xx:", err)
			end
		end
	end
end

M.pcall = core_pcall
M._fixedupdate = update_wrap(fixed_queue)
M._update = update_wrap(update_queue)
M._lateupdate = update_wrap(late_queue)

return M
