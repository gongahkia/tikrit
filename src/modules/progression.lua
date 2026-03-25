local Utils = require("modules/utils")

local Progression = {}

local FILE_NAME = "progression.txt"

local DEFAULT_DATA = {
    totalRuns = 0,
    totalDeaths = 0,
    bestDays = 0,
    totalDaysSurvived = 0,
    totalFiresLit = 0,
    totalWaterBoiled = 0,
    totalMeatCooked = 0,
    totalClothingRepairs = 0,
    totalWolvesRepelled = 0,
    unlocks = {
        Firestarter = false,
        Outdoorsman = false,
        PackMule = false,
        Seamster = false,
        Beddown = false,
    },
}

Progression.data = Utils.deepCopy(DEFAULT_DATA)

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
            end,
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
        end,
    }
end

local function coerce(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    end
    return tonumber(value) or value
end

function Progression.deserialize(content)
    local data = Utils.deepCopy(DEFAULT_DATA)
    local section = "stats"

    for line in (content or ""):gmatch("[^\r\n]+") do
        if line == "[unlocks]" then
            section = "unlocks"
        else
            local key, value = line:match("^(.+)=(.+)$")
            if key and value then
                if section == "stats" then
                    data[key] = coerce(value)
                else
                    data.unlocks[key] = coerce(value)
                end
            end
        end
    end

    for key, value in pairs(DEFAULT_DATA.unlocks) do
        if data.unlocks[key] == nil then
            data.unlocks[key] = value
        end
    end

    return data
end

function Progression.serialize(data)
    local lines = {
        "totalRuns=" .. data.totalRuns,
        "totalDeaths=" .. data.totalDeaths,
        "bestDays=" .. data.bestDays,
        "totalDaysSurvived=" .. data.totalDaysSurvived,
        "totalFiresLit=" .. data.totalFiresLit,
        "totalWaterBoiled=" .. data.totalWaterBoiled,
        "totalMeatCooked=" .. data.totalMeatCooked,
        "totalClothingRepairs=" .. data.totalClothingRepairs,
        "totalWolvesRepelled=" .. data.totalWolvesRepelled,
        "[unlocks]",
    }

    for key, value in pairs(data.unlocks) do
        table.insert(lines, key .. "=" .. tostring(value))
    end

    return table.concat(lines, "\n")
end

function Progression.load()
    local fs = getFilesystem()
    if not fs.exists(FILE_NAME) then
        Progression.data = Utils.deepCopy(DEFAULT_DATA)
        return Progression.data
    end

    Progression.data = Progression.deserialize(fs.read(FILE_NAME))
    return Progression.data
end

function Progression.save()
    local fs = getFilesystem()
    return fs.write(FILE_NAME, Progression.serialize(Progression.data))
end

function Progression.checkUnlocks()
    local unlocks = Progression.data.unlocks
    if Progression.data.totalRuns >= 3 then
        unlocks.Firestarter = true
    end
    if Progression.data.bestDays >= 3 then
        unlocks.Outdoorsman = true
    end
    if Progression.data.bestDays >= 5 then
        unlocks.PackMule = true
    end
    if Progression.data.totalClothingRepairs >= 4 then
        unlocks.Seamster = true
    end
    if Progression.data.totalDaysSurvived >= 10 then
        unlocks.Beddown = true
    end
end

function Progression.recordRun(stats)
    Progression.data.totalRuns = Progression.data.totalRuns + 1
    Progression.data.totalDeaths = Progression.data.totalDeaths + 1
    Progression.data.bestDays = math.max(Progression.data.bestDays, stats.daysSurvived or 0)
    Progression.data.totalDaysSurvived = Progression.data.totalDaysSurvived + (stats.daysSurvived or 0)
    Progression.data.totalFiresLit = Progression.data.totalFiresLit + (stats.firesLit or 0)
    Progression.data.totalWaterBoiled = Progression.data.totalWaterBoiled + (stats.waterBoiled or 0)
    Progression.data.totalMeatCooked = Progression.data.totalMeatCooked + (stats.meatCooked or 0)
    Progression.data.totalClothingRepairs = Progression.data.totalClothingRepairs + (stats.clothingRepairs or 0)
    Progression.data.totalWolvesRepelled = Progression.data.totalWolvesRepelled + (stats.wolvesRepelled or 0)
    Progression.checkUnlocks()
    Progression.save()
end

function Progression.getFeats()
    return Utils.deepCopy(Progression.data.unlocks)
end

return Progression
