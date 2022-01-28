local bind = require "binder.balance".balance
local router = require "router"
local ui = require "zx.ui"

local M = {}

function M:start(view, winner)
	GRoot.inst:AddChild(view)	
	bind(M, view)
	M.title.text = winner
	return 
end

function M:stop()
	
end

return M
