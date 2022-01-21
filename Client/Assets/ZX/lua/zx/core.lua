local M = {}
local weakmt = {__mode = "kv"}
local type = type
local tostring = tostring
local tremove = table.remove
local traceback = debug.traceback

local function errmsg(msg)
	return traceback("error: " .. tostring(msg), 2)
end

local function core_pcall(f, ...)
	return xpcall(f, errmsg, ...)
end

M.pcall = core_pcall
-------------timer

-------------coroutines
local task_status = setmetatable({}, weakmt)
local task_running = nil
local cocreate = coroutine.create
local corunning = coroutine.running
local coyield = coroutine.yield
local coresume = coroutine.resume
local coclose = coroutine.close
local task_yield = coyield
local function task_resume(t, ...)
	local save = task_running
	task_status[t] = "RUN"
	task_running = t
	local ok, err = coresume(t, ...)
	task_running = save
	if not ok then
		task_status[t] = nil
		local ret = traceback(t, tostring(err), 1)
		print("[sys.core] task resume", ret)
		local ok, err = coclose(t)
		if not ok then
			print("[sys.core] task close", err)
		end
	else
		task_status[t] = err
	end
end

--coroutine pool will be dynamic size
--so use the weaktable
local copool = {}
setmetatable(copool, weakmt)

local function task_create(f)
	local co = tremove(copool)
	if co then
		coresume(co, "STARTUP", f)
		return co
	end
	co = cocreate(function(...)
		f(...)
		while true do
			local ret
			f = nil
			copool[#copool + 1] = corunning()
			ret, f = coyield("EXIT")
			if ret ~= "STARTUP" then
				core_log("[sys.core] task create", ret)
				core_log(traceback())
				return
			end
			f(coyield())
		end
	end)
	return co
end

local wakeup_task_queue = {}
local wakeup_task_param = {}
local sleep_session_task = {}

local function dispatch_wakeup()
	while true do
		local co = tremove(wakeup_task_queue, 1)
		if not co then
			return
		end
		local param = wakeup_task_param[co]
		wakeup_task_param[co] = nil
		task_resume(co, param)
	end
end

function M.fork(func)
	local t = task_create(func)
	task_status[t] = "READY"
	wakeup_task_queue[#wakeup_task_queue + 1] = t
	return t
end

function M.wait()
	local t = task_running
	local status = task_status[t]
	assert(status == "RUN", status)
	return task_yield("WAIT")
end

function M.wakeup(t, res)
	local status = task_status[t]
	assert(status == "WAIT", status)
	task_status[t] = "READY"
	wakeup_task_param[t] = res
	wakeup_task_queue[#wakeup_task_queue + 1] = t
end

local timeout = CS.ZX.Timer.timeout

function M.sleep(ms)
	local t = task_running
	local status = task_status[t]
	assert(status == "RUN", status)
	local session = timeout(ms)
	sleep_session_task[session] = t
	task_yield("SLEEP")
end

function M.timeout(ms, func)
	local session = timeout(ms)
	sleep_session_task[session] = func
	return session
end

function M._timerexpire(list)
	for k, session in pairs(list) do
		list[k] = nil
		local t = sleep_session_task[session]
		sleep_session_task[session] = nil
		if type(t) == "function" then
			t = task_create(t)
		end
		task_resume(t, session)
	end
end

-------------update 

local fixed_queue = {}
local update_queue = {}
local late_queue = {}
local logic_queue = {}

local fixed_queue_ = setmetatable({}, weakmt)
local update_queue_ = setmetatable({}, weakmt)
local late_queue_ = setmetatable({}, weakmt)
local logic_queue_ = setmetatable({}, weakmt)


function M.fixedupdate(k, func)
	if func then
		fixed_queue[k] = func
	else
		fixed_queue_[k] = nil
	end
end

function M.update(k, func)
	if func then
		update_queue[k] = func
	else
		update_queue_[k] = func
	end
end

function M.lateupdate(k, func)
	if func then
		late_queue[k] = func
	else
		late_queue_[k] = func
	end
end

function M.logicupdate(k, func)
	if func then
		logic_queue[k] = func
	else
		logic_queue_[k] = func
	end
end

local function update_wrap(list, candidate)
	return function()
		local pcall = core_pcall
		for t, func in pairs(candidate) do
			candidate[t] = nil
			list[t] = func
		end
		for t, func in pairs(list) do
			local ok, err = pcall(func, t)
			if not ok then
				print("xx:", err)
			end
		end
	end
end

M._fixedupdate = update_wrap(fixed_queue_, fixed_queue)
M._update = update_wrap(update_queue_, update_queue)
M._lateupdate = update_wrap(late_queue_, late_queue)

M._logicupdate = function(delta)
	local pcall = core_pcall
	for t, func in pairs(logic_queue_) do
		logic_queue_[t] = nil
		logic_queue[t] = func
	end
	for t, func in pairs(logic_queue) do
		local ok, err = pcall(func, t, delta)
		if not ok then
			print("xx:", err)
		end
	end
	dispatch_wakeup()
end


return M
