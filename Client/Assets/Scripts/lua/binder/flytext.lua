--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.flytext(vm, view)
    vm.text = view:GetChildAt(0);
    vm.ctrl = view:GetTransitionAt(0);
end
return M