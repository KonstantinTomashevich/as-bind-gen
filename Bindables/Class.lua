Class = CreateNewClass ()
Class.Construct = function (self, fileName, bindingAguments)
    self.fileName = fileName
    self.name = ""
    self.publicBases = {}
    self.constructors = {}
    self.methods = {}

    self.bindingName = ""
    self.bindingPublicBases = {}
    self.arguments = bindingAguments
    self.openedBraces = 0
end

-- Return true if no errors.
Class.Parse = function (self, tokensList)
    tokensList.skipEndOfLineTokens = true
    return (self:SkipUntilClassKeyword (tokensList) and self:ReadName (tokensList) and
        self:ReadBases (tokensList) and self:PreInsertSelfToData () and self:ReadContent (tokensList))
end

Class.ToString = function (self, indent)
    local string = indent .. self.bindingName
    if self.name ~= self.bindingName then
        string = string .. " (from " .. self.name .. ")"
    end
    string = string .. " from file " .. self.fileName .. "\n" .. indent ..
        "    " .. "inherits "

    for key, value in pairs (self.publicBases) do
        local base = DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (value))
        if base ~= nil and self.bindingPublicBases [value] ~= nil then
            if base.bindingName == value then
                string = string .. value .. ", "
            else
                string = string .. base.bindingName .. " (from " .. value .. ") "
            end
        elseif self.bindingPublicBases [value] ~= nil then
            string = string .. self.bindingPublicBases [value] .. " (external) "
        end
    end

    string = string .. "\n" .. indent .. "{\n" .. indent .. "constructors:\n"
    for key, value in pairs (self.constructors) do
        string = string .. value:ToString (indent .. "    ") .. "\n"
    end

    string = string .. "\n" .. indent .. "methods:\n"
    for key, value in pairs (self.methods) do
        string = string .. value:ToString (indent .. "    ") .. "\n"
    end
    string = string .. indent .. "}\n"
    return string
end

Class.ApplyArguments = function (self)
    self.bindingName = TypeUtils.ConvertCXXToASType (self.name)
    for index, value in ipairs (self.publicBases) do
        local base = DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (value))
        if base ~= nil then
            self.bindingPublicBases [value] = base.bindingName
        else
            self.bindingPublicBases [value] = TypeUtils.ConvertCXXToASType (value)
        end
    end

    for key, value in pairs (self.arguments) do
        key = key:gsub ("?", "")
        if key == "OverrideName" then
            self.bindingName = value

        elseif key:find ("ExcludeBase_") == 1 then
            local toExclude = key:sub (("ExcludeBase_"):len () + 1, key:len ())
            self.bindingPublicBases [toExclude] = nil
        end
    end

    local toApply = {"constructors", "methods"}
    for itemIndex, toApplyItem in ipairs (toApply) do
        for index, value in ipairs (self [toApplyItem]) do
            value:ApplyArguments ()
        end
    end
end

Class.GetRequiredBindingsIncludes = function (self)
    local bindingsIncludes = {}
    local toCheck = {"methods", "constructors"}
    for itemIndex, toCheckItem in ipairs (toCheck) do
        for index, value in ipairs (self [toCheckItem]) do
            local includes = value:GetRequiredBindingsIncludes ()
            for includeIndex, include in ipairs (includes) do
                table.insert (bindingsIncludes, include)
            end
        end
    end

    for key, baseName in pairs (self.publicBases) do
        local base = DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (baseName))
        if base ~= nil then
            table.insert (bindingsIncludes, base.fileName)
        end
    end
    return bindingsIncludes
end

Class.GenerateWrappers = function (self)
    local wrappers = ""
    local toGenerate = {"constructors", "methods"}
    for itemIndex, toGenerateItem in ipairs (toGenerate) do
        for index, value in ipairs (self [toGenerateItem]) do
            wrappers = wrappers .. value:GenerateWrappers ()
        end
    end
    return wrappers
end

Class.GenerateRegistratorCode = function (self)
    local registratorCode = self:GenerateInheritanceRegistrator ()

    local toGenerate = {"constructors", "methods"}
    for itemIndex, toGenerateItem in ipairs (toGenerate) do
        if toGenerateItem == "constructors" then
            registratorCode = registratorCode .. "    if (registerConstructors)\n    {\n" ..
                    self:GenerateSubclassesRegistrator () .. "\n"
        end

        for index, value in ipairs (self [toGenerateItem]) do
            registratorCode = registratorCode .. value:GenerateRegistratorCode ()
        end

        if toGenerateItem == "constructors" then
            registratorCode = registratorCode .. "    }\n\n"
        end
    end
    return registratorCode
end

Class.SkipUntilClassKeyword = function (self, tokensList)
    local token = tokensList:CurrentOrNextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName and token.value ~= "class" then
        Log ("Line " .. token.line .. ": Expected \"class\", but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        return true
    end
end

Class.ReadName = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName then
        Log ("Line " .. token.line .. ": Expected class name, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        self.name = token.value;
        -- Set binding name there, because it affects names of constructors and static functions.
        if self.arguments ["OverrideName"] ~= nil then
            self.bindingName = self.arguments ["OverrideName"]
        else
            self.bindingName = self.name
        end
        return true
    end
end

Class.ReadBases = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false

    elseif token.type ~= Tokens.Operator then
        Log ("Line " .. token.line .. ": Expected \":\" or \"{\", but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false

    elseif token.value == "{" then
        -- There are no bases.
        return true

    elseif token.value == ":" then
        token = tokensList:NextToken ();
        local isNextBasePublic = false
        while token ~= nil and (token.type ~= Tokens.Operator and token.value ~= "{") do
            if token.type == Tokens.Operator and token.value == "," and isNextBasePublic then
                Log ("Line " .. token.line .. ": Expected public base class name, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
                return false

            elseif token.type == Tokens.TypeOrName then
                if token.value == "public" then
                    isNextBasePublic = true
                elseif isNextBasePublic then
                    table.insert (self.publicBases, token.value)
                    isNextBasePublic = false
                end
            end
            token = tokensList:NextToken ()
        end

        if token == nil then
            Log ("Fatal error, token is nil!")
            return false
        else
            self.openedBraces = 1
            return true
        end

    else
        Log ("Line " .. token.line .. ": Expected \":\" or \"{\", but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    end
end

Class.PreInsertSelfToData = function (self)
    table.insert (data [self:GetDataDestination ()], self)
    return true
end

Class.ReadContent = function (self, tokensList)
    local token = tokensList:NextToken ()
    local currentChildReader = nil
    while token ~= nil and self.openedBraces > 0 do
        if currentChildReader ~= nil then
            if not currentChildReader:Parse (tokensList) then
                return false
            elseif currentChildReader:GetTypeName () ~= "Function" then
                Log ("Line " .. token.line .. ": Class can contain only functions and constructors, but got \"" ..
                    currentChildReader:GetTypeName () .. "\"!")
                return false

            elseif currentChildReader.isConstructor then
                currentChildReader.ownerClassName = self.name
                currentChildReader.name = self.bindingName
                table.insert (self.constructors, currentChildReader)
                currentChildReader = nil

            else
                currentChildReader.ownerClassName = self.name
                if currentChildReader.isStatic then
                    table.insert (data [currentChildReader:GetDataDestination ()], currentChildReader)
                else
                    table.insert (self.methods, currentChildReader)
                end
                currentChildReader = nil
            end

        elseif token.type == Tokens.Command then
            local commandData = TokenUtils.ParseCommand (token)
            if bindables [commandData.command] ~= nil then
                currentChildReader = bindables [commandData.command] (self.fileName, commandData.arguments)
            else
                Log ("Line " .. token.line .. ": Unknown command \"" .. commandData.command .. "\"!")
            end
        end

        token = tokensList:CurrentOrNextToken ()
        if token.type == Tokens.Operator then
            if token.value == "{" then
                self.openedBraces = self.openedBraces + 1
            elseif token.value == "}" then
                self.openedBraces = self.openedBraces - 1
            end
        end
        token = tokensList:NextToken ()
    end

    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    else
        return true
    end
end

Class.GenerateInheritanceRegistrator = function (self)
    local registratorCode = ""
    for key, value in pairs (self.publicBases) do
        if self.bindingPublicBases [value] ~= nil then
            if DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (value)) then
                registratorCode = registratorCode ..
                        TemplatesUtils.ProcessTemplateString (Templates.CallClassRegister,
                            {baseName = self.bindingPublicBases [value],
                             templateName = "T",
                             bindingName = "className",
                             registerConstructors = "false"}) .. "\n"

            else
                local bindingBase = self.bindingPublicBases [value]
                local externalClass = DataUtils.GetNamedValueOfTable (data.externalClasses, TypeUtils.RemoveNamespaces (bindingBase))
                if externalClass ~= nil then
                    registratorCode = registratorCode ..
                            TemplatesUtils.ProcessTemplateString (externalClass.registratorTemplate,
                                {baseName = self.bindingPublicBases [value],
                                 templateName = "T",
                                 bindingName = "className",
                                 registerConstructors = "false"}) .. "\n"
                else
                    Log ("Error! Can't inherite from \"" .. bindingBase ..
                            "\"! Can't find this class neither in classes or external classes!")
                end
            end
        end
    end
    return registratorCode
end

Class.GenerateSubclassesRegistrator = function (self)
    local registratorCode = ""
    for key, value in pairs (self.publicBases) do
        if self.bindingPublicBases [value] ~= nil then
            local base = DataUtils.GetNamedValueOfTable (data.classes, TypeUtils.RemoveNamespaces (value))
            local bindingBase = self.bindingPublicBases [value]
            local externalClass = DataUtils.GetNamedValueOfTable (data.externalClasses, TypeUtils.RemoveNamespaces (bindingBase))

            if base ~= nil or (externalClass ~= nil and not externalClass.excludeSubclassRegistration) then
                registratorCode = registratorCode ..
                        TemplatesUtils.ProcessTemplateString (Templates.RegisterSubclass,
                            {baseName = value,
                             inheritorName = "T",
                             baseBindingName = "\"" .. self.bindingPublicBases [value] .. "\"",
                             inheritorBindingName = "className"})
            end
        end
    end
    return registratorCode
end

Class.GetDataDestination = function ()
    return "classes"
end

Class.GetTypeName = function ()
    return "Class"
end

Class.IsSelfInserted = function ()
    return true
end
return Class
