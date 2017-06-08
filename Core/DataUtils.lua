DataUtils = {}
DataUtils.GetBindablesOfFile = function (fileName)
    local fileBindingTypes = {}
    local toCheck = {"enums", "constants", "freeFunctions", "classes", "subsystems"}
    for index, toCheckItem in ipairs (toCheck) do
        for key, value in pairs (data [toCheckItem]) do
            if value.fileName == fileName then
                table.insert (fileBindingTypes, value)
            end
        end
    end
    return fileBindingTypes
end

DataUtils.GetNamedValueOfTable = function (table, name)
    for key, value in pairs (table) do
        if value.name == name then
            return value
        end
    end
    return nil
end
return DataUtils
