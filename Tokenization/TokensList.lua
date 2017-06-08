if CreateNewClass == nil then
    CreateNewClass = require (scriptDirectory .. "Core/CreateNewClass")
end

if Tokens == nil then
    Tokens = require (scriptDirectory .. "Tokenization/Tokens")
end

TokensList = CreateNewClass ()
TokensList.Construct = function (self, tokens)
    self.currentIndex = 1
    self.tokens = tokens
    self.skipEndOfLineTokens = false
end

TokensList.PreviousToken = function (self)
    self.currentIndex = self.currentIndex - 1
    while self.skipEndOfLineTokens and self:CurrentToken () ~= nil and self:CurrentToken ().type == Tokens.EndOfLine do
        self.currentIndex = self.currentIndex - 1
    end
    return self:CurrentToken ()
end

TokensList.CurrentToken = function (self)
    return self.tokens [self.currentIndex]
end

TokensList.CurrentOrNextToken = function (self)
    if self.skipEndOfLineTokens and self:CurrentToken ().type == Tokens.EndOfLine then
        return self:NextToken ()
    else
        return self:CurrentToken ()
    end
end

TokensList.NextToken = function (self)
    self.currentIndex = self.currentIndex + 1
    while self.skipEndOfLineTokens and self:CurrentToken () ~= nil and self:CurrentToken ().type == Tokens.EndOfLine do
        self.currentIndex = self.currentIndex + 1
    end
    return self:CurrentToken ()
end
return TokensList
