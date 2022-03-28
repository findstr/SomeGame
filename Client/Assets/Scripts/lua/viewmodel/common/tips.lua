local bind = require "binder.common".tips
local root = GRoot.inst
local M = {}
function M:start(view)
	bind(M, view)
end

function M:show()
	root:AddChild(M.__view)
end

function M:hide()
	root:RemoveChild(M.__view)
end

function M:stop()

end

return M