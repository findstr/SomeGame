local core = require "sys.core"
local worker = require "cluster.worker"
local proto = require "proto.cluster"
local E = require "E"
local router = require "router"
local gate = require "agent.gate"
local battle = require "agent.battle"
local start = require "room"

local log = core.log
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
			battle = battle.join,
		}
	}
	gate.restore_online()
	start()
	gate.handle("room", E)
	for k, v in pairs(E) do
		router[k] = v
	end
	worker.run(router)
	print("[room] run ok")
end)

