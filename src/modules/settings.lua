local Utils = require("modules/utils")

local Settings = {}

local FILE_NAME = "settings.txt"

Settings.defaults = {
    audio = {
        master = 0.7,
        music = 0.6,
        sfx = 1.0,
    },
    gameplay = {
        minimap = false,
        screenShake = true,
        fog = true,
        dailyChallenge = false,
        timeAttack = false,
    },
    accessibility = {
        colorblindMode = "none",
        highContrast = false,
        slowMode = false,
        fontScale = 1.0,
        visualAudioIndicators = true,
    }
}

Settings.data = Utils.deepCopy(Settings.defaults)

local function getFilesystem()
    if love and love.filesystem then
        return {
            read = function(path)
                return love.filesystem.read(path)
            end,
            write = function(path, contents)
                return love.filesystem.write(path, contents)
            end,
            exists = function(path)
                return love.filesystem.getInfo(path) ~= nil
            end
        }
    end

    return {
        read = function(path)
            local handle = io.open(path, "r")
            if not handle then
                return nil
            end
            local contents = handle:read("*all")
            handle:close()
            return contents
        end,
        write = function(path, contents)
            local handle = io.open(path, "w")
            if not handle then
                return false
            end
            handle:write(contents)
            handle:close()
            return true
        end,
        exists = function(path)
            local handle = io.open(path, "r")
            if handle then
                handle:close()
                return true
            end
            return false
        end
    }
end

local function coerceValue(rawValue)
    if rawValue == "true" then
        return true
    elseif rawValue == "false" then
        return false
    end

    local numeric = tonumber(rawValue)
    if numeric ~= nil then
        return numeric
    end
    return rawValue
end

local function ensurePath(tbl, pathParts)
    local current = tbl
    for index = 1, #pathParts - 1 do
        local key = pathParts[index]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    return current, pathParts[#pathParts]
end

local function flatten(prefix, value, output)
    output = output or {}
    if type(value) ~= "table" then
        table.insert(output, prefix .. "=" .. tostring(value))
        return output
    end

    for key, innerValue in pairs(value) do
        local nextPrefix = prefix and (prefix .. "." .. key) or key
        flatten(nextPrefix, innerValue, output)
    end
    table.sort(output)
    return output
end

function Settings.resetDefaults()
    Settings.data = Utils.deepCopy(Settings.defaults)
    return Settings.data
end

function Settings.load()
    local fs = getFilesystem()
    Settings.resetDefaults()

    if not fs.exists(FILE_NAME) then
        return Settings.data
    end

    local contents = fs.read(FILE_NAME)
    if not contents then
        return Settings.data
    end

    for line in contents:gmatch("[^\r\n]+") do
        local path, rawValue = line:match("^([%w%.]+)=(.+)$")
        if path and rawValue then
            local parts = Utils.split(path, ".")
            local parent, leaf = ensurePath(Settings.data, parts)
            parent[leaf] = coerceValue(rawValue)
        end
    end

    return Settings.data
end

function Settings.save()
    local fs = getFilesystem()
    local lines = flatten(nil, Settings.data, {})
    return fs.write(FILE_NAME, table.concat(lines, "\n"))
end

function Settings.get(path)
    if not path or path == "" then
        return Settings.data
    end

    local current = Settings.data
    for _, part in ipairs(Utils.split(path, ".")) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
        if current == nil then
            return nil
        end
    end
    return current
end

function Settings.set(path, value)
    local parts = Utils.split(path, ".")
    local parent, leaf = ensurePath(Settings.data, parts)
    parent[leaf] = value
    return value
end

function Settings.getAll()
    return Settings.data
end

return Settings
