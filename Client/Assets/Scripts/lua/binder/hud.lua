--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.main(vm, view)
    vm.name = view:GetChildAt(1);
    vm.level = view:GetChildAt(2);
    vm.hp = view:GetChildAt(3);
    vm.mp = view:GetChildAt(4);
end
return M