-- Meta-progression system for persistent unlocks between runs
local CONFIG = require("config")

local Progression = {}

-- Default progression state
Progression.data = {
    totalRuns = 0,
    totalWins = 0,
    totalDeaths = 0,
    totalKeysCollected = 0,
    totalMonstersKilled = 0,
    totalItemsCollected = 0,
    fastestTime = math.huge,
    
    -- Unlocks
    unlocks = {
        speedBoostStart = false,      -- Start with +50 speed (costs 5 runs)
        invincibilityStart = false,   -- Start with 3s invincibility (costs 10 runs)
        extraInventorySlot = false,   -- 4 inventory slots (costs 15 runs)
        ghostSlowStart = false,       -- Start with ghosts slowed (costs 20 runs)
        mapReveal = false,            -- Permanent fog of war reduction (costs 3 wins)
        combatMaster = false,         -- +1 attack damage (costs 5 wins)
        speedRunner = false,          -- +100 base speed (costs sub-2min run)
        survivor = false,             -- Start with extra life (costs 50 deaths)
    },
    
    -- Cosmetic unlocks
    cosmetics = {
        playerSkin = "default",  -- default, gold, shadow, crystal
    }
}

-- Save progression to file
function Progression.save()
    local file = love.filesystem.newFile("progression.txt")
    if file:open("w") then
        local data = Progression.serialize(Progression.data)
        file:write(data)
        file:close()
        print("[Progression] Saved to progression.txt")
    else
        print("[Progression] Error: Could not save progression")
    end
end

-- Load progression from file
function Progression.load()
    local info = love.filesystem.getInfo("progression.txt")
    if info then
        local content, _ = love.filesystem.read("progression.txt")
        if content then
            Progression.data = Progression.deserialize(content)
            print("[Progression] Loaded progression data")
            print(string.format("  Runs: %d | Wins: %d | Deaths: %d", 
                Progression.data.totalRuns, 
                Progression.data.totalWins, 
                Progression.data.totalDeaths))
        end
    else
        print("[Progression] No progression file found, starting fresh")
    end
end

-- Serialize progression data to string
function Progression.serialize(data)
    local lines = {}
    
    -- Stats
    table.insert(lines, "totalRuns=" .. data.totalRuns)
    table.insert(lines, "totalWins=" .. data.totalWins)
    table.insert(lines, "totalDeaths=" .. data.totalDeaths)
    table.insert(lines, "totalKeysCollected=" .. data.totalKeysCollected)
    table.insert(lines, "totalMonstersKilled=" .. data.totalMonstersKilled)
    table.insert(lines, "totalItemsCollected=" .. data.totalItemsCollected)
    table.insert(lines, "fastestTime=" .. data.fastestTime)
    
    -- Unlocks
    table.insert(lines, "[unlocks]")
    for key, value in pairs(data.unlocks) do
        table.insert(lines, key .. "=" .. tostring(value))
    end
    
    -- Cosmetics
    table.insert(lines, "[cosmetics]")
    for key, value in pairs(data.cosmetics) do
        table.insert(lines, key .. "=" .. tostring(value))
    end
    
    return table.concat(lines, "\n")
end

-- Deserialize progression data from string
function Progression.deserialize(content)
    local data = {
        totalRuns = 0,
        totalWins = 0,
        totalDeaths = 0,
        totalKeysCollected = 0,
        totalMonstersKilled = 0,
        totalItemsCollected = 0,
        fastestTime = math.huge,
        unlocks = {},
        cosmetics = {}
    }
    
    local section = "stats"
    
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%[unlocks%]") then
            section = "unlocks"
        elseif line:match("^%[cosmetics%]") then
            section = "cosmetics"
        else
            local key, value = line:match("^(.+)=(.+)$")
            if key and value then
                if section == "stats" then
                    if key == "fastestTime" then
                        data[key] = tonumber(value) or math.huge
                    else
                        data[key] = tonumber(value) or 0
                    end
                elseif section == "unlocks" then
                    data.unlocks[key] = (value == "true")
                elseif section == "cosmetics" then
                    data.cosmetics[key] = value
                end
            end
        end
    end
    
    return data
end

-- Record a completed run
function Progression.recordRun(won, deaths, keysCollected, monstersKilled, itemsCollected, timeTaken)
    Progression.data.totalRuns = Progression.data.totalRuns + 1
    Progression.data.totalDeaths = Progression.data.totalDeaths + deaths
    Progression.data.totalKeysCollected = Progression.data.totalKeysCollected + keysCollected
    Progression.data.totalMonstersKilled = Progression.data.totalMonstersKilled + monstersKilled
    Progression.data.totalItemsCollected = Progression.data.totalItemsCollected + itemsCollected
    
    if won then
        Progression.data.totalWins = Progression.data.totalWins + 1
        
        -- Track fastest time
        if timeTaken < Progression.data.fastestTime then
            Progression.data.fastestTime = timeTaken
            print("[Progression] New fastest time: " .. math.floor(timeTaken) .. "s!")
        end
    end
    
    -- Check for new unlocks
    Progression.checkUnlocks()
    
    -- Save after each run
    Progression.save()
end

-- Check if new unlocks are available
function Progression.checkUnlocks()
    local newUnlocks = {}
    
    -- Speed boost unlock (5 runs)
    if Progression.data.totalRuns >= 5 and not Progression.data.unlocks.speedBoostStart then
        Progression.data.unlocks.speedBoostStart = true
        table.insert(newUnlocks, "Speed Boost Start (+50 speed)")
    end
    
    -- Invincibility start (10 runs)
    if Progression.data.totalRuns >= 10 and not Progression.data.unlocks.invincibilityStart then
        Progression.data.unlocks.invincibilityStart = true
        table.insert(newUnlocks, "Invincibility Start (3s protection)")
    end
    
    -- Extra inventory slot (15 runs)
    if Progression.data.totalRuns >= 15 and not Progression.data.unlocks.extraInventorySlot then
        Progression.data.unlocks.extraInventorySlot = true
        table.insert(newUnlocks, "Extra Inventory Slot (4 items)")
    end
    
    -- Ghost slow start (20 runs)
    if Progression.data.totalRuns >= 20 and not Progression.data.unlocks.ghostSlowStart then
        Progression.data.unlocks.ghostSlowStart = true
        table.insert(newUnlocks, "Ghost Slow Start (enemies move slower)")
    end
    
    -- Map reveal (3 wins)
    if Progression.data.totalWins >= 3 and not Progression.data.unlocks.mapReveal then
        Progression.data.unlocks.mapReveal = true
        table.insert(newUnlocks, "Map Reveal (larger vision radius)")
    end
    
    -- Combat master (5 wins)
    if Progression.data.totalWins >= 5 and not Progression.data.unlocks.combatMaster then
        Progression.data.unlocks.combatMaster = true
        table.insert(newUnlocks, "Combat Master (2 damage per hit)")
    end
    
    -- Speed runner (sub-2min run)
    if Progression.data.fastestTime < 120 and not Progression.data.unlocks.speedRunner then
        Progression.data.unlocks.speedRunner = true
        table.insert(newUnlocks, "Speed Runner (+100 base speed)")
    end
    
    -- Survivor (50 deaths)
    if Progression.data.totalDeaths >= 50 and not Progression.data.unlocks.survivor then
        Progression.data.unlocks.survivor = true
        table.insert(newUnlocks, "Survivor (extra life - respawn once)")
    end
    
    return newUnlocks
end

-- Apply unlocks to game start
function Progression.applyStartingUnlocks(world, effects)
    local unlocks = Progression.data.unlocks
    
    -- Speed boost
    if unlocks.speedBoostStart then
        world.player.speed = world.player.speed + 50
        print("[Progression] Applied: Speed Boost Start")
    end
    
    -- Invincibility
    if unlocks.invincibilityStart then
        effects.invincibility = true
        effects.invincibilityTimer = 3.0
        print("[Progression] Applied: Invincibility Start")
    end
    
    -- Ghost slow
    if unlocks.ghostSlowStart then
        effects.ghostSlow = true
        effects.ghostSlowTimer = 15.0  -- 15 seconds at start
        print("[Progression] Applied: Ghost Slow Start")
    end
    
    -- Speed runner
    if unlocks.speedRunner then
        world.player.speed = world.player.speed + 100
        print("[Progression] Applied: Speed Runner")
    end
    
    -- Map reveal (increase vision radius)
    if unlocks.mapReveal then
        CONFIG.VISION_RADIUS = CONFIG.VISION_RADIUS + 3
        print("[Progression] Applied: Map Reveal")
    end
end

-- Get unlock requirements text
function Progression.getUnlockRequirements()
    local reqs = {}
    table.insert(reqs, string.format("Speed Boost Start: %d/5 runs", math.min(Progression.data.totalRuns, 5)))
    table.insert(reqs, string.format("Invincibility Start: %d/10 runs", math.min(Progression.data.totalRuns, 10)))
    table.insert(reqs, string.format("Extra Inventory: %d/15 runs", math.min(Progression.data.totalRuns, 15)))
    table.insert(reqs, string.format("Ghost Slow Start: %d/20 runs", math.min(Progression.data.totalRuns, 20)))
    table.insert(reqs, string.format("Map Reveal: %d/3 wins", math.min(Progression.data.totalWins, 3)))
    table.insert(reqs, string.format("Combat Master: %d/5 wins", math.min(Progression.data.totalWins, 5)))
    table.insert(reqs, string.format("Speed Runner: Best time %.1fs (need <120s)", Progression.data.fastestTime))
    table.insert(reqs, string.format("Survivor: %d/50 deaths", math.min(Progression.data.totalDeaths, 50)))
    return reqs
end

return Progression
