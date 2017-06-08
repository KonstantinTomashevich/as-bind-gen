ExternalClass = CreateNewClass ()
ExternalClass.Construct = function (self, fileName, bindingAguments)
    self.fileName = fileName
    self.name = ""
    self.bindingName = ""
    self.registratorTemplate = ""
    self.excludeSubclassRegistration = false
    self.arguments = bindingAguments
end

-- Return true if no errors.
ExternalClass.Parse = function (self, tokensList)
    local token = tokensList:PreviousToken ()
    self.name = self.arguments ["Name"]
    if self.arguments ["ExcludeSubclassRegistration"] ~= nil then
        self.excludeSubclassRegistration = true
    end
    self.bindingName = self.name

    token = tokensList:NextToken ()
    if token == nil then
        Log ("Fatal error, token is nil!")
        return false

    elseif token.type ~= Tokens.Command then
        Log ("Line " .. token.line .. ": Expected external class registrator template, but got " ..
                TokenUtils.TokenToString (token) .. "!")
        return false

    else
        self.registratorTemplate = token.value .. "\n"
        if self.name ~= nil then
            return true
        else
            Log ("Line " .. token.line .. ": Can't read external class name!")
            return false
        end

    end
end

ExternalClass.ToString = function (self, indent)
    local string = indent .. self.name .. " registrator template:\n" ..
        indent .. "    " .. self.registratorTemplate .. "\n"
    return string
end

ExternalClass.ApplyArguments = function (self)

end

ExternalClass.GetRequiredBindingsIncludes = function (self)
    return {}
end

ExternalClass.GenerateWrappers = function (self)
    return ""
end

ExternalClass.GenerateRegistratorCode = function (self)
    return ""
end

ExternalClass.GetDataDestination = function ()
    return "externalClasses"
end

ExternalClass.GetTypeName = function ()
    return "ExternalClass"
end

ExternalClass.IsSelfInserted = function ()
    return false
end
return ExternalClass
