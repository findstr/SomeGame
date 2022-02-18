local bind = require "binder.skill".skill
local root = GRoot.inst
local M = {}
function M:start(view)	
	M.view = view
	view:MakeFullScreen()
	bind(M, view)
end

function M:stop(view)
end

return M