local bind = require "binder.hud".blue
local M = {}
function M:start(view)
	bind(M, view)
end

function M:stop(view)
end

return M