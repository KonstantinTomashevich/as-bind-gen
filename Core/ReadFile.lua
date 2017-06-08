local TokenizeFile = require (scriptDirectory .. "Tokenization/TokenizeFile")
if TokensList == nil then
    TokensList = require (scriptDirectory .. "Tokenization/TokensList")
end
if Tokens == nil then
    Tokens = require (scriptDirectory .. "Tokenization/Tokens")
end
local currentlyProcessing = nil

function ReadFile (fileName)
    local file = io.open (ConfigurationUtils.LocalFileNameToFilePath (fileName), "r")
    local tokens = TokenizeFile (file)
    local tokensList = TokensList (tokens)
    local token = tokensList:CurrentToken ()

    while token ~= nil do
        if currentlyProcessing ~= nil then
            if not currentlyProcessing:Parse (tokensList) then
                currentlyProcessing = nil
                return false
            else
                -- For correct methods parsing, classes do self-insertion before methods parsing.
                if not currentlyProcessing:IsSelfInserted () then
                    table.insert (data [currentlyProcessing:GetDataDestination ()], currentlyProcessing)
                end
                currentlyProcessing = nil
            end
        elseif token.type == Tokens.Command then
            local commandData = TokenUtils.ParseCommand (token)
            if bindables [commandData.command] ~= nil then
                currentlyProcessing = bindables [commandData.command] (fileName, commandData.arguments)
            else
                Log ("Line " .. token.line .. ": Unknown command \"" .. commandData.command .. "\"!")
            end
        end
        token = tokensList:NextToken ()
    end

    file:close ()
    return true
end

return ReadFile
