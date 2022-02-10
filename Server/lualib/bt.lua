local M = {}
local mem_path = {}
local function tick(tree, actions, obj, delta)
	local res
	local running_id
	local ctx = self
	repeat
		local n
		if tree.mem then
			n = ctx[tree]
			if not n then
				n = tree.children[1]
			end
			mem_path[#mem_path + 1] = tree
		else
			local func = actions[tree.name]
			if tree.type == "decorator" then
				res = func(obj, tree.properties, res)
			else
				res = func(obj, tree.properties, delta)
			end
			print("exec", tree.name, res)
			if res == nil then
				running_id = tree.id
				break
			end
			if res then
				n = tree.success
			else
				n = tree.failure
			end
		end
		tree = n
	until not tree
	if res ~= nil then
		for i = 1, #mem_path do
			ctx[mem_path[i]] = false --prevent rehash
			mem_path[i] = nil
		end
	else
		for i = 1, #mem_path do
			local nxt
			local node = mem_path[i]
			local children = node.children
			local n = #children
			if running_id <= children[n] then
				local mid = n // 2
				for i = mid+1, n do
					if running_id <= children[i] then
						nxt = children[i-mid]
						break
					end
				end
				ctx[node] = nxt
			end
			mem_path[i] = nil
		end
	end
	return res
end

return tick

