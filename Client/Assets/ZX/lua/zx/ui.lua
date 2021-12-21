local M = {}
local conf = require "zx.conf"
local match = string.match
local remove = table.remove
local ui_stack = {}

function M.open(fullname, ...)
	local pkg, name = match(fullname, "([^%.]+).([^%.]+)")
	UIPackage.AddPackage(conf.fgui_path .. pkg)
	local view = UIPackage.CreateObject(pkg, name)
	local vm = require ("viewmodel." .. name)
	local vm = vm:start(view, ...)
	ui_stack[#ui_stack + 1] = {
		name = fullname,
		view = view,
		viewmodel = vm,
	}
	return vm
end

function M.close(fullname)
	for i = #ui_stack, 1, -1 do
		local ui = ui_stack[i]
		if ui.name == fullname or ui.viewmode == fullname then
			remove(ui_stack, i)
			ui_stack[i].viewmodel:stop()
			break
		end
	end

end

return M
