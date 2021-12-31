--This is an automatically generated class by FairyGUI. Please do not modify it.

local function binder(vm, view)
    vm.room_name = view:GetChildAt(1);
    vm.player_count = view:GetChildAt(3);
    vm.room_id = view:GetChildAt(5);
end
return binder