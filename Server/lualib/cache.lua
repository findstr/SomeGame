local setmetatable = setmetatable
local mt = {__mode = "kv"}
local function cache()
	return setmetatable({}, mt)
end

return cache
