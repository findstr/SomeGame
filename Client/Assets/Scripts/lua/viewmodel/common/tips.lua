local bind = require "binder.common".tips
local root = GRoot.inst
local M = {}
function M:start(view)
	M.view = view
	bind(M, view)
end

function M:show()
	root:AddChild(view)
end

function M:hide()
	root:RemoveChild(view)
end

function M:stop(view)

end

return M