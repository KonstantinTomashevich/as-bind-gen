Enum = CreateNewClass ()
Enum.Construct = function (self, fileName, bindingAguments)
    self.fileName = fileName
    self.name = ""
    self.values = {}
    self.bindingName = ""
    self.bindingValues = {}
    self.arguments = bindingAguments
end

-- Return true if no errors.
Enum.Parse = function (self, tokensList)
    tokensList.skipEndOfLineTokens = true
    return (self:SkipUntilEnumKeyword (tokensList) and self:ReadName (tokensList) and
        self:ReadValues (tokensList))
end

Enum.ToString = function (self, indent)
    local string = indent .. self.bindingName
    if self.bindingName ~= self.name then
        string = string .. " (from " .. self.name .. ")"
    end
    string = string .. " from file " .. self.fileName .. "\n" .. indent .. "{\n"

    for index, value in pairs (self.values) do
        string = string .. indent .. "    "
        if self.bindingValues [value] == value then
            string = string .. value
        elseif self.bindingValues [value] == nil then
            string = string .. "[exluded " .. value .. "]"
        else
            string = string .. self.bindingValues [value] .. " (from " .. value .. ")"
        end
        string = string .. "\n"
    end
    string = string .. indent .. "}\n"
    return string
end

Enum.ApplyArguments = function (self)
    self.bindingName = TypeUtils.ConvertCXXToASType (self.name)
    for index, value in ipairs (self.values) do
        self.bindingValues [value] = value
    end

    for key, value in pairs (self.arguments) do
        key = key:gsub ("?", "")
        if key == "OverrideName" then
            self.bindingName = value

        elseif key:find ("Exclude_") == 1 then
            local toExclude = key:sub (("Exclude_"):len () + 1, key:len ())
            self.bindingValues [toExclude] = nil

        elseif key:find ("Rename_") == 1 then
            local toRename = key:sub (("Rename_"):len () + 1, key:len ())
            self.bindingValues [toRename] = value
        end
    end
end

Enum.GetRequiredBindingsIncludes = function (self)
    return {}
end

Enum.GenerateWrappers = function (self)
    return ""
end

Enum.GenerateRegistratorCode = function (self)
    local registratorCode = TemplatesUtils.ProcessTemplateString (Templates.RegisterEnumType,
                                {bindingName = self.bindingName})
    for sourceName, bindingName in pairs (self.bindingValues) do
        registratorCode = registratorCode ..
                TemplatesUtils.ProcessTemplateString (Templates.RegisterEnumValue,
                        {bindingEnumName = self.bindingName,
                         bindingValue = bindingName,
                         value = sourceName})
    end
    return registratorCode
end

Enum.SkipUntilEnumKeyword = function (self, tokensList)
    local token = tokensList:CurrentOrNextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName or token.value ~= "enum" then
        Log ("Line " .. token.line .. ": Expected \"enum\"(Type Or Name), but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        return true
    end
end

Enum.ReadName = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName then
        Log ("Line " .. token.line .. ": Expected enum name, but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        self.name = token.value
        return true
    end
end

Enum.ReadValues = function (self, tokensList)
    if not self:SkipUntilValuesBlockBegin (tokensList) then
        return false
    end

    local isNextNameTokenEnumValue = true
    local token = tokensList:NextToken ()

    while token ~= nil and not (token.type == Tokens.Operator and token.value == "}") do
        if token.type == Tokens.TypeOrName and isNextNameTokenEnumValue then
            table.insert (self.values, token.value)
            isNextNameTokenEnumValue = false
        elseif token.type == Tokens.Operator and token.value == "," then
            isNextNameTokenEnumValue = true
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

Enum.SkipUntilValuesBlockBegin = function (self, tokensList)
    local token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.Operator or token.value ~= "{" then
        Log ("Line " .. token.line .. ": Expected \"{\"(Operator), but got \"" .. TokenUtils.TokenToString (token) .. "\"!")
        return false
    else
        return true
    end
end

Enum.GetDataDestination = function ()
    return "enums"
end

Enum.GetTypeName = function ()
    return "Enum"
end

Enum.IsSelfInserted = function ()
    return false
end
return Enum
