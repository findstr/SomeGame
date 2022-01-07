local core = require "sys.core"
local master = require "cluster.master"


core.start(function()
	local addr = assert(core.envget("master_listen"), "master_listen")
	local capacity = {
		['auth'] = 1,
		['gate'] = 1,
		['room'] = 1,
		['battle'] = 1,
	}
	for k, v in pairs(capacity) do
		if v == false then
			v = assert(core.envget("capacity."..k), k)
		end
		capacity[k] = v
	end
	local ok, err = master.start {
		listen = addr,
		monitor = ":8080",
		console = "127.0.0.1:8081",
		capacity = capacity
	}
	core.log("[main] start success")
end)

