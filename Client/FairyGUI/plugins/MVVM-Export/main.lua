--FYI: https://github.com/Tencent/xLua/blob/master/Assets/XLua/Doc/XLua_Tutorial_EN.md

local function genCode(handler)
    local settings = handler.project:GetSettings("Publish").codeGeneration
    local codePkgName = handler:ToFilename(handler.pkg.name); --convert chinese to pinyin, remove special chars etc.
    local exportCodePath = handler.exportCodePath
    local namespaceName = codePkgName
    
    if settings.packageName~=nil and settings.packageName~='' then
        namespaceName = settings.packageName..'.'..namespaceName;
    end

    --CollectClasses(stripeMemeber, stripeClass, fguiNamespace)
    local classes = handler:CollectClasses(settings.ignoreNoname, settings.ignoreNoname, nil)
    handler:SetupCodeFolder(exportCodePath, "lua") --check if target folder exists, and delete old files
    local getMemberByName = settings.getMemberByName

    local classCnt = classes.Count
    local writer = CodeWriter.new()
	
    writer:reset()
	writer:writeln('local M = {}')
    for i=0,classCnt-1 do
        local classInfo = classes[i]
        local members = classInfo.members
		writer.lines[1] = "--This is an automatically generated class by FairyGUI. Please do not modify it."
		writer:writeln(string.format('function M.%s(vm, view)', classInfo.className))
		writer:incIndent()
			writer:writeln('vm.__view = view')
			local memberCnt = members.Count
			for j=0,memberCnt-1 do
				local memberInfo = members[j]
				local typeName = memberInfo.type
				if memberInfo.group==0 then
					local isCustom
					for k = 0, classCnt-1 do
						if typeName == classes[k].className then
							isCustom =  true
							break
						end
					end
					if getMemberByName then
						if isCustom then
							writer:writeln('vm.%s = M.%s({}, view:GetChild("%s"))', memberInfo.name, typeName, memberInfo.name)
						else
							writer:writeln('vm.%s = view:GetChild("%s")', memberInfo.name, memberInfo.name)
						end
					else
						if isCustom then
							writer:writeln('vm.%s = M.%s({}, view:GetChildAt(%s))', memberInfo.name, typeName, memberInfo.index)
						else
							writer:writeln('vm.%s = view:GetChildAt(%s)', memberInfo.name, memberInfo.index)
						end
					end
				elseif memberInfo.group==1 then
					if getMemberByName then
						writer:writeln('vm.%s = view:GetController("%s")', memberInfo.name, memberInfo.name)
					else
						writer:writeln('vm.%s = view:GetControllerAt(%s)', memberInfo.name, memberInfo.index)
					end
				else
					if getMemberByName then
						writer:writeln('vm.%s = view:GetTransition("%s")', memberInfo.name, memberInfo.name)
					else
						writer:writeln('vm.%s = view:GetTransitionAt(%s)', memberInfo.name, memberInfo.index)
					end
				end
			end
			writer:writeln("return vm")
		writer:decIndent()
		writer:writeln('end')
    end
	writer:writeln('return M')
	writer:save(exportCodePath..'/'..namespaceName..'.lua')
end

function onPublish(handler)
    if not handler.genCode then return end
    handler.genCode = false --prevent default output

    fprint('Handling gen code in plugin')
    genCode(handler) --do it myself
end

function onDestroy()
-------do cleanup here-------
end
