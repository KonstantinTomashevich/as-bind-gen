TemplatesUtils = {}
TemplatesUtils.ProcessTemplateString = function (string, vars)
    local resultString = string
    for key, value in pairs (vars) do
        resultString = resultString:gsub ("${" .. key .. "}", value)
    end
    return resultString
end

TemplatesUtils.ProcessTemplateFile = function (inputFileName, outputFile, commands)
    for line in io.lines (inputFileName) do
        local isCommand = false
        for command, processor in pairs (commands) do
            if not isCommand then
                if line:find (configuration.bindingsGeneratorCommand .. " " .. command) ~= nil then
                    if not processor:Write (outputFile) then
                        return false
                    end
                    isCommand = true
                end
            end
        end

        if not isCommand then
            outputFile:write (line .. "\n")
        end
    end
    return true
end
return TemplatesUtils
