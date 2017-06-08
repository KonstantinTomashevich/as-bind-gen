local mainHppBody =
[[void RegisterAnything (asIScriptEngine *engine);
void RegisterClassesForwardDeclarations (asIScriptEngine *engine);
void RegisterEnums (asIScriptEngine *engine);
void RegisterConstants (asIScriptEngine *engine);
void RegisterFreeFunctions (asIScriptEngine *engine);
void RegisterUrho3DSubsystems (asIScriptEngine *engine);
void RegisterClasses (asIScriptEngine *engine);
]]

local IncludesWriter = Class ()
IncludesWriter.Construct = function (self)

end

IncludesWriter.Write = function (self, outputFile)
    return true
end

local BodyWriter = Class ()
BodyWriter.Construct = function (self)

end

BodyWriter.Write = function (self, outputFile)
    outputFile:write (mainHppBody)
    return true
end

function WriteMainHpp ()
    local inputFileName = configuration.outputHppFileTemplate
    local fileName = ConfigurationUtils.LocalFileNameToBindingsFilePath (configuration.bindingsFileName .. ".hpp")
    local outputFile = FileUtils.CreateNewFile (fileName)

    local commands = {}
    commands ["WriteIncludes"] = IncludesWriter ()
    commands ["WriteBody"] = BodyWriter ()

    local result = TemplatesUtils.ProcessTemplateFile (inputFileName, outputFile, commands)
    outputFile:close ()
    return result
end
return WriteMainHpp
