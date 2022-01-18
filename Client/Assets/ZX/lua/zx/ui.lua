local strings = require "zx.strings"
local M = {}
local ui_stack = {}
local packages = {}
local package_ref = {}
local AddPackage = CS.ZX.Core.AddPackage
local RemovePackage = CS.ZX.Core.RemovePackage
local CreateObject = CS.ZX.Core.CreateObject

local match = string.match
local remove = table.remove
local pairs = pairs

local function ref_pkg(name)
	local pkg = packages[name]
	if pkg then
		package_ref[name] = package_ref[name] + 1
		return pkg
	end
	pkg = AddPackage(strings[name])
	package_ref[name] = 1
	packages[name] = pkg
	return pkg
end

local function unref_pkg(name)
	local n = package_ref[name] or 0
	if n <= 1 then
		local id = packages[name]
		RemovePackage(id)
		package_ref[name] = nil
		packages[name] = nil
		return
	end
	package_ref[name] = n - 1
end

local function close(tag)
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		if ui.name == tag or ui.viewmode == tag then	
			local pkg = match(ui.name, "([^%.]+)")
			unref_pkg(pkg)
			remove(ui_stack, i)
			ui.viewmodel:stop(ui.view)
			ui.view:Dispose()
			ui_stack[i] = nil
			break
		end
	end
end

local function closeall()
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		ui.viewmodel:stop(ui.view)
		ui.view:Dispose()
		ui_stack[i] = nil
	end
	for name, pkg in pairs(packages) do
		packages[name] = nil
		package_ref[name] = nil
		RemovePackage(pkg)
	end
end

local function new(fullname)
	local pkg, name = match(fullname, "([^%.]+).([^%.]+)")
	pkg = ref_pkg(pkg)
	return CreateObject(pkg, strings[name])
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
M.new = new
M.back = back

function M.inplace(fullname, ...)
	local tag = ui_stack[#ui_stack]
	print("inplace", fullname, tag)
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
