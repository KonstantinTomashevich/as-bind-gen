local IncludesWriter = Class ()
IncludesWriter.Construct = function (self, fileData)
    self.fileName = fileData.name
    self.bindables = fileData.bindables
end

IncludesWriter.Write = function (self, outputFile)
    outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.IncludeFullPath,
                        {file = ConfigurationUtils.LocalFileNameToProjectIncludePath (self.fileName)}))

    local alreadyIncluded = {}
    for index, bindable in ipairs (self.bindables) do
        local requiredIncludes = bindable:GetRequiredBindingsIncludes ()
        for include, include in ipairs (requiredIncludes) do
            if alreadyIncluded [include] == nil then
                outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.IncludeFullPath,
                                    {file = ConfigurationUtils.LocalFileNameToProjectBindingsIncludePath (include)}))
                alreadyIncluded [include] = 1
            end
        end
    end
    return true
end

local BodyWriter = Class ()
BodyWriter.Construct = function (self, fileData)
    self.fileName = fileData.name
    self.bindables = fileData.bindables
end

BodyWriter.Write = function (self, outputFile)
    for index, bindable in ipairs (self.bindables) do
        outputFile:write (bindable:GenerateWrappers ())
    end

    local registratorsCodes = {}
    for index, bindable in ipairs (self.bindables) do
        local code = bindable:GenerateRegistratorCode ()
        if registratorsCodes [bindable.bindingName] == nil then
            registratorsCodes [bindable.bindingName] = {}
            registratorsCodes [bindable.bindingName].code = code
        else
            registratorsCodes [bindable.bindingName].code =
                registratorsCodes [bindable.bindingName].code .. code
        end

        if bindable:GetTypeName () == "Class" then
            registratorsCodes [bindable.bindingName].functionTemplate = Templates.ClassRegisterFunction
        else
            registratorsCodes [bindable.bindingName].functionTemplate = Templates.StandartRegisterFunction
        end
    end

    for registratorName, registrator in pairs (registratorsCodes) do
        outputFile:write (TemplatesUtils.ProcessTemplateString (registrator.functionTemplate, {name = registratorName}) ..
                            "{\n" .. registrator.code .. "}\n\n")
    end
    return true
end

function WriteFile (fileData)
    local inputFileName = configuration.outputHppFileTemplate
    local outputFile = FileUtils.CreateNewFile (ConfigurationUtils.LocalFileNameToBindingsFilePath (fileData.name))

    local commands = {}
    commands ["WriteIncludes"] = IncludesWriter (fileData)
    commands ["WriteBody"] = BodyWriter (fileData)

    local result = TemplatesUtils.ProcessTemplateFile (inputFileName, outputFile, commands)
    outputFile:close ()
    return result
end
return WriteFile
