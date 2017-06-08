ConfigurationUtils = {}
ConfigurationUtils.PrintConfiguration = function ()
    Log ("### Angel Script Bindings Generator Configuration:")
    Log ("    Path prefix: " .. configuration.pathPrefix)
    Log ("    Project dir: " .. configuration.projectDir)
    Log ("    Bindings dir: " .. configuration.bindingsDir)
    Log ("    Bindings file name: " .. configuration.bindingsFileName)
    Log ("    Bindings generator command: " .. configuration.bindingsGeneratorCommand .. "\n")

    Log ("    Files: ")
    for index, value in pairs (configuration.files) do
        Log ("        [" .. index .. "] " .. value)
    end
    Log ("\n")

    Log ("    Output hpp file template path: " .. configuration.outputHppFileTemplate)
    Log ("    Output cpp file template path: " .. configuration.outputCppFileTemplate)
    Log ("\n")
    Log ("\n")
end

ConfigurationUtils.LocalFileNameToFilePath = function (fileName)
    return configuration.pathPrefix .. "/" .. configuration.projectDir .. "/" .. fileName
end

ConfigurationUtils.LocalFileNameToBindingsFilePath = function (fileName)
    return configuration.pathPrefix .. "/" .. configuration.projectDir .. "/" .. configuration.bindingsDir .. "/" .. fileName
end

ConfigurationUtils.LocalFileNameToProjectIncludePath = function (fileName)
    return configuration.projectDir .. "/" .. fileName
end

ConfigurationUtils.LocalFileNameToProjectBindingsIncludePath = function (fileName)
    return configuration.projectDir .. "/" .. configuration.bindingsDir .. "/" .. fileName
end
return ConfigurationUtils
