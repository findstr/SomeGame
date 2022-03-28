--This is an automatically generated class by FairyGUI. Please do not modify it.

local M = {}
function M.list(vm, view)
    vm.__view = view
    vm.back = view:GetChildAt(2)
    vm.refresh = view:GetChildAt(3)
    vm.create = view:GetChildAt(4)
    vm.room_list = view:GetChildAt(5)
    return vm
end
function M.rinfo(vm, view)
    vm.__view = view
    vm.room_name = view:GetChildAt(1)
    vm.player_count = view:GetChildAt(3)
    vm.room_id = view:GetChildAt(5)
    vm.join_left = view:GetChildAt(6)
    vm.join_right = view:GetChildAt(7)
    return vm
end
function M.room(vm, view)
    vm.__view = view
    vm.room_name = view:GetChildAt(2)
    vm.back = view:GetChildAt(3)
    vm.left_list = view:GetChildAt(4)
    vm.right_list = view:GetChildAt(5)
    vm.begin = view:GetChildAt(6)
    return vm
end
function M.pinfo(vm, view)
    vm.__view = view
    vm.name = view:GetChildAt(1)
    vm.level = view:GetChildAt(3)
    return vm
end
return M