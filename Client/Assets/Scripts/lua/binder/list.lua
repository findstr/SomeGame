--This is an automatically generated class by FairyGUI. Please do not modify it.

local function binder(vm, view)
    vm.back = view:GetChildAt(1);
    vm.refresh = view:GetChildAt(2);
    vm.create = view:GetChildAt(3);
    vm.room_list = view:GetChildAt(4);
end
return binder