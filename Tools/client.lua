local l = require "Tools.client_files"
local buf = {'local zproto = require "zproto"'}
local open = io.open
local prefix= "Protocol/client/"
buf[#buf +1] = "local M = zproto:parse [["
for _, name in ipairs(l) do
	local p = prefix .. name
	local f = io.open(p, "r")
	buf[#buf + 1] = f:read("a")
	f:close()
end
buf[#buf + 1] = "]]\nreturn M\n"
print(table.concat(buf, "\n"))

