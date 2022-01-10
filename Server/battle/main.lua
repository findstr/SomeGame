local core = require "sys.core"
local worker = require "cluster.worker"
local proto = require "proto.cluster"
local router = require "router"
local gate = require "agent.gate"
local room = require "agent.room"
local E = require "E"
local battle = require "battle"

local log = core.log
local pairs = pairs

core.start(function()
	local listen = assert(core.envget("listen"), "listen")
	local master = assert(core.envget("master_listen", "master_listen"))
	local slot, cap = worker.up {
		type = "battle",
		listen = listen,
		master = master,
		proto = proto,
		agents = {
			gate = gate.join,
			room = room.join,
		}
	}
	gate.restore_online()
	gate.handle("battle", E)
	for k, v in pairs(E) do
		router[k] = v
	end
	battle(slot)
	worker.run(router)
	print("[battle] run ok")
end)

