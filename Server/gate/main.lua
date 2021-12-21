local core = require "sys.core"
local worker = require "cluster.worker"
local proto = require "proto.cluster"
local gate = require "gate"
local router = require "router"
local rand = math.random
local lprint = core.log
local forward = gate.forward
core.start(function()
	local master = assert(core.envget("master_listen", "master_listen"))
	local listen = assert(core.envget("listen"), "listen")
	local slot = worker.up {
		type = "gate",
		listen = listen,
		master = master,
		proto = proto,
		agents = {
			["room"] = gate.room_join
		},
	}
	worker.run(router, function(tbl, k)
		print("=====")
		tbl[k] = forward
		return forward
	end)
	gate.start(slot)
	core.log("[main] run ok")
end)

