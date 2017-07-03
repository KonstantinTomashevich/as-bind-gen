-- TODO: Implement AddRef argument!
Function = CreateNewClass ()
Function.Construct = function (self, fileName, bindingAguments, isConstructor)
    self.fileName = fileName
    self.ownerClassName = nil
    self.returnType = ""
    self.name = ""
    self.callArguments = {}

    self.bindingName = ""
    self.bindingReturnType = ""
    self.bindingCallArguments = {}

    self.isConst = false
    self.isStatic = false
    if isConstructor ~= nil then
        self.isConstructor = isConstructor
    else
        self.isConstructor = false
    end
    self.arguments = bindingAguments
end

-- Return true if no errors.
Function.Parse = function (self, tokensList)
    tokensList.skipEndOfLineTokens = true
    return ((self.isConstructor or self:ReadReturnType (tokensList)) and
        self:ReadName (tokensList) and self:ReadCallArguments (tokensList) and
        self:ReadIsConst (tokensList))
end

Function.ToString = function (self, indent)
    local string = indent
    if not self.isConstructor then
        string = string .. self.bindingReturnType .. " "
    end
    string = string .. self.bindingName

    if self.bindingName ~= self.name or self.bindingReturnType ~= self.returnType then
        string = string .. " (from " .. self.returnType .. " " .. self.name .. ")"
    end
    string = string .. " from file " .. self.fileName .. "\n" .. indent .. "(\n"

    for key, value in pairs (self.bindingCallArguments) do
        string = string .. indent .. "    "
        if value.type == "UseUrho3DScriptContext" then
            string = string .. "[Urho3D script context will be passed as argument]"
        else
            string = string .. value.type .. " " .. value.name
            if value.default ~= nil then
                string = string .. " = " .. value.default
            end

            local sourceCallArgument = self.callArguments [key]
            if sourceCallArgument.type ~= value.type or
                sourceCallArgument.name ~= value.name or
                sourceCallArgument.default ~= value.default then

                string = string .. " (from " .. sourceCallArgument.type .. " " .. sourceCallArgument.name
                if sourceCallArgument.default ~= nil then
                    string = string .. " = " .. sourceCallArgument.default
                end
                string = string .. ")"
            end
        end
        string = string .. "\n"
    end

    string = string .. indent .. ")"
    if self.isConst then
        string = string .. " const"
    end
    string = string .. "\n"
    return string
end

Function.ApplyArguments = function (self)
    if self.ownerClassName ~= nil then
        local owner = DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (self.ownerClassName))
        self.ownerClassBindingName = owner.bindingName
    end

    if self.isStatic then
        self.bindingName = self.ownerClassBindingName .. self.name
    else
        self.bindingName = self.name
    end

    self.bindingReturnType = TypeUtils.ConvertCXXToASType (self.returnType)
    for key, value in pairs (self.callArguments) do
        self.bindingCallArguments [key] = {}
        for innerKey, innerValue in pairs (value) do
            if innerKey == "type" then
                self.bindingCallArguments [key] [innerKey] = TypeUtils.ConvertCXXToASType (innerValue)
            else
                self.bindingCallArguments [key] [innerKey] = innerValue
            end
        end
    end

    for key, value in pairs (self.arguments) do
        key = key:gsub ("?", "")
        if key == "OverrideName" then
            self.bindingName = value

        elseif key:find ("OverrideType_") == 1 then
            local argumentIndex = tonumber (key:sub (("OverrideType_arg"):len () + 1, key:len ()))
            if argumentIndex == -1 then
                self.bindingReturnType = value
            else
                self.bindingCallArguments [argumentIndex + 1].type = value
            end

        elseif key:find ("OverrideName_") == 1 then
            local argumentIndex = tonumber (key:sub (("OverrideName_arg"):len () + 1, key:len ()))
            self.bindingCallArguments [argumentIndex + 1].name = value

        elseif key:find ("Replace") == 1 then
            local pattern = nil
            local replace = ""
            local valueCopy = value:gsub ("|", " ")
            for part in valueCopy:gmatch ("%S+") do
                if pattern == nil then
                    pattern = part
                elseif replace == "" then
                    replace = part
                else
                    replace = replace .. "|"
                end
            end

            if key:find ("ReplaceInType_") == 1 then
                local argumentIndex = tonumber (key:sub (("ReplaceInType_arg"):len () + 1, key:len ()))
                if argumentIndex == -1 then
                    self.bindingReturnType = self.bindingReturnType:gsub (pattern, replace)
                else
                    self.bindingCallArguments [argumentIndex + 1].type =
                        self.bindingCallArguments [argumentIndex + 1].type:gsub (pattern, replace)
                end
            elseif key:find ("ReplaceInName_") == 1 then
                local argumentIndex = tonumber (key:sub (("ReplaceInName_arg"):len () + 1, key:len ()))
                self.bindingCallArguments [argumentIndex + 1].name =
                    self.bindingCallArguments [argumentIndex + 1].name:gsub (pattern, replace)
            end

        elseif key:find ("UseUrho3DScriptContext_") == 1 then
            local argumentIndex = tonumber (key:sub (("UseUrho3DScriptContext_arg"):len () + 1, key:len ()))
            self.bindingCallArguments [argumentIndex + 1].type = "UseUrho3DScriptContext"

        elseif key:find ("AddRef_") == 1 then
            local argumentIndex = tonumber (key:sub (("AddRef_arg"):len () + 1, key:len ()))
            if argumentIndex == -1 then
                self.bindingReturnType = self.bindingReturnType .. "+"
            else
                self.bindingCallArguments [argumentIndex + 1].type =
                    self.bindingCallArguments [argumentIndex + 1].type .. "+"
            end
        end
    end
end

Function.GetRequiredBindingsIncludes = function (self)
    return {}
end

Function.GenerateWrappers = function (self)
    -- TODO: Maybe wrappers names should be ${ownerClassName}_${name}_${argumentsNames}? (for support of functions with same name)
    if self:IsWrapperNeeded () then
        return self:GenerateWrapperReturnType () .. " " ..
                self:GenerateWrapperName () .. " (" ..
                self:GenerateWrapperArguments () .. ")" .. "\n" .. "{\n" ..
                self:GenerateWrapperCode () .. "}\n\n"
    else
        return ""
    end
end

Function.GenerateRegistratorCode = function (self)
    if self.isConstructor then
        return self:GenerateConstructorRegistrator ()
    elseif self.isStatic or self.ownerClassName == nil then
        return self:GenerateStaticOrFreeRegistrator ()
    else
        return self:GenerateMethodRegistrator ()
    end
end

Function.ReadReturnType = function (self, tokensList)
    local token = tokensList:CurrentOrNextToken ()
    while token.type == Tokens.TypeOrName and (token.value == "static" or token.value == "virtual") do
        if token.value == "static" then
            self.isStatic = true
        end
        token = tokensList:NextToken ()
    end

    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName then
        Log ("Line " .. token.line .. ": Expected function return type, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        self.returnType = token.value
        return true
    end
end

Function.ReadName = function (self, tokensList)
    local token = nil
    if (self.isConstructor) then
        token = tokensList:CurrentOrNextToken ()
    else
        token = tokensList:NextToken ()
    end

    if token.type == Tokens.TypeOrName and token.value == "explicit" then
        token = tokensList:NextToken ()
    end

    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName then
        if self.returnType:find ("unsigned ") == 1 then
            self.name = self.returnType:sub (("unsigned "):len () + 1, self.returnType:len ())
            self.returnType = "unsigned"
            tokensList:PreviousToken ()
            return true
        else
            Log ("Line " .. token.line .. ": Expected function name, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
            return false
        end
    else
        self.name = token.value
        return true
    end
end

Function.ReadCallArguments = function (self, tokensList)
    if not self:SkipUntilArgumentsListBegin (tokensList) then
        return false
    end

    local whatNextNameTokenWillBe = "type"
    local token = tokensList:NextToken ()
    local currentArg = nil

    while token ~= nil and not (token.type == Tokens.Operator and token.value == ")") do
        if currentArg == nil then
            currentArg = {}
        end

        if token.type == Tokens.TypeOrName then
            if whatNextNameTokenWillBe == "type" then
                currentArg.type = token.value
                whatNextNameTokenWillBe = "name"

            elseif whatNextNameTokenWillBe == "name" then
                currentArg.name = token.value
                whatNextNameTokenWillBe = ""

            elseif whatNextNameTokenWillBe == "default" then
                currentArg.default = token.value
                whatNextNameTokenWillBe = ""
            end

        elseif token.type == Tokens.Operator and token.value == "=" then
            if currentArg.type == nil or currentArg.name == nil then
                if currentArg.type:find ("unsigned ") == 1 then
                    currentArg.name = currentArg.type:sub (("unsigned "):len () + 1, currentArg.type:len ())
                    currentArg.type = "unsigned"
                    whatNextNameTokenWillBe = "default"
                else
                    Log ("Line " .. token.line .. ": Call argument type or name is not readed, but got \"=\"!")
                    return false
                end
            else
                whatNextNameTokenWillBe = "default"
            end

        elseif token.type == Tokens.Operator and token.value == "," then
            if whatNextNameTokenWillBe == "default" then
                Log ("Line " .. token.line .. ": Expected call argument default, but got \",\"!")
                return false

            elseif currentArg.type == nil or currentArg.name == nil then
                if currentArg.type:find ("unsigned ") == 1 then
                    currentArg.name = currentArg.type:sub (("unsigned "):len () + 1, currentArg.type:len ())
                    currentArg.type = "unsigned"

                    whatNextNameTokenWillBe = "type"
                    table.insert (self.callArguments, currentArg)
                    currentArg = nil
                else
                    Log ("Line " .. token.line .. ": Call argument type or name is not readed, but got \",\"!")
                    return false
                end

            else
                whatNextNameTokenWillBe = "type"
                table.insert (self.callArguments, currentArg)
                currentArg = nil
            end

        else
            Log ("Line " .. token.line .. ": Unexpected token \"" .. TokenUtils.TokenToString (token) .. "\" while reading function call arguments!")
            return false
        end
        token = tokensList:NextToken ()
    end

    if token == nil then
        Log ("End of file reached while trying to read call arguments while reading function!")
        return false
    elseif currentArg ~= nil then
        if currentArg.type == nil or currentArg.name == nil then
            if currentArg.type:find ("unsigned ") == 1 then
                currentArg.name = currentArg.type:sub (("unsigned "):len () + 1, currentArg.type:len ())
                currentArg.type = "unsigned"

                table.insert (self.callArguments, currentArg)
                currentArg = nil
                return true
            else
                Log ("Line " .. token.line .. ": Call argument type or name is not readed, but got \")\"!")
                return false
            end
        else
            table.insert (self.callArguments, currentArg)
            currentArg = nil
            return true
        end
    else
        return true
    end
end

Function.ReadIsConst = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type == Tokens.Operator then
        if token.value == ";" or token.value == "{" or token.value == "=" then
            return true
        else
            Log ("Line " .. token.line .. ": Expected function declaration end, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
            return false
        end

    elseif token.type == Tokens.TypeOrName then
        if token.value == "const" then
            self.isConst = true
            return true
        else
            Log ("Line " .. token.line .. ": Expected function declaration end, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
            return false
        end
    end
end

Function.SkipUntilArgumentsListBegin = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.Operator and token.value ~= "(" then
        Log ("Line " .. token.line .. ": Expected \"(\", but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        return true
    end
end

Function.IsWrapperNeeded = function (self)
    if TypeUtils.IsCXXArray (self.returnType) or self.isConstructor or self.isStatic then
        return true
    end

    for index, callArgument in ipairs (self.callArguments) do
        if TypeUtils.IsCXXArray (callArgument.type) then
            return true
        end
    end
    return false
end

Function.GenerateWrapperReturnType = function (self)
    if self.isConstructor then
        return self.ownerClassName .. " *"
    elseif TypeUtils.IsCXXArray (self.returnType) then
        return TypeUtils.ASArrayTypeInCXX ()
    else
        return self.returnType
    end
end

Function.GenerateWrapperName = function (self)
    local wrapperName = ""
    wrapperName = wrapperName .. "wrapper_"
    if self.ownerClassName ~= nil then
        wrapperName = wrapperName .. self.ownerClassBindingName .. "_"
    end

    if self.isConstructor then
        wrapperName = wrapperName .. "constructor"
    else
        wrapperName = wrapperName .. self.name
    end

    for key, callArgument in pairs (self.bindingCallArguments) do
        if callArgument.type ~= "UseUrho3DScriptContext" then
            wrapperName = wrapperName .. "_" .. callArgument.name
        end
    end
    return wrapperName
end

Function.GenerateWrapperArguments = function (self)
    local wrapperArguments = ""
    local isFirstCallArgument = true
    if self.ownerClassName ~= nil and not self.isConstructor and not self.isStatic then
        wrapperArguments = wrapperArguments .. self.ownerClassName .. "* objectPtr"
        isFirstCallArgument = false
    end

    for key, callArgument in pairs (self.bindingCallArguments) do
        if callArgument.type ~= "UseUrho3DScriptContext" then
            if not isFirstCallArgument then
                wrapperArguments = wrapperArguments .. ", "
            else
                isFirstCallArgument = false
            end

            local sourceCallArgument = self.callArguments [key]
            if TypeUtils.IsCXXArray (sourceCallArgument.type) then
                wrapperArguments = wrapperArguments .. TypeUtils.ASArrayTypeInCXX ()
            else
                wrapperArguments = wrapperArguments .. sourceCallArgument.type
            end
            wrapperArguments = wrapperArguments .. " " .. sourceCallArgument.name

            if sourceCallArgument.default ~= nil then
                wrapperArguments = wrapperArguments .. " = " .. sourceCallArgument.default
            end
        end
    end
    return wrapperArguments
end

Function.GenerateWrapperCode = function (self)
    local wrapperCode = "    "
    if self.isConstructor then
        wrapperCode = wrapperCode .. "return new " .. self.ownerClassName .. " (" ..
                    self:GenerateWrapperFunctionCallArguments () .. ");\n"
    else
        if self.returnType ~= "void" then
            wrapperCode = wrapperCode .. self.returnType .. " result = "
        end

        if self.ownerClassName ~= nil and not self.isStatic then
            wrapperCode = wrapperCode .. "objectPtr->"
        end

        if self.isStatic then
            wrapperCode = wrapperCode .. self.ownerClassName .. "::"
        end

        wrapperCode = wrapperCode .. self.name .. " (" ..
                    self:GenerateWrapperFunctionCallArguments () .. ");\n"

        if self.returnType ~= "void" then
            if TypeUtils.IsCXXArray (self.returnType) then
                local template = ""
                if self.arguments ["ReturnHandleArray"] ~= nil then
                    template = Templates.CXXArrayToASHandleArray
                else
                    template = Templates.CXXArrayToASArray
                end

                local cxxArrayElementType = TypeUtils.GetArrayElementType (self.returnType)
                if self.arguments ["ReturnHandleArray"] ~= nil then
                    cxxArrayElementType = cxxArrayElementType:gsub ("*", "")
                end

                wrapperCode = wrapperCode .. "    return " ..
                        TemplatesUtils.ProcessTemplateString (template,
                            {cxxArrayElementType = cxxArrayElementType,
                             cxxArrayName = "result",
                             asArrayElementType = TypeUtils.GetArrayElementType (self.bindingReturnType)}) .. ";\n"
            else
                wrapperCode = wrapperCode .. "    return result;\n"
            end
        end
    end
    return wrapperCode
end

Function.GenerateWrapperFunctionCallArguments = function (self)
    local isFirstCallArgument = true
    local wrapperFunctionCallArguments = ""
    for key, callArgument in pairs (self.callArguments) do
        if not isFirstCallArgument then
            wrapperFunctionCallArguments = wrapperFunctionCallArguments .. ", "
        else
            isFirstCallArgument = false
        end

        local bindingCallArgument = self.bindingCallArguments [key]
        if bindingCallArgument.type == "UseUrho3DScriptContext" then
            wrapperFunctionCallArguments = wrapperFunctionCallArguments .. "Urho3D::GetScriptContext ()"
        else
            if TypeUtils.IsCXXArray (callArgument.type) then
                wrapperFunctionCallArguments = wrapperFunctionCallArguments ..
                        TemplatesUtils.ProcessTemplateString (Templates.ASArrayToCXXArray,
                            {cxxArrayShortType = TypeUtils.GetArrayShortType (callArgument.type),
                             cxxArrayElementType = TypeUtils.GetArrayElementType (callArgument.type),
                             asArrayName = bindingCallArgument.name})
            else
                wrapperFunctionCallArguments = wrapperFunctionCallArguments .. callArgument.name
            end
        end
    end
    return wrapperFunctionCallArguments
end

Function.GenerateConstructorRegistrator = function (self)
    return TemplatesUtils.ProcessTemplateString (Templates.RegisterClassConstructor,
                {wrapperName = self:GenerateWrapperName (),
                 wrapperArgs = self:GenerateBindingArguments ()})
end

Function.GenerateStaticOrFreeRegistrator = function (self)
    local callName = ""
    if self:IsWrapperNeeded () then
        callName = self:GenerateWrapperName ()
    elseif self.arguments ["AddNamespaceToCallName"] ~= nil then
        callName = self.arguments ["AddNamespaceToCallName"] .. "::" .. self.name
    else
        callName = self.name
    end

    return TemplatesUtils.ProcessTemplateString (Templates.RegisterFreeFunction,
                {bindingReturnType = self.bindingReturnType,
                 bindingName = self.bindingName,
                 bindingArgs = self:GenerateBindingArguments (),
                 name = callName})
end

Function.GenerateMethodRegistrator = function (self)
    local template = ""
    if self:IsWrapperNeeded () then
        template = Templates.RegisterClassMethodWithWrapper
    else
        template = Templates.RegisterClassMethodWithoutWrapper
    end

    local modifers = ""
    if self.isConst then
        modifers = "const"
    end

    return TemplatesUtils.ProcessTemplateString (template,
                {bindingReturnType = self.bindingReturnType,
                 bindingName = self.bindingName,
                 bindingArgs = self:GenerateBindingArguments (),
                 modifers = modifers,
                 name = self.name,
                 wrapperName = self:GenerateWrapperName ()})
end

Function.GenerateBindingArguments = function (self)
    local isFirstCallArgument = true
    local args = ""
    for key, callArgument in pairs (self.bindingCallArguments) do
        if callArgument.type ~= "UseUrho3DScriptContext" then
            if not isFirstCallArgument then
                args = args .. ", "
            else
                isFirstCallArgument = false
            end

            args = args ..  callArgument.type .. " " .. callArgument.name
            if callArgument.default ~= nil then
                args = args .. " = " .. callArgument.default
            end
        end
    end
    return args
end

Function.GetDataDestination = function ()
    return "freeFunctions"
end

Function.GetTypeName = function ()
    return "Function"
end

Function.IsSelfInserted = function ()
    return false
end
return Function
