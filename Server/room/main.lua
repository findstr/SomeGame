local core = require "sys.core"
local worker = require "cluster.worker"
local proto = require "proto.cluster"
local E = require "E"
local router = require "router"
local gate = require "agent.gate"
require "room"


local pairs = pairs

core.start(function()
	local listen = assert(core.envget("listen"), "listen")
	local master = assert(core.envget("master_listen", "master_listen"))
	local slot, cap = worker.up {
		type = "room",
		listen = listen,
		master = master,
		proto = proto,
		agents = {
			gate = gate.join,
		}
	}
	gate.restore_online()
	gate.handle("room", E)
	worker.run(router)
	print("[room] run ok")
end)

