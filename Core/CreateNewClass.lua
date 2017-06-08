function CreateNewClass (...)
    local newClass = {}
    local bases = {...}

    -- Copy base classes content.
    for index, base in ipairs (bases) do
        for key, value in pairs (base) do
            newClass [key] = value
        end
    end

    -- Fill `IsA` table for inheritance checking.
    newClass.__index = newClass
    newClass.isA = {[newClass] = true}
    for iindex, base in ipairs (bases) do
        for baseOfBase in pairs (base.isA) do
            newClass.isA [baseOfBase] = true
        end
        newClass.isA [base] = true
    end

    -- The class's __call metamethod.
    setmetatable (newClass, {__call =
        function (c, ...)
            local instance = setmetatable ({}, c)
            local init = instance.Construct
            if init ~= nil then
                init (instance, ...)
            end
            return instance
        end
    })
    return newClass
end
return CreateNewClass
