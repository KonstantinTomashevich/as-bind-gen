TypeUtils = {}
TypeUtils.BasicCXXToASType = function (type)
    if type == "unsigned" then
        return "uint"
    end

    local newType = type:gsub ("*", "@"):gsub ("unsigned ", "u"):gsub ("long", "int64"):
            gsub ("short", "int16"):gsub ("byte", "int8"):
            gsub ("PODVector <", "Array <"):gsub ("PODVector<", "Array<"):
            gsub ("Vector <", "Array <"):gsub ("Vector<", "Array<")

    if newType:find ("Array ") ~= nil or newType:find ("Array<") ~= nil then
        newType = newType .. " @"
    end

    if newType:find ("SharedPtr <") == 1 or newType:find ("SharedPtr<") == 1 then
        newType = newType:match ("<.*>")
        newType = newType:sub (2, newType:len () - 1)

    elseif newType:find ("Array <") == 1 or newType:find ("Array<") == 1 then
        newType = "Array <" .. TypeUtils.GetArrayElementType (newType) .. "> @"
    end
    return newType
end

TypeUtils.CheckParsedClassesAndEnumsNames = function (type)
    local toCheck = {"classes", "enums"}
    for itemIndex, toCheckItem in ipairs (toCheck) do
        for index, parsed in ipairs (data [toCheckItem]) do
            if parsed.name ~= parsed.bindingName and type ~= parsed.name then
                type = type:gsub (parsed.name, parsed.bindingName)
            end
        end
    end
    return type
end

TypeUtils.RemoveNamespaces = function (type)
    local newType = type
    local index = newType:find ("::")

    while index ~= nil do
        local toRemove = "::"
        local nextScanIndex = index - 1

        if nextScanIndex ~= 0 then
            local char = newType:sub (nextScanIndex, nextScanIndex)
            while char ~= " " and char ~= "," and char ~= "<" and char ~= ">" and
                char ~= "@" and char ~= "+" and char ~= "*" and char ~= "&" and nextScanIndex > 0 do
                toRemove = char .. toRemove
                nextScanIndex = nextScanIndex - 1
                char = newType:sub (nextScanIndex, nextScanIndex)
            end
        end
        newType = newType:gsub (toRemove, "")
        index = newType:find ("::")
    end

    return newType
end

TypeUtils.ConvertCXXToASType = function (type)
    return TypeUtils.CheckParsedClassesAndEnumsNames (TypeUtils.BasicCXXToASType (TypeUtils.RemoveNamespaces (type)))
end

TypeUtils.IsCXXArray = function (type)
    return type:find ("Vector ") ~= nil or type:find ("Vector<") ~= nil
end

TypeUtils.ASArrayTypeInCXX = function (type)
    return "Urho3D::CScriptArray *"
end

TypeUtils.GetArrayShortType = function (type)
    local typeWithoutNamespaces = TypeUtils.RemoveNamespaces (type):gsub ("const ", "")
    local index = 1
    local shortType = ""
    local char = ""

    while char ~= "<" and char ~= " " and index <= typeWithoutNamespaces:len () do
        shortType = shortType .. char
        char = typeWithoutNamespaces:sub (index, index)
        index = index + 1
    end
    return shortType
end

TypeUtils.GetArrayElementType = function (type)
    local elementType = type
    while elementType:find ("Vector <") or elementType:find ("Vector<") or
        elementType:find ("SharedPtr <") or elementType:find ("SharedPtr<") or
        elementType:find ("Array <") or elementType:find ("Array<") do

        local isAddRef = elementType:find ("SharedPtr <") == 1 or elementType:find ("SharedPtr<") == 1
        elementType = elementType:match ("<.*>")
        elementType = elementType:sub (2, elementType:len () - 1)
        if isAddRef then
            elementType = elementType .. " @"
        end
    end
    return elementType
end
return TypeUtils
