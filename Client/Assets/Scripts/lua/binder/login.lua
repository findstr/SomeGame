--This is an automatically generated class by FairyGUI. Please do not modify it.

local function binder(vm, view)
    vm.c1 = view:GetControllerAt(0);
    vm.login_tips = view:GetChildAt(5);
    vm.account_input = view:GetChildAt(6);
    vm.password_input = view:GetChildAt(7);
    vm.login_button = view:GetChildAt(8);
    vm.register_button = view:GetChildAt(9);
    vm.t0 = view:GetTransitionAt(0);
end
return binder