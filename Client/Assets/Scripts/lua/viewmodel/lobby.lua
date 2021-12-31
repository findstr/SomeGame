local bind = require "binder.lobby"

local M = {}

function M:start(view)
	view:MakeFullScreen()
	GRoot.inst:AddChild(view)	
	bind(self)
	
	
	return M
end

return M
