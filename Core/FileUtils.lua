FileUtils = {}
FileUtils.RemoveBeginPointsInPath = function (path)
    local newPath = path
    while newPath:sub (1, 1) == "." or newPath:sub (1, 1) == "/" do
        newPath = newPath:sub (2, newPath:len ())
    end
    return newPath
end

FileUtils.IsWindowsCmd = function ()
    return (os.execute ("cls") == 0)
end

FileUtils.MakePath = function (path)
    local chunkTemplate = ""
    chunkTemplate = "((cd ${dir} && cd ${exit} ) || mkdir ${dir})"

    local command = ""
    local dirIndex = 1
    local pathAddition = ""
    local pathSeparator = "/"
    if FileUtils.IsWindowsCmd () then
        pathSeparator = "\\"
    end

    for dir in path:gmatch ("%a+/") do
        if dirIndex > 1 then
            command = command .. " && "
        end

        local exitPath = ""
        for index = 1, dirIndex do
            if index > 1 then
                exitPath = exitPath .. pathSeparator
            end
            exitPath = exitPath .. ".."
        end

        local dirName = dir:sub (1, dir:len () - 1)
        command = command .. chunkTemplate:gsub ("${dir}", pathAddition .. dirName):
                gsub ("${exit}", exitPath)
        pathAddition = pathAddition .. dirName .. pathSeparator
        dirIndex = dirIndex + 1
    end
    os.execute (command)
end

FileUtils.CreateNewFile = function (fileName)
    local file = io.open (fileName, "w+")
    if file == nil then
        local dir = FileUtils.RemoveBeginPointsInPath (fileName:match (".*/"))
        FileUtils.MakePath (dir)
        file = io.open (fileName, "w+")
    end
    return file
end
return FileUtils
