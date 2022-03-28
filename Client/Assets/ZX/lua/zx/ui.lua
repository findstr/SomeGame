local strings = require "zx.strings"
local M = {}
local ui_stack = {}
local CreateObject = CS.ZX.Core.CreateObject
local RemoveObject = CS.ZX.Core.RemoveObject

local match = string.match
local remove = table.remove
local pairs = pairs

local function new(fullname, ...)
	local pkg, name = match(fullname, "([^%.]+).([^%.]+)")
	local view = CreateObject(strings[pkg], strings[name])
	local vm = require ("viewmodel." .. fullname)
	return (vm:start(view, ...) or vm)
end

local function close(tag)
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		if ui.name == tag or ui.viewmodel == tag then	
			local vm = ui.viewmodel
			remove(ui_stack, i)
			vm:stop()
			RemoveObject(vm.__view)
			ui_stack[i] = nil
			break
		end
	end
end

local function closeall()
	for i = #ui_stack, 1, -1 do
		local vm = ui_stack[i].viewmodel
		vm:stop()
		RemoveObject(vm.__view)
		ui_stack[i] = nil
	end
end

local function open(fullname, ...)
	local vm = new(fullname, ...)
	ui_stack[#ui_stack + 1] = {
		name = fullname,
		viewmodel = vm,
	}
	return vm
end


local function back()
	local tag = ui_stack[#ui_stack]
	if tag then
		close(tag.name)
	end
end

M.close = close
M.open = open
M.back = back
M.new = new
M.del = RemoveObject

function M.inplace(fullname, ...)
	local tag = ui_stack[#ui_stack]
	if tag then
		close(tag.name)
	end
	return open(fullname, ...)
end

function M.singletop(fullname, ...)
	local tag = ui_stack[#ui_stack] 
	if tag and tag.name == fullname then
		close(fullname)
	end
	return open(fullname, ...)
end

function M.single(fullname, ...)
	close(fullname)
	return open(fullname, ...)
end

M.clear = closeall

function M.lan(lan)
	ZX_LAN = lan
end

M.assetdir = CS.ZX.Core.SetPathPrefix
M.screenposition = CS.ZX.Core.ScreenPosition

return M
