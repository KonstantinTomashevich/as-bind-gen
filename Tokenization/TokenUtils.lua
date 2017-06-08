TokenUtils = {}

TokenUtils.TokenTypeToString = function (token)
    if token.type == Tokens.Operator then
        return "Operator"
    elseif token.type == Tokens.TypeOrName then
        return "Type Or Name"
    elseif token.type == Tokens.Command then
        return "Command"
    elseif token.type == Tokens.EndOfLine then
        return "End Of Line"
    elseif token.type == Tokens.EndOfFile then
        return "End Of File"
    else
        return "Unknown Token"
    end
end

TokenUtils.TokenToString = function (token)
    local tokenValue = token.value
    if tokenValue == nil then
        tokenValue = "nil"
    end
    return "\"" .. tokenValue .. "\"(" .. TokenUtils.TokenTypeToString (token) .. ")"
end

TokenUtils.ParseCommand = function (token)
    local command = nil
    local arguments = {}

    for part in token.value:gmatch ("%S+") do
        if command == nil and part ~= "" then
            command = part
        elseif part ~= "" then
            local argName = nil
            local argValue = ""
            part = part:gsub ("=", " ")
            for argPart in part:gmatch ("%S+") do
                if argName == nil then
                    argName = argPart
                elseif argValue == "" then
                    argValue = argPart
                else
                    argValue = argValue .. "=" .. argPart
                end
            end

            while arguments [argName] ~= nil do
                argName = argName .. "?"
            end
            arguments [argName] = argValue
        end
    end
    return {command = command, arguments = arguments}
end
return TokenUtils
