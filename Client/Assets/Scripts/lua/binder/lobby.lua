--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.lobby(vm, view)
    vm.__view = view
    vm.shop = view:GetChildAt(2)
    vm.social = view:GetChildAt(3)
    vm.prebattle = view:GetChildAt(4)
    vm.hero = view:GetChildAt(5)
    vm.achievement = view:GetChildAt(6)
    vm.bag = view:GetChildAt(7)
    vm.team = view:GetChildAt(8)
    vm.watch = view:GetChildAt(9)
    vm.Bottom = view:GetChildAt(10)
    vm.normalpvp = view:GetChildAt(14)
    vm.normal = view:GetChildAt(15)
    vm.roompvp = view:GetChildAt(19)
    vm.pve = view:GetChildAt(20)
    vm.hellpvp = view:GetChildAt(24)
    vm.hell = view:GetChildAt(25)
    return vm
end
return M