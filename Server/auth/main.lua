local core = require "sys.core"
local worker = require "cluster.worker"
local proto = require "proto.cluster"
local router = require "router"
local auth_start = require "auth"
local gate = require "agent.gate"

core.start(function()
	local master = assert(core.envget("master_listen", "master_listen"))
	local listen = assert(core.envget("listen"), "listen")
	worker.up {
		type = "auth",
		listen = listen,
		master = master,
		proto = proto,
		agents = {
			["gate"] = gate.join,
		}
	}
	gate.restore_online()
	worker.run(router)
	core.log("[main] run ok")
	auth_start()
end)

