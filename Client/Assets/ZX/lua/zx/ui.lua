local M = {}
local conf = require "zx.conf"
local match = string.match
local remove = table.remove
local ui_stack = {}
local package_ref = {}

local function ref_pkg(pkg)
	local n = package_ref[pkg] or 0
	if n == 0 then
		UIPackage.AddPackage(conf.fgui_path .. pkg)
	end
	package_ref[pkg] = n + 1
end

local function unref_pkg(pkg)
	local n = package_ref[pkg] or 0
	if n <= 1 then
		UIPackage.RemovePackage(conf.fgui_path .. pkg)
		package_ref[pkg] = nil
		return
	end
	package_ref[pkg] = n - 1
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
	for pkg, _ in pairs(package_ref) do
		package_ref[pkg] = nil
		UIPackage.RemovePackage(conf.fgui_path .. pkg)
	end
end

local function new(fullname)
	local pkg, name = match(fullname, "([^%.]+).([^%.]+)")
	ref_pkg(pkg)
	return UIPackage.CreateObject(pkg, name)
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

return M
