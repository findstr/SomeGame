--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.blue(vm, view)
    vm.__view = view
    vm.name = view:GetChildAt(1)
    vm.level = view:GetChildAt(2)
    vm.hp = view:GetChildAt(3)
    vm.mp = view:GetChildAt(4)
    return vm
end
function M.red(vm, view)
    vm.__view = view
    vm.name = view:GetChildAt(1)
    vm.level = view:GetChildAt(2)
    vm.hp = view:GetChildAt(3)
    vm.mp = view:GetChildAt(4)
    return vm
end
return M