local Utils = require("modules/utils")
local CONFIG = require("config")
local Effects = require("modules/effects")

local Progression = {}

local FILE_NAME = "progression.txt"

local DEFAULT_DATA = {
    totalRuns = 0,
    totalWins = 0,
    totalDeaths = 0,
    totalKeysCollected = 0,
    totalMonstersKilled = 0,
    totalItemsCollected = 0,
    fastestTime = math.huge,
    unlocks = {
        speedBoostStart = false,
        invincibilityStart = false,
        extraInventorySlot = false,
        ghostSlowStart = false,
        mapReveal = false,
        combatMaster = false,
        speedRunner = false,
        survivor = false,
    },
    cosmetics = {
        playerSkin = "default",
    }
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

local function coerce(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif value == "inf" or value == "math.huge" then
        return math.huge
    end

    local numeric = tonumber(value)
    if numeric ~= nil then
        return numeric
    end
    return value
end

local function applyDefaults(rawData)
    local defaults = Utils.deepCopy(DEFAULT_DATA)
    local function merge(into, source)
        for key, value in pairs(source or {}) do
            if type(value) == "table" and type(into[key]) == "table" then
                merge(into[key], value)
            else
                into[key] = value
            end
        end
    end
    merge(defaults, rawData)
    return defaults
end

function Progression.serialize(data)
    local lines = {
        "totalRuns=" .. data.totalRuns,
        "totalWins=" .. data.totalWins,
        "totalDeaths=" .. data.totalDeaths,
        "totalKeysCollected=" .. data.totalKeysCollected,
        "totalMonstersKilled=" .. data.totalMonstersKilled,
        "totalItemsCollected=" .. data.totalItemsCollected,
        "fastestTime=" .. tostring(data.fastestTime),
        "[unlocks]",
    }

    for key, value in pairs(data.unlocks) do
        table.insert(lines, key .. "=" .. tostring(value))
    end

    table.insert(lines, "[cosmetics]")
    for key, value in pairs(data.cosmetics) do
        table.insert(lines, key .. "=" .. tostring(value))
    end

    return table.concat(lines, "\n")
end

function Progression.deserialize(content)
    local data = Utils.deepCopy(DEFAULT_DATA)
    local section = "stats"

    for line in (content or ""):gmatch("[^\r\n]+") do
        if line == "[unlocks]" then
            section = "unlocks"
        elseif line == "[cosmetics]" then
            section = "cosmetics"
        else
            local key, rawValue = line:match("^(.+)=(.+)$")
            if key and rawValue then
                if section == "stats" then
                    data[key] = coerce(rawValue)
                elseif section == "unlocks" then
                    data.unlocks[key] = coerce(rawValue)
                elseif section == "cosmetics" then
                    data.cosmetics[key] = rawValue
                end
            end
        end
    end

    return applyDefaults(data)
end

function Progression.load()
    local fs = getFilesystem()
    if not fs.exists(FILE_NAME) then
        Progression.data = Utils.deepCopy(DEFAULT_DATA)
        return Progression.data
    end

    local content = fs.read(FILE_NAME)
    Progression.data = Progression.deserialize(content)
    return Progression.data
end

function Progression.save()
    local fs = getFilesystem()
    return fs.write(FILE_NAME, Progression.serialize(Progression.data))
end

function Progression.checkUnlocks()
    local unlocks = Progression.data.unlocks
    local newUnlocks = {}

    local function unlock(key, message)
        if not unlocks[key] then
            unlocks[key] = true
            table.insert(newUnlocks, message)
        end
    end

    if Progression.data.totalRuns >= 5 then
        unlock("speedBoostStart", "Speed Boost Start")
    end
    if Progression.data.totalRuns >= 10 then
        unlock("invincibilityStart", "Invincibility Start")
    end
    if Progression.data.totalRuns >= 15 then
        unlock("extraInventorySlot", "Extra Inventory Slot")
    end
    if Progression.data.totalRuns >= 20 then
        unlock("ghostSlowStart", "Ghost Slow Start")
    end
    if Progression.data.totalWins >= 3 then
        unlock("mapReveal", "Map Reveal")
    end
    if Progression.data.totalWins >= 5 then
        unlock("combatMaster", "Combat Master")
    end
    if Progression.data.fastestTime < 120 then
        unlock("speedRunner", "Speed Runner")
    end
    if Progression.data.totalDeaths >= 50 then
        unlock("survivor", "Survivor")
    end

    return newUnlocks
end

function Progression.recordRun(runResult)
    Progression.data.totalRuns = Progression.data.totalRuns + 1
    Progression.data.totalDeaths = Progression.data.totalDeaths + (runResult.deaths or 0)
    Progression.data.totalKeysCollected = Progression.data.totalKeysCollected + (runResult.keysCollected or 0)
    Progression.data.totalMonstersKilled = Progression.data.totalMonstersKilled + (runResult.monstersKilled or 0)
    Progression.data.totalItemsCollected = Progression.data.totalItemsCollected + (runResult.itemsCollected or 0)

    if runResult.won then
        Progression.data.totalWins = Progression.data.totalWins + 1
        if runResult.timeTaken and runResult.timeTaken < Progression.data.fastestTime then
            Progression.data.fastestTime = runResult.timeTaken
        end
    end

    Progression.checkUnlocks()
    Progression.save()
end

function Progression.applyStartingUnlocks(run)
    local unlocks = Progression.data.unlocks
    local player = run.world.player

    if unlocks.speedBoostStart then
        player.speedBonus = player.speedBonus + 50
    end
    if unlocks.invincibilityStart then
        Effects.activeEffects.invincibility = true
        Effects.activeEffects.invincibilityTimer = 3
    end
    if unlocks.extraInventorySlot then
        player.inventorySize = player.inventorySize + 1
    end
    if unlocks.ghostSlowStart then
        Effects.activeEffects.ghostSlow = true
        Effects.activeEffects.ghostSlowTimer = 15
    end
    if unlocks.mapReveal then
        player.visionBonus = player.visionBonus + 2
    end
    if unlocks.combatMaster then
        player.attackDamage = player.attackDamage + 1
    end
    if unlocks.speedRunner then
        player.speedBonus = player.speedBonus + 80
    end
    if unlocks.survivor then
        player.extraLife = 1
    end
end

function Progression.getUnlockRequirements()
    return {
        string.format("Speed Boost Start: %d/5 runs", math.min(Progression.data.totalRuns, 5)),
        string.format("Invincibility Start: %d/10 runs", math.min(Progression.data.totalRuns, 10)),
        string.format("Extra Inventory Slot: %d/15 runs", math.min(Progression.data.totalRuns, 15)),
        string.format("Ghost Slow Start: %d/20 runs", math.min(Progression.data.totalRuns, 20)),
        string.format("Map Reveal: %d/3 wins", math.min(Progression.data.totalWins, 3)),
        string.format("Combat Master: %d/5 wins", math.min(Progression.data.totalWins, 5)),
        string.format("Speed Runner: best %.1fs (<120s)", Progression.data.fastestTime == math.huge and 0 or Progression.data.fastestTime),
        string.format("Survivor: %d/50 deaths", math.min(Progression.data.totalDeaths, 50)),
    }
end

return Progression
