local socket = require "zx.socket"
local json = require "zx.json"
local router = require "router"
local core = require "zx.core"
local proto = require "proto"
local ui = require "zx.ui"

--[[
function router.auth_a(req, cmd)
	print("auth_a")
end

local function socket_close(errno)
    print("socket close", errno)
end

local sock, err = socket:connect {
    ip = "192.168.2.118",
    port = 7000, 
    proto = proto, 
    router = router,
    close = socket_close
}
assert(sock)
sock:send("auth_r", {
        account = "findstr",
        passwd = "123456",
        server = 1
})

]]

ui.open "login.login"

print("hello")
