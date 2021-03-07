local filename, skip = ...
if skip == nil then
    skip = {}
end

local function read_xml(file_name)
    local files = {}
    local folder = file_name:match("^(.+)/.+$")
    for line in io.lines(file_name) do
        local file = line:match('.*Script file="(.+)".*$')
        if file ~= nil then
            file = file:gsub('\\', '/')
            table.insert(files, folder .. '/' .. file)
        end
    end
    return files
end

local function load_file(file_path)
    local file = loadfile(file_path)
    if file ~= nil then
        print('Loaded ' .. file_path)
        file()
    else
        error('Unable to load file ' .. file_path)
    end
end

for line in io.lines(filename) do
    local first = line:sub(1, 1)
    if first ~= '#' and line:len() > 1 then
        line = line:gsub('\\', '/')
        line = line:gsub('lua.*', 'lua')
        line = line:gsub('xml.*', 'xml')
        local file_path = '../' .. line

        local basename = line:gsub('.*/', '')
        local extension = line:match("^.*%.(%a+)$")

        if extension == 'xml' then
            local files_xml = read_xml(file_path)
            for _, file in ipairs(files_xml) do
                --print('File from XML: ' .. file)
                load_file(file)
            end
        elseif skip[basename] ~= true then
            load_file(file_path)
        else
            print('Skip file ' .. file_path)
        end

    end
end

