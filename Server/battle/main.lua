local core = require "sys.core"
core.start(function()
	local worker = require "cluster.worker"
	local proto = require "proto.cluster"
	local agent_gate = require "agent.gate"
	local agent_room = require "agent.room"
	local room = require "room"
	local player = require "player"
	local E = require "E"
	local router = require "router"

	local log = core.log
	local pairs = pairs

	local listen = assert(core.envget("listen"), "listen")
	local master = assert(core.envget("master_listen", "master_listen"))
	local slot, cap = worker.up {
		type = "battle",
		listen = listen,
		master = master,
		proto = proto,
		agents = {
			gate = agent_gate.join,
			room = agent_room.join,
		}
	}
	agent_gate.restore_online()
	agent_gate.handle("battle", E)
	for k, v in pairs(E) do
		router[k] = v
	end
	room.start(slot)
	worker.run(router)
	print("[battle] run ok")
end)

