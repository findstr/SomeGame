local cl = require "Tools.client_files"
local dl = require "Tools.cluster_files"
local buf = {}
local open = io.open
local prefix= "Protocol/client/"

local function extend(strc)
	for l in string.gmatch(strc, "([^\n]+)\n") do
		if l:find("{%s*$") then
			buf[#buf + 1] = l
		elseif l:find("^}") then
			buf[#buf + 1] = "\t.uid_:uinteger " .. (tag + 1)
			buf[#buf + 1] = l
			tag = 0
		else
			if l:find("^%s*%.") then
				tag = tonumber(l:match("%s+(%d+)%s*"))
			end
			buf[#buf + 1] = l
		end
	end
end

buf[#buf +1] = "local M = [["
for _, name in ipairs(cl) do
	local p = prefix .. name
	local f = io.open(p, "r")
	extend(f:read("a"))
	f:close()
end
buf[#buf + 1] = "#----------cluster protocol----------\n"
local prefix= "Protocol/cluster/"
for _, name in ipairs(dl) do
	local p = prefix .. name
	local f = io.open(p, "r")
	buf[#buf + 1] = f:read("a")
	f:close()
end
buf[#buf + 1] = "]]\nreturn M\n"
print(table.concat(buf, "\n"))


