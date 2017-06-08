Constant = CreateNewClass ()
Constant.Construct = function (self, fileName, bindingAguments)
    self.fileName = fileName
    self.type = ""
    self.name = ""
    self.bindingType = ""
    self.bindingName = ""
    self.arguments = bindingAguments
end

-- Return true if no errors.
Constant.Parse = function (self, tokensList)
    tokensList.skipEndOfLineTokens = true
    return (self:ReadType (tokensList) and self:ReadName (tokensList));
end

Constant.ToString = function (self, indent)
    local string = indent .. self.bindingType .. " " .. self.bindingName
    if self.bindingType ~= self.type or self.bindingName ~= self.name then
        string = string .. " (from " .. self.type .. " " .. self.name .. ")"
    end
    string = string .. " from file " .. self.fileName .. "\n"
    return string
end

Constant.ApplyArguments = function (self)
    if self.arguments ["OverrideType"] ~= nil then
        self.bindingType = self.arguments ["OverrideType"]
    else
        self.bindingType = TypeUtils.ConvertCXXToASType (self.type)
    end

    if self.arguments ["OverrideName"] ~= nil then
        self.bindingName = self.arguments ["OverrideName"]
    else
        self.bindingName = self.name
    end
end

Constant.GetRequiredBindingsIncludes = function (self)
    return {}
end

Constant.GenerateWrappers = function (self)
    local getName = self.name
    if self.arguments ["AddNamespaceToName"] ~= nil then
        getName = self.arguments ["AddNamespaceToName"] .. "::" .. self.name
    end

    return TemplatesUtils.ProcessTemplateString (Templates.ConstantWrapper,
                {name = getName,
                 bindingName = self.bindingName,
                 type = self.type})
end

Constant.GenerateRegistratorCode = function (self)
    return TemplatesUtils.ProcessTemplateString (Templates.RegisterConstant,
                {bindingName = self.bindingName,
                 bindingType = self.bindingType})
end

Constant.ReadType = function (self, tokensList)
    local token = tokensList:CurrentOrNextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token.type ~= Tokens.TypeOrName then
        Log ("Line " .. token.line .. ": Expected constant type, but got " .. TokenUtils.TokenToString (token) .. "!")
        return false
    else
        self.type = token.value
        return true
    end
end

Constant.ReadName = function (self, tokensList)
    token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false
    elseif token == nil or token.type ~= Tokens.TypeOrName then
        Log ("Line " .. token.line .. ": Expected constant name, but got " .. TokenUtils.TokenToString (token) .. "!")
        return false
    else
        self.name = token.value
        return true
    end
end

Constant.GetDataDestination = function ()
    return "constants"
end

Constant.GetTypeName = function ()
    return "Constant"
end

Constant.IsSelfInserted = function ()
    return false
end
return Constant
