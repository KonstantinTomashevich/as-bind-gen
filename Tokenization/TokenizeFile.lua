if Tokens == nil then
    Tokens = require (scriptDirectory .. "Tokenization/Tokens")
end

function Read (config, previousChar, char, nextChar, line)
    if char == "#" or (char == "/" and nextChar == "/") then
        config.currentReader = SkipLine
        config.immediateData = {}
        return nil

    elseif char == "@" and nextChar == "@" and (previousChar == " " or previousChar == "\n") then
        config.currentReader = ReadCommand
        config.immediateData = {}
        return nil

    elseif char == " " then
        return nil

    elseif char == "\n" then
        return {{type = Tokens.EndOfLine}}

    elseif char:match ("%a") ~= nil or char:match ("%d") or char == "\"" or char == "'" then
        config.immediateData = {}
        config.currentReader = ReadTypeOrName
        return nil

    elseif char ~= "~" then
        return {{type = Tokens.Operator, value = char, line = line}}
    end
end

function SkipLine (config, previousChar, char, nextChar, line)
    if char == "\n" then
        config.currentReader = Read
        return nil
    else
        return nil
    end
end

function ReadTypeOrName (config, previousChar, char, nextChar, line)
    if config.immediateData.readed == nil then
        config.immediateData.readed = previousChar
    end

    if config.immediateData.openedTemplates == nil then
        config.immediateData.openedTemplates = 0
    end

    if char:match ("%a") ~= nil or char:match ("%d") ~= nil or char == "." or
        char == "\"" or char == "'" or char == "_" or char == "-" or
        (config.immediateData.readed == "unsigned" and nextChar:match ("%a")) or
        (config.immediateData.readed == "const" and nextChar:match ("%a")) or
        (char == ":" and (nextChar == ":" or previousChar == ":")) or
        nextChar == "*" or nextChar == "&" or char == "<" or char == ">" or
        nextChar == "<" or nextChar == ">" or config.immediateData.openedTemplates > 0 then

        if char ~= "\n" then
            config.immediateData.readed = config.immediateData.readed .. char
        end

        if char == "<" then
            config.immediateData.openedTemplates = config.immediateData.openedTemplates + 1
        elseif char == ">" then
            config.immediateData.openedTemplates = config.immediateData.openedTemplates - 1
        end
        return nil

    else
        local tokens = {}
        if char == "*" or char == "&" then
            config.immediateData.readed = config.immediateData.readed .. char
        end

        table.insert (tokens, {type = Tokens.TypeOrName, value = config.immediateData.readed, line = line})
        if char ~= " " and char ~= "\n" and char ~= "*" and char ~= "&" then
            table.insert (tokens, {type = Tokens.Operator, value = char, line = line})
        end

        config.immediateData = {}
        config.currentReader = Read
        return tokens
    end
end

function ReadCommand (config, previousChar, char, nextChar, line)
    if config.immediateData.readed == nil then
        config.immediateData.readed = ""
    end

    if char ~= "\n" and char ~= "@" then
        config.immediateData.readed = config.immediateData.readed .. char
    elseif char == "\n" then
        local tokens = {{type = Tokens.Command, value = config.immediateData.readed, line = line}}
        config.immediateData = {}
        config.currentReader = Read
        return tokens
    else
        return nil
    end
end

function TokenizeFile (file)
    local code = ""
    for line in file:lines () do
        code = code .. line .. "\n"
    end
    code = code:gsub (configuration.bindingsGeneratorCommand, "@@")

    local tokens = {}
    local config = {currentReader = Read, immediateData = {}}
    local line = 1

    for index = 1, code:len () do
        local previousChar = ""
        if index > 1 then
            previousChar = code:sub (index - 1, index - 1)
        end
        local char = code:sub (index, index)

        local nextChar = ""
        if index < code:len () then
            nextChar = code:sub (index + 1, index + 1)
        end

        if previousChar == "\n" then
            line = line + 1
        end

        local result = config.currentReader (config, previousChar, char, nextChar, line)
        if result ~= nil then
            for key, value in pairs (result) do
                table.insert (tokens, value)
            end
        end
    end

    table.insert (tokens, {type = Tokens.EndOfFile})
    return tokens
end
return TokenizeFile
