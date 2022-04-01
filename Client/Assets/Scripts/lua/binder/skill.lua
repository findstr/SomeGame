--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.Button1(vm, view)
    vm.__view = view
    vm.sprite = view:GetChildAt(0)
    vm.name = view:GetChildAt(1)
    return vm
end
function M.Button2(vm, view)
    vm.__view = view
    vm.sprite = view:GetChildAt(0)
    vm.name = view:GetChildAt(1)
    vm.cdmask = view:GetChildAt(2)
    vm.cdtime = view:GetChildAt(3)
    return vm
end
function M.Button3(vm, view)
    vm.__view = view
    vm.sprite = view:GetChildAt(0)
    vm.name = view:GetChildAt(1)
    vm.cdmask = view:GetChildAt(2)
    vm.cdtime = view:GetChildAt(3)
    vm.t0 = view:GetTransitionAt(0)
    return vm
end
function M.skill(vm, view)
    vm.__view = view
    vm.s1 = M.Button1({}, view:GetChildAt(0))
    vm.s2 = M.Button2({}, view:GetChildAt(1))
    vm.s3 = M.Button2({}, view:GetChildAt(2))
    vm.s4 = M.Button2({}, view:GetChildAt(3))
    vm.s5 = M.Button3({}, view:GetChildAt(4))
    vm.s6 = M.Button3({}, view:GetChildAt(5))
    return vm
end
return M