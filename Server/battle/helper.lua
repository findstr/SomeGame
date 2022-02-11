local M = {}
local sqrt = math.sqrt

function M.dist2(x1, y1, x2, y2)
	local x = x1 - x2
	local y = y1 - y2
	return x*x + y*y
end

function M.dist(x1, y1, x2, y2)
	local x = x1 - x2
	local y = y1 - y2
	return sqrt(x*x + y*y)
end

return M


