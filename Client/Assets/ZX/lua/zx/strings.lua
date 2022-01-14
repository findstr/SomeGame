local strnew = CS.ZX.Core.StringNew

local M = setmetatable({
	
}, {__index = function(t, k)
	local id = strnew(k)
	t[k] = id
	return id
end})

return M
