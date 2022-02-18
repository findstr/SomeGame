local bind = require "binder.hud".red
local M = {}
function M:start(view)
	bind(M, view)
end

function M:stop(view)
end

return M