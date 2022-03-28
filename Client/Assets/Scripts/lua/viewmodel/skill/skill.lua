local bind = require "binder.skill".skill
local root = GRoot.inst
local M = {}
function M:start(view)
	view:MakeFullScreen()
	root:AddChild(view)
	bind(M, view)
end

function M:stop()

end

return M
