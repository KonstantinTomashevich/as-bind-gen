local registerAnythingBody =
[[void RegisterAnything (asIScriptEngine *engine)
{
    RegisterClassesForwardDeclarations (engine);
    RegisterEnums (engine);
    RegisterConstants (engine);
    RegisterFreeFunctions (engine);
    RegisterUrho3DSubsystems (engine);
    RegisterClasses (engine);
}

]]

local IncludesWriter = Class ()
IncludesWriter.Construct = function (self)

end

IncludesWriter.Write = function (self, outputFile)
    outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.IncludeRelativePath,
                        {file = configuration.bindingsFileName .. ".hpp"}))

    for index, fileData in ipairs (data.filesToWriteList) do
        outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.IncludeFullPath,
                            {file = ConfigurationUtils.LocalFileNameToProjectBindingsIncludePath (fileData.name)}))
    end
    return true
end

local BodyWriter = Class ()
BodyWriter.Construct = function (self)

end

BodyWriter.Write = function (self, outputFile)
    outputFile:write (registerAnythingBody)
    return (self:WriteClassesForwardDeclarations (outputFile) and
            self:WriteStandartBindings (outputFile) and
            self:WriteClassesBindings (outputFile))
end

BodyWriter.WriteClassesForwardDeclarations = function (self, outputFile)
    outputFile:write ("void RegisterClassesForwardDeclarations (asIScriptEngine *engine)\n{\n")
    for index, class in ipairs (data.classes) do
        local objectType = ""
        local size = "sizeof (" .. class.name .. ")"

        if class.arguments ["ObjectType"] == "Ref" then
            objectType = "asOBJ_REF"
            size = "0"
        elseif class.arguments ["ObjectType"] == "Value" then
            objectType = "asOBJ_VALUE"
        elseif class.arguments ["ObjectType"] == "POD" then
            objectType = "asOBJ_VALUE | asOBJ_POD"
        end

        outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.DeclareClass,
                            {name = class.bindingName, size = size, objectType = objectType}))
    end
    outputFile:write ("}\n\n")
    return true
end

BodyWriter.WriteStandartBindings = function (self, outputFile)
    local toBindStandart = {}
    table.insert (toBindStandart, {functionName = "void RegisterEnums (asIScriptEngine *engine)", key = "enums"})
    table.insert (toBindStandart, {functionName = "void RegisterConstants (asIScriptEngine *engine)", key = "constants"})
    table.insert (toBindStandart, {functionName = "void RegisterFreeFunctions (asIScriptEngine *engine)", key = "freeFunctions"})
    table.insert (toBindStandart, {functionName = "void RegisterUrho3DSubsystems (asIScriptEngine *engine)", key = "subsystems"})

    for configIndex, config in ipairs (toBindStandart) do
        outputFile:write (config.functionName .. "\n{\n")
        local alreadyCalled = {}
        for index, value in ipairs (data [config.key]) do
            if alreadyCalled [value.name] == nil then
                outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.CallStandartRegister,
                                    {name = value.bindingName}))
                alreadyCalled [value.bindingName] = true
            end
        end
        outputFile:write ("}\n\n")
    end
    return true
end

BodyWriter.WriteClassesBindings = function (self, outputFile)
    outputFile:write ("void RegisterClasses (asIScriptEngine *engine)\n{\n")
    for index, class in ipairs (data.classes) do
        outputFile:write (TemplatesUtils.ProcessTemplateString (Templates.CallClassRegister,
                            {baseName = class.bindingName,
                             templateName = class.name,
                             bindingName = "\"" .. class.bindingName .. "\"",
                             registerConstructors = "true"}))
    end
    outputFile:write ("}\n\n")
    return true
end

function WriteMainCpp ()
    local inputFileName = configuration.outputCppFileTemplate
    local fileName = ConfigurationUtils.LocalFileNameToBindingsFilePath (configuration.bindingsFileName .. ".cpp")
    local outputFile = FileUtils.CreateNewFile (fileName)

    local commands = {}
    commands ["WriteIncludes"] = IncludesWriter ()
    commands ["WriteBody"] = BodyWriter ()

    local result = TemplatesUtils.ProcessTemplateFile (inputFileName, outputFile, commands)
    outputFile:close ()
    return result
end
return WriteMainCpp
