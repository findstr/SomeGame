--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.tips(vm, view)
    vm.__view = view
    vm.text = view:GetChildAt(1)
    vm.ctrl = view:GetTransitionAt(0)
    return vm
end
return M