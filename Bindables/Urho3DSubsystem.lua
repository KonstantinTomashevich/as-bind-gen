Urho3DSubsystem = CreateNewClass ()
Urho3DSubsystem.Construct = function (self, fileName, bindingAguments)
    self.fileName = fileName
    self.name = ""
    self.type = ""
    self.bindingType = ""
    self.bindingName = ""
    self.arguments = bindingAguments
end

-- Return true if no errors.
Urho3DSubsystem.Parse = function (self, tokensList)
    local commandToken = tokensList:PreviousToken ()
    self.type = self.arguments ["Type"]
    self.bindingName = self.arguments ["BindingName"]

    if self.arguments ["BindingType"] ~= nil then
        self.bindingType = self.arguments ["BindingType"]
    else
        self.bindingType = TypeUtils.ConvertCXXToASType (self.type)
    end

    if self.type == nil then
        Log ("Line " .. token.line .. ": Can't read subsystem type!")
        return false

    elseif self.bindingName == nil then
        Log ("Line " .. token.line .. ": Can't read subsystem binding name!")
        return false

    elseif self.bindingType == nil then
        Log ("Line " .. token.line .. ": Can't read subsystem binding type!")
        return false
    else
        self.name = self.bindingType
        return true
    end
end

Urho3DSubsystem.ToString = function (self, indent)
    local string = indent .. self.bindingName .. " of type " .. self.bindingType
    if self.bindingType ~= self.type then
        string = string .. " (from " .. self.type .. ")"
    end
    string = string .. " from file " .. self.fileName .. "\n"
    return string
end

Urho3DSubsystem.ApplyArguments = function (self)

end

Urho3DSubsystem.GetRequiredBindingsIncludes = function (self)
    return {}
end

Urho3DSubsystem.GenerateWrappers = function (self)
    return TemplatesUtils.ProcessTemplateString (Templates.SubsystemWrapper,
                {bindingName = self.bindingName,
                 type = self.type})
end

Urho3DSubsystem.GenerateRegistratorCode = function (self)
    return TemplatesUtils.ProcessTemplateString (Templates.RegisterSubsystem,
                {bindingName = self.bindingName,
                 bindingType = self.bindingType})
end

Urho3DSubsystem.GetDataDestination = function ()
    return "subsystems"
end

Urho3DSubsystem.GetTypeName = function ()
    return "Urho3DSubsystem"
end

Urho3DSubsystem.IsSelfInserted = function ()
    return false
end
return Urho3DSubsystem
