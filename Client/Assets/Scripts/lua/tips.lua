local core = require "zx.core"
local ui = require "zx.ui"
local bind = require "binder.common".tips
local com = ui.new("common.tips")

local M = {}
local pending = 0
local str_queue = {}
local cb_queue = {}

local remove = table.remove

local function play_finish()
	local cb = remove(cb_queue, 1)
	if cb ~= "" then
		core.pcall(cb)
	end
	if #cb_queue == 0 then
		com:hide()
	else
		local str = remove(str_queue, 1)
		com.text.text = str
		com.ctrl:Play(play_finish)
	end
end

function M.show(str, cb)
	cb_queue[#cb_queue + 1] = cb or ""
	if #cb_queue > 1 then
		str_queue[#str_queue + 1] = str
		return 
	end
	pending = pending + 1
	com:show()
	com.text.text = str
	com.ctrl:Play(play_finish)
end

return M
