local strings = require "zx.strings"
local M = {}
local ui_stack = {}
local CreateObject = CS.ZX.Core.CreateObject
local RemoveObject = CS.ZX.Core.RemoveObject

local match = string.match
local remove = table.remove
local pairs = pairs

local function new(fullname)
	local pkg, name = match(fullname, "([^%.]+).([^%.]+)")
	return CreateObject(strings[pkg], strings[name])
end

local function close(tag)
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		if ui.name == tag or ui.viewmode == tag then	
			remove(ui_stack, i)
			ui.viewmodel:stop(ui.view)
			RemoveObject(ui.view)
			ui_stack[i] = nil
			break
		end
	end
end

local function closeall()
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		ui.viewmodel:stop(ui.view)
		RemoveObject(ui.view)
		ui_stack[i] = nil
	end
end

local function open(fullname, ...)
	local view = new(fullname)
	local vm = require ("viewmodel." .. fullname)
	local vm = vm:start(view, ...) or vm
	ui_stack[#ui_stack + 1] = {
		view = view,
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

return M
