-- ---------- PRESETS ----------

-- local inspect = require("inspect")
local CONFIG = require("config")

-- Modular imports
local Utils = require("modules/utils")
local AI = require("modules/ai")
local Effects = require("modules/effects")
local UI = require("modules/ui")
local Animation = require("modules/animation")
local Audio = require("modules/audio")
local Combat = require("modules/combat")
local ProcGen = require("modules/procgen")
local Accessibility = require("modules/accessibility")
local Hazards = require("modules/hazards")
local Events = require("modules/events")

local currentMode = "titleScreen"
local difficultyMenuSelection = 2 -- 1=easy, 2=normal, 3=hard, 4=nightmare
local pauseMenuSelection = 1 -- 1=resume, 2=restart, 3=quit

local elapsedTime = 0
local debugMode = false
local godMode = false
local minimapEnabled = CONFIG.MINIMAP_ENABLED
local dailyChallengeEnabled = CONFIG.DAILY_CHALLENGE_ENABLED
local timeAttackEnabled = CONFIG.TIME_ATTACK_MODE
local currentSeed = nil  -- Track the seed being used
local profilingEnabled = CONFIG.PROFILING_ENABLED

-- Time Attack tracking
local timeAttack = {
    enabled = false,
    gameStartTime = 0,
    elapsedGameTime = 0,
    parTime = 0,
    itemBonus = 0,
    lastSpeedIncrease = 0,  -- Track when we last increased speed
}

-- Performance profiling data
local profiling = {
    frameHistory = {},
    updateTimeHistory = {},
    drawTimeHistory = {},
    memoryHistory = {},
    updateTimer = 0,
    currentUpdateTime = 0,
    currentDrawTime = 0,
    avgFPS = 0,
    avgUpdateTime = 0,
    avgDrawTime = 0,
    avgMemory = 0,
    minFPS = 999,
    maxFPS = 0,
}

-- Player last movement for attack direction
local lastMoveX = 0
local lastMoveY = 1  -- Default facing down

-- Item effects tracking
local activeEffects = {
    invincibility = false,
    invincibilityTimer = 0,
    mapReveal = false,
    mapRevealTimer = 0,
    ghostSlow = false,
    ghostSlowTimer = 0,
}

local stats = {
    startTime = 0,
    finishTime = 0,
    roomsVisited = {},
    keysCollected = 0,
    deaths = 0,
    itemsUsed = 0,
}

-- Fog of War tracking
local visibilityMap = {} -- tracks which tiles have been seen
local currentVisibleTiles = {} -- currently visible tiles

-- Screen shake
local screenShake = {
    active = false,
    duration = 0,
    intensity = 0,
    offsetX = 0,
    offsetY = 0,
}

-- Particle systems
local particleSystems = {
    key = nil,
    item = nil,
    death = nil,
    door = nil,
}

local activeParticles = {} -- Track active particle emitters

local world = {

    player = {
        coord = {0,0},
        speed = CONFIG.PLAYER_SPEED,
        keyCount = 0,
        currRoom = "1",
        overallKeyCount = 0,
        alive = true,
        inventory = {},  -- Holds items (max 3)
    }, 

    monster = {
        coord = {},
        speed = CONFIG.MONSTER_SPEED,
        aiTypes = {}, -- stores AI type for each monster (1=chase, 2=patrol)
        patrolPoints = {}, -- stores patrol waypoints for patrol-type monsters
        currentWaypoint = {}, -- current waypoint index for each patrol monster
    },

    wall = {
        coord = {},
    },

    item = {
        coord = {},
        buffSpeed = CONFIG.PLAYER_SPEED_BUFF,
    },

    key = {
        coord = {},
        totalCount = 0,
        globalCount = 0,
    },

    door = {
        coord = {},
    }

}

-- ---------- GENERAL ----------

function rstrip(str)
    if #str > 0 and str:sub(#str) == "\n" then
        return str:sub(1, #str - 1)
    else
        return str
    end
end

function inside(targetCoord, tbl)
    for _, coord in ipairs(tbl) do
        if targetCoord[1] == coord[1] and targetCoord[2] == coord[2] then
            return true
        end 
    end
    return false
end

function removeByValue(targetValue, tbl)
    for i, value in ipairs(tbl) do
        if value[1] == targetValue[1] and value[2] == targetValue[2] then
            table.remove(tbl, i)
        end
    end
end

function split(str, delimiter)
    local fin = {}
    local tem = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == delimiter then
            table.insert(fin,tem)
            tem = ""
        else
            tem = tem .. char
        end
    end
    tem = tem:gsub("\r$", "")
    table.insert(fin,tem)
    return fin
end

function shallowCopy(og) 
    local fin = {}
    for key, value in ipairs(og) do
        fin[key] = value
    end
    return fin
end

-- ---------- PROCEDURAL GENERATION ----------

function generateProceduralMap()
    -- Use procedural generation to create map layout
    local mapWidth = math.floor(CONFIG.MAP_WIDTH / CONFIG.TILE_SIZE)
    local mapHeight = math.floor(CONFIG.MAP_HEIGHT / CONFIG.TILE_SIZE)
    
    local grid, rooms
    if CONFIG.PROCGEN_ALGORITHM == "cave" then
        grid = ProcGen.generateCaveLayout(
            mapWidth, 
            mapHeight, 
            CONFIG.PROCGEN_CAVE_FILL_PERCENT, 
            CONFIG.PROCGEN_CAVE_SMOOTH_ITERATIONS
        )
    else -- BSP by default
        grid, rooms = ProcGen.generateRoomLayout(
            mapWidth, 
            mapHeight, 
            CONFIG.PROCGEN_MIN_ROOM_SIZE, 
            CONFIG.PROCGEN_MAX_ROOM_SIZE
        )
    end
    
    -- Clear existing world data
    world.wall.coord = {}
    world.door.coord = {}
    world.monster.coord = {}
    world.item.coord = {}
    world.key.coord = {}
    
    -- Convert grid to world coordinates
    for y = 1, #grid do
        for x = 1, #grid[y] do
            local worldX = (x - 1) * CONFIG.TILE_SIZE
            local worldY = (y - 1) * CONFIG.TILE_SIZE
            
            if grid[y][x] == 1 then
                -- Wall
                table.insert(world.wall.coord, {worldX, worldY})
            end
        end
    end
    
    -- Determine entity counts based on difficulty
    local difficulty = CONFIG.DIFFICULTY_SETTINGS[CONFIG.DIFFICULTY]
    local entityCounts = {
        monsters = math.random(CONFIG.MIN_ROOMS * 2, CONFIG.MAX_ROOMS * 2),
        keys = math.random(CONFIG.MIN_ROOMS, CONFIG.MAX_ROOMS),
        items = math.floor(math.random(CONFIG.MIN_ROOMS, CONFIG.MAX_ROOMS) * difficulty.itemSpawnMultiplier)
    }
    
    -- Place entities using procedural generation
    local entities = ProcGen.placeEntities(grid, entityCounts)
    
    -- Set player start position
    if entities.playerStart then
        world.player.coord[1] = entities.playerStart[1]
        world.player.coord[2] = entities.playerStart[2]
    end
    
    -- Place monsters
    for _, pos in ipairs(entities.monsters) do
        table.insert(world.monster.coord, {pos[1], pos[2]})
    end
    
    -- Place keys
    for _, pos in ipairs(entities.keys) do
        table.insert(world.key.coord, {pos[1], pos[2]})
    end
    world.key.globalCount = #entities.keys
    
    -- Place items
    for _, pos in ipairs(entities.items) do
        table.insert(world.item.coord, {pos[1], pos[2]})
    end
    
    -- Initialize visibility for fog of war
    if CONFIG.FOG_ENABLED then
        Utils.initVisibility(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT, CONFIG.TILE_SIZE)
    end
end

-- Update performance profiling
function updateProfiling(dt, updateTime, drawTime)
    if not profilingEnabled then
        return
    end
    
    -- Update timer
    profiling.updateTimer = profiling.updateTimer + dt
    
    -- Collect current frame data
    local currentFPS = love.timer.getFPS()
    local currentMemory = collectgarbage("count") / 1024  -- Convert to MB
    
    -- Add to history
    table.insert(profiling.frameHistory, currentFPS)
    table.insert(profiling.updateTimeHistory, updateTime * 1000)  -- Convert to ms
    table.insert(profiling.drawTimeHistory, drawTime * 1000)  -- Convert to ms
    table.insert(profiling.memoryHistory, currentMemory)
    
    -- Limit history size
    if #profiling.frameHistory > CONFIG.PROFILING_HISTORY_SIZE then
        table.remove(profiling.frameHistory, 1)
        table.remove(profiling.updateTimeHistory, 1)
        table.remove(profiling.drawTimeHistory, 1)
        table.remove(profiling.memoryHistory, 1)
    end
    
    -- Update statistics periodically
    if profiling.updateTimer >= CONFIG.PROFILING_UPDATE_INTERVAL then
        profiling.updateTimer = 0
        
        -- Calculate averages
        local fpsSum, updateSum, drawSum, memSum = 0, 0, 0, 0
        profiling.minFPS = 999
        profiling.maxFPS = 0
        
        for i = 1, #profiling.frameHistory do
            fpsSum = fpsSum + profiling.frameHistory[i]
            updateSum = updateSum + profiling.updateTimeHistory[i]
            drawSum = drawSum + profiling.drawTimeHistory[i]
            memSum = memSum + profiling.memoryHistory[i]
            
            if profiling.frameHistory[i] < profiling.minFPS then
                profiling.minFPS = profiling.frameHistory[i]
            end
            if profiling.frameHistory[i] > profiling.maxFPS then
                profiling.maxFPS = profiling.frameHistory[i]
            end
        end
        
        local count = #profiling.frameHistory
        if count > 0 then
            profiling.avgFPS = fpsSum / count
            profiling.avgUpdateTime = updateSum / count
            profiling.avgDrawTime = drawSum / count
            profiling.avgMemory = memSum / count
        end
    end
end

function drawProfilingOverlay()
    if not profilingEnabled then
        return
    end
    
    -- Draw background panel
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", CONFIG.WINDOW_WIDTH - 310, 10, 300, 250)
    
    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", CONFIG.WINDOW_WIDTH - 310, 10, 300, 250)
    
    -- Draw profiling data
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(AmaticFont25)
    love.graphics.print("PERFORMANCE PROFILER (F6)", CONFIG.WINDOW_WIDTH - 305, 15)
    
    local y = 45
    love.graphics.print(string.format("FPS: %d (avg: %.1f)", love.timer.getFPS(), profiling.avgFPS), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    love.graphics.print(string.format("  Min: %d  Max: %d", profiling.minFPS, profiling.maxFPS), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    
    love.graphics.print(string.format("Frame Time: %.2f ms", profiling.avgUpdateTime + profiling.avgDrawTime), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    love.graphics.print(string.format("  Update: %.2f ms", profiling.avgUpdateTime), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    love.graphics.print(string.format("  Draw: %.2f ms", profiling.avgDrawTime), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    
    love.graphics.print(string.format("Memory: %.2f MB", profiling.avgMemory), CONFIG.WINDOW_WIDTH - 305, y)
    y = y + 25
    
    -- Entity counts
    if currentMode == "gameScreen" and world then
        love.graphics.print(string.format("Entities:"), CONFIG.WINDOW_WIDTH - 305, y)
        y = y + 25
        love.graphics.print(string.format("  Monsters: %d", #world.monster.coord), CONFIG.WINDOW_WIDTH - 305, y)
        y = y + 25
        love.graphics.print(string.format("  Items: %d  Keys: %d", #world.item.coord, #world.key.coord), CONFIG.WINDOW_WIDTH - 305, y)
    end
end

-- Inventory management functions
function addItemToInventory(item)
    if #world.player.inventory < CONFIG.INVENTORY_SIZE then
        table.insert(world.player.inventory, item)
        print("Added item to inventory slot " .. #world.player.inventory)
        return true
    else
        print("Inventory full! Use an item first.")
        return false
    end
end

function useInventoryItem(slotNumber)
    if world.player.inventory[slotNumber] then
        local item = world.player.inventory[slotNumber]
        print("Using item from slot " .. slotNumber)
        
        -- Apply the item's stored effect
        if item.effect == "speedBoost" then
            world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF
        elseif item.effect == "speedReduction" then
            world.player.speed = math.max(100, world.player.speed - 100)
        elseif item.effect == "ghostSlow" then
            activeEffects.ghostSlow = true
            activeEffects.ghostSlowTimer = CONFIG.PLAYER_SPEED_BUFF_DURATION
        elseif item.effect == "invincibility" then
            activeEffects.invincibility = true
            activeEffects.invincibilityTimer = CONFIG.INVINCIBILITY_DURATION
        elseif item.effect == "mapReveal" then
            activeEffects.mapReveal = true
            activeEffects.mapRevealTimer = CONFIG.MAP_REVEAL_DURATION
            for y = 0, CONFIG.MAP_HEIGHT, CONFIG.TILE_SIZE do
                for x = 0, CONFIG.MAP_WIDTH, CONFIG.TILE_SIZE do
                    local key = x .. "," .. y
                    currentVisibleTiles[key] = true
                end
            end
        elseif item.effect == "megaSpeed" then
            world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF * 2
        end
        
        -- Remove item from inventory
        table.remove(world.player.inventory, slotNumber)
        stats.itemsUsed = stats.itemsUsed + 1
        
        return true
    else
        print("No item in slot " .. slotNumber)
        return false
    end
end

-- ---------- UTILITY ----------

function randomiseMap(fileName) -- generates map layouts which are applied on layout.txt before generating the map

    while true do

        -- Use current seed (already set by Utils.setGameSeed)
        local fhand = io.open(fileName, "w")
        local fin = ""
        local tem = {}
        
        while true do

            if #tem > 8 then -- max 9 rooms
                break
            end
            local i = math.random(1, 36)
            if i > 15 then
                table.insert(tem, ".")
            else
                local found = false
                for _, el in ipairs(tem) do
                    if el == i then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(tem, i)
                end
            end
        end
        
        for i, val in ipairs(tem) do
            if i % 3 == 0 or i == #tem then
                fin = fin .. val .. "\n"
            else
                fin = fin .. val .. "|"
            end
        end
        
        fhand:write(fin)
        fhand:close()

        local temMap = generateMap(fileName)
        local validGen = true

        for _, el in ipairs(temMap) do
            if #temMap <= 2 or #el[2] == 0 or horiVertDiagCheck(fileName) then
                validGen = false
                break
            else
            end
        end

        if validGen then
            break
        end

    end
end

function horiVertDiagCheck(fileName)
    local tem = {}
    local fhand = io.open(fileName, "r")
    if fhand then 
        for line in fhand:lines() do
            table.insert(tem, split(line, "|"))
        end
    else
        print("error, unable to open local map file")
    end 
    fhand:close()
    return tem[1][2] == "." and tem[2][2] == "." and tem[3][2] == "." or tem[2][1] == "." and tem[2][2] == "." and tem[2][3] == "." or tem[1][3] == "." and tem[2][2] == "." and tem[3][1] == "." or tem[1][1] == "." and tem[2][2] == "." and tem[3][3] == "." 
end

-- writes the map data to a txt file
function serialize(fileName) 
    local fhand = io.open(fileName, "w")
    local fin = ""
    for y = 0, 580, 20 do
        local tem = ""
        for x = 0, 580, 20 do
            if #world.wall.coord ~= 0 and inside({x,y}, world.wall.coord) then
                tem = tem .. "#"
            elseif #world.door.coord ~= 0 and inside({x,y}, world.door.coord) then
                tem = tem .. "D"
            elseif #world.monster.coord ~= 0 and inside({x,y}, world.monster.coord) then
                tem = tem .. "!"
            elseif #world.item.coord ~= 0 and inside({x,y}, world.item.coord) then
                tem = tem .. "?"
            elseif #world.key.coord ~= 0 and inside({x,y}, world.key.coord) then
                tem = tem .. "$"
            else
                tem = tem .. "."
            end
        end
        fin = fin .. tem .. "\n"
    end
    if fhand then
        fhand:write(rstrip(fin))
        fhand:close()
    else
        print("error, unable to open local map file")
    end
end

-- reads txt file to map data
function deserialize(fileName)
    local fhand = io.open(fileName, "r")
    if fhand then 
        local data = fhand:read("*all")
        fhand:close()
        local x = 0
        local y = 0
        for line in data:gmatch("[^\r\n]+") do
            for char in line:gmatch("(.)") do
                if char == "#" then
                    table.insert(world.wall.coord, {x * 20, y * 20})
                elseif char == "D" then
                    table.insert(world.door.coord, {x * 20, y * 20})
                elseif char == "?" then 
                    table.insert(world.item.coord, {x * 20, y * 20})
                elseif char == "$" then 
                    table.insert(world.key.coord, {x * 20, y * 20})
                    world.key.totalCount = world.key.totalCount + 1
                elseif char == "!" then
                    table.insert(world.monster.coord, {x * 20, y * 20})
                elseif char == "@" then
                    world.player.coord = {x * 20, y * 20}
                elseif char == "^" then
                    Hazards.addSpike(x * 20, y * 20)
                elseif char == "P" then
                    Hazards.addPressurePlate(x * 20, y * 20)
                elseif char == "T" then
                    Hazards.activateTimedRoom()
                end
                x = x + 1
            end 
            x = 0
            y = y + 1
        end
        -- return inspect(world)
    else
        print("error, unable to open local map file")
    end 
end

-- resets table data except current room since that one needs to continue being tracked
function reset(tbl)
    tbl.player.coord = {0,0}
    tbl.player.speed = CONFIG.PLAYER_SPEED
    tbl.player.keyCount = 0
    tbl.player.alive = true
    tbl.monster.coord = {}
    tbl.monster.speed = CONFIG.MONSTER_SPEED
    tbl.monster.aiTypes = {}
    tbl.monster.patrolPoints = {}
    tbl.monster.currentWaypoint = {}
    tbl.wall.coord = {}
    tbl.item.coord = {}
    tbl.item.buffSpeed = CONFIG.PLAYER_SPEED_BUFF
    tbl.key.coord = {}
    tbl.key.totalCount = 0
    tbl.door.coord = {}
    Hazards.init()  -- Reset hazards when changing rooms
    return tbl
end

function checkCollision(ACoord, BCoord)
    return ACoord[1] + CONFIG.TILE_SIZE > BCoord[1] and ACoord[2] + CONFIG.TILE_SIZE > BCoord[2] and BCoord[1] + CONFIG.TILE_SIZE > ACoord[1] and BCoord[2] + CONFIG.TILE_SIZE > ACoord[2]
end

function checkPlayerOutBounds(playerCoord)
    return playerCoord[1] < 0 or playerCoord[1] > CONFIG.MAP_WIDTH or playerCoord[2] < 0 or playerCoord[2] > CONFIG.MAP_HEIGHT
end

--[[ 
    1
2 center 3
    4
]]--

function checkPlayerRoom(playerCoord)
    if playerCoord[1] < 0 then
        return {2, {580,290}}
    elseif playerCoord[1] > 600 then
        return {3, {0,290}}
    elseif playerCoord[2] < 0 then 
        return {1, {290,580}}
    elseif playerCoord[2] > 600 then
        return {4, {290,0}}
    end
end

-- remove doors at a specific location
function removeDoors(playerCurrRoom)
    if playerLoc[1] == 1 then -- door 4
        removeByValue({280,580},doors.coord)
        removeByValue({300,580},doors.coord)
    elseif playerLoc[1] == 2 then -- door 3
        removeByValue({580,280},doors.coord)
        removeByValue({580,300},doors.coord)
    elseif playerLoc[1] == 3 then -- door 2
        removeByValue({0,280},doors.coord)
        removeByValue({0,300},doors.coord)
    elseif playerLoc[1] == 4 then -- door 1
        removeByValue({280,0},doors.coord)
        removeByValue({300,0},doors.coord)
    end
end

--[[
            Room1
              ^
Room2 <-> currentRoom <-> Room3
              v 
            Room4
]]--

-- returns a nested table of the following syntax {currentRoomName, {Room1: RoomNameOfRoom}} based off the layout map file
function generateMap(fileName)
    local fhand = io.open(fileName, "r")
    local fin = {}
    local tem = {}
    if fhand then 
        for line in fhand:lines() do
            table.insert(tem, split(line, "|"))
            -- print(inspect(tem))
        end
    else
        print("error, unable to open local map file")
    end 
    for i,iel in ipairs(tem) do
        for q,qel in ipairs(tem[i]) do
            -- print(tem[i][q])
            eachRoom = {}
            if tem[i][q] ~= "." then
                if q ~= 1 then
                    if tem[i][q-1] ~= "." then
                        table.insert(eachRoom,{2,tem[i][q-1]})
                    end
                end
                if q ~= #tem[i] then
                    if tem[i][q+1] ~= "." then 
                        table.insert(eachRoom,{3,tem[i][q+1]})
                    end
                end
                if i ~= 1 then
                    if tem[i-1][q] ~= "." then
                        table.insert(eachRoom,{1,tem[i-1][q]})
                    end
                end
                if i ~= #tem then
                    if tem[i+1][q] ~= "." then
                        table.insert(eachRoom,{4,tem[i+1][q]})
                    end
                end
                table.insert(fin,{tem[i][q],eachRoom})
            end
        end
    end
    fhand:close()
    return fin
end

function checkNextRoom(aMap, currRoom, currDoor)
    for _, el in ipairs(aMap) do
        -- print(inspect(el))
        if el[1] == currRoom then
            -- print(inspect(el[1]))
            for _, val in ipairs(el[2]) do
                -- print(inspect(val))
                if val[1] == currDoor then
                    -- print(inspect(val[1]))
                    return val[2]
                end
            end
        end
    end
end

function extractDoors(aMap, currRoom)
    local tem = {}
    local fin = {}
    for _, el in ipairs(aMap) do
        if el[1] == currRoom then
            for _, val in ipairs(el[2]) do
                table.insert(tem, val[1])
            end
        end
    end
    for _, q in ipairs(tem) do
        if q == 4 then -- door 4
            table.insert(fin,{280,580})
            table.insert(fin,{300,580})
        elseif q == 3 then -- door 3
            table.insert(fin,{580,280})
            table.insert(fin,{580,300})
        elseif q == 2 then -- door 2
            table.insert(fin,{0,280})
            table.insert(fin,{0,300})
        elseif q == 1 then -- door 1
            table.insert(fin,{280,0})
            table.insert(fin,{300,0})
        end
    end
    return fin
end

function addDoorAsWall(map,doorList)
    fin = {}
    for i,doorCoord in ipairs(map.door.coord) do
        local found = false
        for q,presentDoorCoord in ipairs(doorList) do
            if doorCoord[1] == presentDoorCoord[1] and doorCoord[2] == presentDoorCoord[2] then
                found = true
                break
            end
        end
        if not found then 
            table.insert(fin, doorCoord)
        end
    end
    for _, doorAsWallCoord in ipairs(fin) do
        table.insert(map.wall.coord, doorAsWallCoord)
    end
end

function totalKeys() 
    total = 0
    for _, el in ipairs(worldMap) do
        -- print(inspect(el[1]))
        local fhand = io.open(string.format("map/%s.txt",el[1]), "r")
        if fhand then 
            for line in fhand:lines() do
                for i = 1, #line, 1 do
                    local char = line:sub(i,i)
                    if char == "$" then
                        total = total + 1
                    end
                end
            end
            fhand:close()
        else
            print("specified file cannot be opened")
        end 
    end
    return total
end

function startingRoom(worldMap)
    -- Don't reseed here - use existing seed
    local tem = {}
    for _,el in ipairs(worldMap) do
        table.insert(tem,el)
    end
    return tem[math.random(1,#tem)][1]
end

function startingCoord(roomNumber, map)
    -- Don't reseed here - use existing seed
    genX = math.random(2,28)
    genY = math.random(2,28)

    fhand = io.open(string.format("map/%s.txt", roomNumber))
    if fhand then 
        local data = fhand:read("*all")
        fhand:close()
        local x = 0
        local y = 0
        for line in data:gmatch("[^\r\n]+") do
            for char in line:gmatch("(.)") do
                if genX == x and genY == y and char == "." then
                    return {true, {genX * 20, genY * 20}}
                end
                x = x + 1
            end 
            x = 0
            y = y + 1
        end
        return {false}
    else
        print("local map file cannot be opened")
    end
    fhand:close()
end

function validStartingRoomAndCoord(worldMap)
    while true do 
        startingRm = startingRoom(worldMap)
        startingCoordSet = startingCoord(startingRm)
        if startingCoordSet[1] then
            startingCoord = startingCoordSet[2]
            return {startingRm, startingCoord}
        end
    end
end

function randomFloor(worldMap)
    -- Don't reseed here - use existing seed
    fin = {}
    for _, el in ipairs(worldMap) do
        tem = {}
        for y = 20, 580, 20 do
            for x = 20, 580, 20 do
                local i = math.random(1, 2)
                if i == 1 then 
                    table.insert(tem,{{x,y},1})
                elseif i == 2 then
                    table.insert(tem,{{x,y},2})
                end
            end
        end
        table.insert(fin,{el[1], tem})
    end
    return fin
end

function randomWall(worldMap)
    -- Don't reseed here - use existing seed
    fin = {}
    for _, el in ipairs(worldMap) do
        tem = {}
        for y = 20, 580, 20 do
            for x = 20, 580, 20 do
                local i = math.random(1, 3)
                if i == 1 then 
                    table.insert(tem,{{x,y},1})
                elseif i == 2 then
                    table.insert(tem,{{x,y},2})
                elseif i == 3 then
                    table.insert(tem,{{x,y},3})
                end
            end
        end
        table.insert(fin,{el[1], tem})
    end
    return fin
end

-- aggregates every other pixel to create a pixellated shader texture
local pixelateShaderCode = [[
    extern float pixelSize;

    vec2 pixelate(vec2 uv, float pixelSize) {
        return floor(uv / pixelSize) * pixelSize;
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelatedCoords = pixelate(texture_coords, pixelSize);
        vec4 pixel = Texel(texture, pixelatedCoords);
        return color * pixel;
    }
]]

function assertTwenty(num)
    if num % 20 == 0 then
        return num
    else
        local fin = math.floor(num/20) * 20 + 20
        return fin
    end
end

function sanitiseMonsterCoord(earth)

    -- Don't reseed here - use existing seed

    fin = {}

    for _,monsterCoord in ipairs(earth.monster.coord) do

        i = math.random(1,2)
        newMonsterCoord = {assertTwenty(monsterCoord[1]), assertTwenty(monsterCoord[2])}

        -- overlap check
        while inside(newMonsterCoord,earth.wall.coord) do
            if i == 1 then
                newMonsterCoord[1] = newMonsterCoord[1] + 20
            elseif i == 2 then
                newMonsterCoord[2] = newMonsterCoord[2] + 20
            end
        end

        while inside(newMonsterCoord,earth.key.coord) do
            if i == 1 then
                newMonsterCoord[2] = newMonsterCoord[2] + 20
            elseif i == 2 then
                newMonsterCoord[1] = newMonsterCoord[1] + 20
            end
        end

        while inside(newMonsterCoord,earth.item.coord) do
            if i == 1 then
                newMonsterCoord[1] = newMonsterCoord[1] + 20
            elseif i == 2 then
                newMonsterCoord[2] = newMonsterCoord[2] + 20
            end
        end

        while inside(newMonsterCoord,earth.wall.coord) do
            if i == 1 then
                newMonsterCoord[1] = newMonsterCoord[1] + 20
            elseif i == 2 then
                newMonsterCoord[2] = newMonsterCoord[2] + 20
            end
        end

        while inside(newMonsterCoord,fin) do
            if i == 1 then
                newMonsterCoord[1] = newMonsterCoord[1] + 20
            elseif i == 2 then
                newMonsterCoord[2] = newMonsterCoord[2] + 20
            end
        end

        -- bounds check
        if newMonsterCoord[1] < 20 then 
            newMonsterCoord[1] = newMonsterCoord[1] + 20
        end
        if newMonsterCoord[2] < 20 then
            newMonsterCoord[2] = newMonsterCoord[2] + 20
        end
        if newMonsterCoord[1] > 580 then
            newMonsterCoord[1] = newMonsterCoord[1] - 20
        end
        if newMonsterCoord[2] > 580 then
            newMonsterCoord[2] = newMonsterCoord[2] - 20
        end

        table.insert(fin,newMonsterCoord)
    end
    earth.monster.coord = fin
    -- print("save these monster coords" .. inspect(fin))
end

function manhattanDistance(playerCoord, monsterCoord)
    return math.abs(monsterCoord[1] - playerCoord[1]) + math.abs(monsterCoord[2] - playerCoord[2])
end

function ghostProxCheck(playerCoord, monsterCoords)
    local tem = {}
    for _, monsterCoord in ipairs(monsterCoords) do
        table.insert(tem, manhattanDistance(player.coord, monsterCoord))
    end
    for _, val in ipairs(tem) do
        if val <= CONFIG.GHOST_PROXIMITY_THRESHOLD then
            return true
        end
    end
    return false
end

-- Fog of War helper functions
function updateVisibility(playerCoord)
    currentVisibleTiles = {}
    local playerTileX = math.floor(playerCoord[1] / CONFIG.TILE_SIZE)
    local playerTileY = math.floor(playerCoord[2] / CONFIG.TILE_SIZE)
    
    for dy = -CONFIG.VISION_RADIUS, CONFIG.VISION_RADIUS do
        for dx = -CONFIG.VISION_RADIUS, CONFIG.VISION_RADIUS do
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= CONFIG.VISION_RADIUS then
                local tileX = playerTileX + dx
                local tileY = playerTileY + dy
                local worldX = tileX * CONFIG.TILE_SIZE
                local worldY = tileY * CONFIG.TILE_SIZE
                
                if worldX >= 0 and worldX < CONFIG.MAP_WIDTH and worldY >= 0 and worldY < CONFIG.MAP_HEIGHT then
                    local key = worldX .. "," .. worldY
                    currentVisibleTiles[key] = true
                    
                    if CONFIG.SHOW_VISITED then
                        visibilityMap[key] = true
                    end
                end
            end
        end
    end
end

function isVisible(x, y)
    if not CONFIG.FOG_ENABLED then
        return true
    end
    local key = x .. "," .. y
    return currentVisibleTiles[key] ~= nil
end

function hasBeenVisited(x, y)
    if not CONFIG.FOG_ENABLED or not CONFIG.SHOW_VISITED then
        return false
    end
    local key = x .. "," .. y
    return visibilityMap[key] ~= nil and currentVisibleTiles[key] == nil
end

-- Screen shake functions
function startScreenShake(intensity, duration)
    if CONFIG.SCREEN_SHAKE_ENABLED then
        screenShake.active = true
        screenShake.intensity = intensity or CONFIG.SHAKE_INTENSITY
        screenShake.duration = duration or CONFIG.SHAKE_DURATION
    end
end

function updateScreenShake(dt)
    if screenShake.active then
        screenShake.duration = screenShake.duration - dt
        
        if screenShake.duration <= 0 then
            screenShake.active = false
            screenShake.offsetX = 0
            screenShake.offsetY = 0
        else
            -- Random shake offset
            screenShake.offsetX = (math.random() * 2 - 1) * screenShake.intensity
            screenShake.offsetY = (math.random() * 2 - 1) * screenShake.intensity
        end
    end
end

-- Particle system functions
function createParticleImage()
    -- Create a simple 2x2 white pixel image for particles
    local imageData = love.image.newImageData(2, 2)
    for x = 0, 1 do
        for y = 0, 1 do
            imageData:setPixel(x, y, 1, 1, 1, 1)
        end
    end
    return love.graphics.newImage(imageData)
end

function spawnParticles(x, y, particleType)
    if not CONFIG.PARTICLES_ENABLED then
        return
    end
    
    local ps = particleSystems[particleType]
    if ps then
        local emitter = {
            system = ps:clone(),
            x = x + CONFIG.TILE_SIZE / 2,
            y = y + CONFIG.TILE_SIZE / 2,
        }
        emitter.system:emit(CONFIG["PARTICLE_COUNT_" .. string.upper(particleType)] or 15)
        table.insert(activeParticles, emitter)
    end
end

function updateParticles(dt)
    for i = #activeParticles, 1, -1 do
        local emitter = activeParticles[i]
        emitter.system:update(dt)
        
        -- Remove dead particle systems
        if emitter.system:getCount() == 0 then
            table.remove(activeParticles, i)
        end
    end
end

function drawParticles()
    if CONFIG.PARTICLES_ENABLED then
        for _, emitter in ipairs(activeParticles) do
            love.graphics.draw(emitter.system, emitter.x, emitter.y)
        end
    end
end

-- Ghost AI functions
function initializeGhostAI()
    -- Assign AI types to ghosts based on their index
    for i, _ in ipairs(world.monster.coord) do
        -- Alternate between chase (1) and patrol (2) AI
        if i % 2 == 0 then
            world.monster.aiTypes[i] = 2 -- Patrol
            -- Create patrol waypoints
            local patrolRadius = 3
            world.monster.patrolPoints[i] = {
                {world.monster.coord[i][1] - patrolRadius * CONFIG.TILE_SIZE, world.monster.coord[i][2]},
                {world.monster.coord[i][1], world.monster.coord[i][2] - patrolRadius * CONFIG.TILE_SIZE},
                {world.monster.coord[i][1] + patrolRadius * CONFIG.TILE_SIZE, world.monster.coord[i][2]},
                {world.monster.coord[i][1], world.monster.coord[i][2] + patrolRadius * CONFIG.TILE_SIZE},
            }
            world.monster.currentWaypoint[i] = 1
        else
            world.monster.aiTypes[i] = 1 -- Chase
        end
    end
end

function moveGhostChase(monsterCoord, playerCoord, dt, speed)
    local xOffset = playerCoord[1] - monsterCoord[1]
    local yOffset = playerCoord[2] - monsterCoord[2]
    local angle = math.atan2(yOffset, xOffset)
    local dx = speed * math.cos(angle)
    local dy = speed * math.sin(angle)
    monsterCoord[1] = monsterCoord[1] + (dt * dx)
    monsterCoord[2] = monsterCoord[2] + (dt * dy)
end

function moveGhostPatrol(monsterIndex, dt, speed)
    local monsterCoord = world.monster.coord[monsterIndex]
    local waypoints = world.monster.patrolPoints[monsterIndex]
    local currentWP = world.monster.currentWaypoint[monsterIndex]
    
    if not waypoints or #waypoints == 0 then
        return
    end
    
    local targetWaypoint = waypoints[currentWP]
    local xOffset = targetWaypoint[1] - monsterCoord[1]
    local yOffset = targetWaypoint[2] - monsterCoord[2]
    local distance = math.sqrt(xOffset * xOffset + yOffset * yOffset)
    
    -- If close to waypoint, move to next one
    if distance < CONFIG.TILE_SIZE then
        world.monster.currentWaypoint[monsterIndex] = (currentWP % #waypoints) + 1
    else
        local angle = math.atan2(yOffset, xOffset)
        local dx = speed * 0.5 * math.cos(angle) -- Patrol slower than chase
        local dy = speed * 0.5 * math.sin(angle)
        monsterCoord[1] = monsterCoord[1] + (dt * dx)
        monsterCoord[2] = monsterCoord[2] + (dt * dy)
    end
end

-- Item effect functions
function applyRandomItemEffect()
    math.randomseed(os.time())
    local effect = math.random(1, 6)
    
    if effect == 1 then
        -- Speed boost (original behavior)
        world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF
        print("Item effect: Speed Boost!")
        return "Speed Boost!"
    elseif effect == 2 then
        -- Speed reduction (risk!)
        world.player.speed = math.max(100, world.player.speed - 100)
        print("Item effect: Speed Reduced!")
        return "Speed Reduced!"
    elseif effect == 3 then
        -- Slow ghosts
        activeEffects.ghostSlow = true
        activeEffects.ghostSlowTimer = CONFIG.PLAYER_SPEED_BUFF_DURATION
        print("Item effect: Ghosts Slowed!")
        return "Ghosts Slowed!"
    elseif effect == 4 then
        -- Temporary invincibility
        activeEffects.invincibility = true
        activeEffects.invincibilityTimer = CONFIG.INVINCIBILITY_DURATION
        print("Item effect: Invincibility!")
        return "Invincibility!"
    elseif effect == 5 then
        -- Map reveal pulse
        activeEffects.mapReveal = true
        activeEffects.mapRevealTimer = CONFIG.MAP_REVEAL_DURATION
        -- Reveal all tiles
        for y = 0, CONFIG.MAP_HEIGHT, CONFIG.TILE_SIZE do
            for x = 0, CONFIG.MAP_WIDTH, CONFIG.TILE_SIZE do
                local key = x .. "," .. y
                currentVisibleTiles[key] = true
            end
        end
        print("Item effect: Map Revealed!")
        return "Map Revealed!"
    else
        -- Double speed boost (rare!)
        world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF * 2
        print("Item effect: MEGA Speed Boost!")
        return "MEGA Speed Boost!"
    end
end

function updateItemEffects(dt)
    -- Update invincibility
    if activeEffects.invincibility then
        activeEffects.invincibilityTimer = activeEffects.invincibilityTimer - dt
        if activeEffects.invincibilityTimer <= 0 then
            activeEffects.invincibility = false
            activeEffects.invincibilityTimer = 0
            print("Invincibility wore off")
        end
    end
    
    -- Update map reveal
    if activeEffects.mapReveal then
        activeEffects.mapRevealTimer = activeEffects.mapRevealTimer - dt
        if activeEffects.mapRevealTimer <= 0 then
            activeEffects.mapReveal = false
            activeEffects.mapRevealTimer = 0
            -- Clear temporary reveals
            if CONFIG.FOG_ENABLED then
                currentVisibleTiles = {}
            end
            print("Map reveal wore off")
        end
    end
    
    -- Update ghost slow
    if activeEffects.ghostSlow then
        activeEffects.ghostSlowTimer = activeEffects.ghostSlowTimer - dt
        if activeEffects.ghostSlowTimer <= 0 then
            activeEffects.ghostSlow = false
            activeEffects.ghostSlowTimer = 0
            print("Ghost slow wore off")
        end
    end
end

-- FUA add and spruce up these screens
function drawTitleScreen()
    local text1 = "TIKRIT"
    local text2 = "Select Difficulty"
    local text3 = "Made by @gongahkia on Github in Love2D"
    local difficulties = {"Easy", "Normal", "Hard", "Nightmare"}
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(AmaticFont80)
    love.graphics.print("TIKRIT", (love.graphics.getWidth() - AmaticFont80:getWidth(text1))/2, 50)
    
    love.graphics.setFont(AmaticFont40)
    love.graphics.print("Select Difficulty", (love.graphics.getWidth() - AmaticFont40:getWidth(text2))/2, 150)
    
    -- Draw difficulty options
    for i, diff in ipairs(difficulties) do
        local y = 200 + (i * 50)
        if i == difficultyMenuSelection then
            love.graphics.setColor(1, 1, 0, 1)  -- Highlight selected
            love.graphics.print("> " .. diff .. " <", (love.graphics.getWidth() - AmaticFont40:getWidth("> " .. diff .. " <"))/2, y)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.print(diff, (love.graphics.getWidth() - AmaticFont40:getWidth(diff))/2, y)
        end
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(AmaticFont25)
    love.graphics.print("Use UP/DOWN arrows to select, ENTER to start", (love.graphics.getWidth() - AmaticFont25:getWidth("Use UP/DOWN arrows to select, ENTER to start"))/2, 500)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - AmaticFont25:getWidth(text3) - 10), (love.graphics.getHeight() - AmaticFont25:getHeight() - 10))
end

function drawLoseScreen()
    local text1 = "Try again next time!"
    local text2 = string.format("You collected %d out of %d keys.", world.player.overallKeyCount, world.key.globalCount)
    local text3 = "Made by @gongahkia on Github in Love2D"
    local roomCount = 0
    for _ in pairs(stats.roomsVisited) do roomCount = roomCount + 1 end
    local elapsedGameTime = math.floor(love.timer.getTime() - stats.startTime)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(AmaticFont80)
    love.graphics.print("Try again next time!", (love.graphics.getWidth() - AmaticFont80:getWidth(text1))/2, 80)
    love.graphics.setFont(AmaticFont40)
    love.graphics.print(string.format("You collected %d out of %d keys.", world.player.overallKeyCount, world.key.globalCount), (love.graphics.getWidth() - AmaticFont40:getWidth(text2))/2, 200)
    
    -- Display statistics
    love.graphics.setFont(AmaticFont25)
    local statsText = string.format("Time: %d seconds | Rooms: %d | Items: %d", elapsedGameTime, roomCount, stats.itemsUsed)
    love.graphics.print(statsText, (love.graphics.getWidth() - AmaticFont25:getWidth(statsText))/2, 260)
    love.graphics.print("Difficulty: " .. CONFIG.DIFFICULTY, (love.graphics.getWidth() - AmaticFont25:getWidth("Difficulty: " .. CONFIG.DIFFICULTY))/2, 290)
    
    love.graphics.setFont(AmaticFont25)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - AmaticFont25:getWidth(text3) - 10), (love.graphics.getHeight() - AmaticFont25:getHeight() - 10))
end

function drawWinScreen()
    local text1 = "You Win!"
    local text2 = string.format("You collected %d out of %d keys.", world.player.overallKeyCount, world.key.globalCount)
    local text3 = "Made by @gongahkia on Github in Love2D"
    local roomCount = 0
    for _ in pairs(stats.roomsVisited) do roomCount = roomCount + 1 end
    local elapsedGameTime = math.floor(love.timer.getTime() - stats.startTime)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(AmaticFont80)
    love.graphics.print("You Win!", (love.graphics.getWidth() - AmaticFont80:getWidth(text1))/2, 80)
    love.graphics.setFont(AmaticFont40)
    love.graphics.print(string.format("You collected all %d keys!", world.key.globalCount), (love.graphics.getWidth() - AmaticFont40:getWidth(string.format("You collected all %d keys!", world.key.globalCount)))/2, 200)
    
    -- Display statistics
    love.graphics.setFont(AmaticFont25)
    local statsText = string.format("Time: %d seconds | Rooms: %d | Items: %d | Deaths: %d", elapsedGameTime, roomCount, stats.itemsUsed, stats.deaths)
    love.graphics.print(statsText, (love.graphics.getWidth() - AmaticFont25:getWidth(statsText))/2, 260)
    love.graphics.print("Difficulty: " .. CONFIG.DIFFICULTY, (love.graphics.getWidth() - AmaticFont25:getWidth("Difficulty: " .. CONFIG.DIFFICULTY))/2, 290)
    
    -- Grade system
    local grade = "D"
    if stats.deaths == 0 and elapsedGameTime < 120 then grade = "S"
    elseif stats.deaths == 0 and elapsedGameTime < 180 then grade = "A"
    elseif stats.deaths <= 1 and elapsedGameTime < 240 then grade = "B"
    elseif stats.deaths <= 2 then grade = "C"
    end
    love.graphics.setFont(AmaticFont80)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("Grade: " .. grade, (love.graphics.getWidth() - AmaticFont80:getWidth("Grade: " .. grade))/2, 340)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(AmaticFont25)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - AmaticFont25:getWidth(text3) - 10), (love.graphics.getHeight() - AmaticFont25:getHeight() - 10))
end

function drawPauseScreen()
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(AmaticFont80)
    local titleText = "PAUSED"
    love.graphics.print(titleText, (love.graphics.getWidth() - AmaticFont80:getWidth(titleText))/2, 100)
    
    -- Menu options
    local options = {"Resume", "Restart", "Quit"}
    love.graphics.setFont(AmaticFont40)
    
    for i, option in ipairs(options) do
        local yPos = 250 + (i - 1) * 70
        if i == pauseMenuSelection then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("> " .. option .. " <", (love.graphics.getWidth() - AmaticFont40:getWidth("> " .. option .. " <"))/2, yPos)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.print(option, (love.graphics.getWidth() - AmaticFont40:getWidth(option))/2, yPos)
        end
    end
    
    love.graphics.setFont(AmaticFont25)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Use UP/DOWN to select, ENTER to confirm", (love.graphics.getWidth() - AmaticFont25:getWidth("Use UP/DOWN to select, ENTER to confirm"))/2, 500)
    love.graphics.print("Press P or ESC to resume", (love.graphics.getWidth() - AmaticFont25:getWidth("Press P or ESC to resume"))/2, 530)
end

-- ---------- EVENT LOOP ----------

function love.load() -- load function that runs once at the beginning

    love.window.setTitle(CONFIG.WINDOW_TITLE)
    love.window.setMode(CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)
    
    -- Use procedural generation if enabled, otherwise use room-based system
    if CONFIG.PROCGEN_ENABLED then
        generateProceduralMap()
        worldMap = {}  -- Empty world map for procgen
        world.player.currRoom = "procgen"
        -- Initialize empty floor/wall maps for compatibility
        randomFloorMap = {}
        randomWallMap = {}
        doorList = {}
        openedDoorSpriteCoords = {}
    else
        randomiseMap("map/layout.txt")
        worldMap = generateMap("map/layout.txt")
        world.key.globalCount = totalKeys(worldMap)
        playerRoomCoord = validStartingRoomAndCoord(worldMap)
        randomFloorMap = randomFloor(worldMap)
        randomWallMap = randomWall(worldMap)
        world.player.currRoom = playerRoomCoord[1]
        world.player.coord = playerRoomCoord[2]
        deserialize(string.format("map/%s.txt", playerRoomCoord[1]))
        doorList = extractDoors(worldMap, world.player.currRoom) -- checks connecting doors available and replace doors that should not exist with walls
        openedDoorSpriteCoords = shallowCopy(doorList)
        addDoorAsWall(world,doorList)
        world.door.coord = doorList
    end
    
    -- Initialize ghost AI
    AI.initializeGhosts(world)
    
    -- Initialize animations
    Animation.init()
    Animation.initGhostBobbing(#world.monster.coord)
    
    -- Initialize combat
    Combat.init(#world.monster.coord)
    
    -- Initialize statistics
    stats.startTime = love.timer.getTime()
    stats.roomsVisited = {[world.player.currRoom] = true}
    
    -- Initialize time attack mode
    if timeAttackEnabled then
        timeAttack.enabled = true
        timeAttack.gameStartTime = love.timer.getTime()
        timeAttack.elapsedGameTime = 0
        timeAttack.parTime = CONFIG.TIME_ATTACK_PAR_TIMES[CONFIG.DIFFICULTY] or 180
        timeAttack.itemBonus = 0
        timeAttack.lastSpeedIncrease = 0
        print("Time Attack Mode - Par Time: " .. timeAttack.parTime .. "s")
    end
    
    -- Setup event listeners (demonstrating event system)
    Events.on(Events.GAME_EVENTS.KEY_COLLECTED, function(keyCoord)
        print("[Event] Key collected at", keyCoord[1], keyCoord[2])
    end)
    
    Events.on(Events.GAME_EVENTS.MONSTER_KILLED, function(monsterIndex)
        print("[Event] Monster", monsterIndex, "defeated")
    end)
    
    Events.on(Events.GAME_EVENTS.PLAYER_DEATH, function()
        print("[Event] Player died - Game Over")
    end)
    
    Events.on(Events.GAME_EVENTS.ROOM_ENTERED, function(roomName)
        print("[Event] Entered room:", roomName)
    end)
    
    Events.on(Events.GAME_EVENTS.ITEM_COLLECTED, function(itemType)
        print("[Event] Item collected:", itemType)
    end)
    
    debugMode = CONFIG.DEBUG_MODE
    godMode = CONFIG.GOD_MODE

    -- print(inspect(worldMap))
    -- print(totalKeys(worldMap))
    -- print(inspect(validStartingRoomAndCoord(worldMap)))
    -- print(inspect(openedDoorSpriteCoords))

    -- ---------- SPRITE LOADING ------------

    playerSprite = love.graphics.newImage("sprite/player-default.png")
    deadPlayerSprite = love.graphics.newImage("sprite/player-tombstone.png")
    ghostSprite1 = love.graphics.newImage("sprite/ghost-1.png")
    ghostSprite2 = love.graphics.newImage("sprite/ghost-2.png")
    itemSprite = love.graphics.newImage("sprite/potion-1.png")
    floorSprite1 = love.graphics.newImage("sprite/floor-stone-1.png")
    floorSprite2 = love.graphics.newImage("sprite/floor-stone-2.png")
    openedDoorSprite = love.graphics.newImage("sprite/opened-door.png")
    closedDoorSprite = love.graphics.newImage("sprite/closed-door.png")
    openedChestSprite = love.graphics.newImage("sprite/opened-chest.png")
    closedChestSprite = love.graphics.newImage("sprite/closed-chest.png")
    topBorderSprite = love.graphics.newImage("sprite/top-border.png")
    topLeftBorderSprite = love.graphics.newImage("sprite/top-left-border.png")
    topRightBorderSprite = love.graphics.newImage("sprite/top-right-border.png")
    middleLeftBorderSprite = love.graphics.newImage("sprite/middle-left-border.png")
    middleRightBorderSprite = love.graphics.newImage("sprite/middle-right-border.png")
    bottomBorderSprite = love.graphics.newImage("sprite/bottom-border.png")
    bottomLeftBorderSprite = love.graphics.newImage("sprite/bottom-left-border.png")
    bottomRightBorderSprite = love.graphics.newImage("sprite/bottom-right-border.png")
    wallSprite1 = love.graphics.newImage("sprite/dirt-wall-1.png")
    wallSprite2 = love.graphics.newImage("sprite/dirt-wall-2.png")
    wallSprite3 = love.graphics.newImage("sprite/dirt-wall-3.png")

    -- ---------- SOUND LOADING ----------

    ambientNoiseSound = love.audio.newSource("sound/ambient-background.mp3", "stream")
    playerWalkingSound = love.audio.newSource("sound/player-walking.mp3", "static")
    playerDeathSound = love.audio.newSource("sound/player-death.mp3", "static")
    playerTombstoneSound = love.audio.newSource("sound/player-lose-screen.mp3", "static")
    playerItemSound = love.audio.newSource("sound/player-collect-item.mp3", "static")
    playerKeySound = love.audio.newSource("sound/player-collect-key.mp3", "static")
    playerEquipArmourSound = love.audio.newSource("sound/player-equip.mp3", "static")
    doorOpenSound = love.audio.newSource("sound/door-open.mp3", "static")
    ghostScreamSound = love.audio.newSource("sound/ghost-scream.mp3", "static")

    -- ---------- FONT LOADING ----------

    AmaticFont80 = love.graphics.newFont("font/Amatic-Bold.ttf", CONFIG.FONT_SIZE_LARGE)
    AmaticFont40 = love.graphics.newFont("font/Amatic-Bold.ttf", CONFIG.FONT_SIZE_MEDIUM)
    AmaticFont25 = love.graphics.newFont("font/Amatic-Bold.ttf", CONFIG.FONT_SIZE_SMALL)

    -- ---------- MODULE INITIALIZATION ----------
    
    -- Initialize particle systems and effects
    Effects.init()

    -- ---------- LOADING IN PRESETS -----------

    ambientNoiseSound:setLooping(true)
    ambientNoiseSound:setVolume(CONFIG.VOLUME_MUSIC)
    love.audio.play(ambientNoiseSound)

end

function love.update(dt) -- update function that runs once every frame; dt is change in time and can be used for different tasks

    local updateStartTime = love.timer.getTime()

    if currentMode == "titleScreen" then
        
        -- Handle difficulty selection
        if love.keyboard.isDown("up") then
            if not upPressed then
                difficultyMenuSelection = math.max(1, difficultyMenuSelection - 1)
                upPressed = true
            end
        else
            upPressed = false
        end
        
        if love.keyboard.isDown("down") then
            if not downPressed then
                difficultyMenuSelection = math.min(4, difficultyMenuSelection + 1)
                downPressed = true
            end
        else
            downPressed = false
        end
        
        -- Toggle daily challenge mode
        if love.keyboard.isDown("d") then
            if not dPressed then
                dailyChallengeEnabled = not dailyChallengeEnabled
                dPressed = true
                print("Daily Challenge Mode:", dailyChallengeEnabled)
            end
        else
            dPressed = false
        end
        
        -- Toggle time attack mode
        if love.keyboard.isDown("t") then
            if not tPressed then
                timeAttackEnabled = not timeAttackEnabled
                tPressed = true
                print("Time Attack Mode:", timeAttackEnabled)
            end
        else
            tPressed = false
        end

        if love.keyboard.isDown("return") then
            -- Apply difficulty settings
            local difficultyNames = {"easy", "normal", "hard", "nightmare"}
            local selectedDifficulty = difficultyNames[difficultyMenuSelection]
            CONFIG.DIFFICULTY = selectedDifficulty
            
            local settings = CONFIG.DIFFICULTY_SETTINGS[selectedDifficulty]
            CONFIG.MONSTER_SPEED = settings.monsterSpeed
            CONFIG.PLAYER_SPEED = settings.playerSpeed
            world.player.speed = settings.playerSpeed
            world.monster.speed = settings.monsterSpeed
            
            if settings.fogEnabled then
                CONFIG.FOG_ENABLED = true
            end
            
            -- Set game seed for daily challenge or random
            currentSeed = Utils.setGameSeed(dailyChallengeEnabled, CONFIG.USE_CUSTOM_SEED and CONFIG.CUSTOM_SEED or nil)
            print("Starting game with difficulty: " .. selectedDifficulty)
            if dailyChallengeEnabled then
                print("Daily Challenge Mode - Seed: " .. currentSeed .. " (" .. Utils.getDailyDateString() .. ")")
            else
                print("Random seed: " .. currentSeed)
            end
            
            currentMode = "gameScreen"
        elseif love.keyboard.isDown("escape") then
            love.event.quit()
        end

    elseif currentMode == "gameScreen" then

    -- ---------- SCOPING ----------

        player = world.player
        monsters = world.monster
        walls = world.wall
        doors = world.door
        items = world.item
        keys = world.key

    -- ---------- LOSE CONDITION WHEN PLAYER DIES ----------

    -- FUA
    -- further spruce up the lose screen later
        if not player.alive then
            serialize(string.format("map/%s.txt",player.currRoom))
            love.audio.stop(playerWalkingSound)
            love.audio.stop(ambientNoiseSound)
            love.audio.stop(ghostScreamSound)
            -- Store finish time
            if stats.finishTime == 0 then
                stats.finishTime = love.timer.getTime()
            end
            -- love.event.quit()
            currentMode = "loseScreen"
        end

    -- ---------- WIN CONDITION WHEN ALL KEYS COLLECTED ----------

    -- FUA
    -- further spruce up the win screen later
        if player.overallKeyCount == keys.globalCount and player.alive then
            serialize(string.format("map/%s.txt",player.currRoom))
            love.audio.stop(playerWalkingSound)
            love.audio.stop(ambientNoiseSound)
            love.audio.stop(ghostScreamSound)
            -- Store finish time
            if stats.finishTime == 0 then
                stats.finishTime = love.timer.getTime()
            end
            -- love.event.quit()
            currentMode = "winScreen"
        end 

    -- ---------- PLAYER MOVE DIFFERENT ROOM ----------

        if checkPlayerOutBounds(player.coord) then -- player moves to different room, instantiate new room

            playerLoc = checkPlayerRoom(player.coord) 
            sanitiseMonsterCoord(world)
            serialize(string.format("map/%s.txt",player.currRoom)) -- save past room data
            world = reset(world) -- resets world table data
            nextRoom = checkNextRoom(worldMap, player.currRoom, playerLoc[1])
            deserialize(string.format("map/%s.txt",nextRoom)) -- load new room data
            player.currRoom = nextRoom
            player.coord = playerLoc[2] -- new player location
            
            -- Trigger room entered event
            Events.trigger(Events.GAME_EVENTS.ROOM_ENTERED, nextRoom)
            
            -- Track room visit
            if not stats.roomsVisited[nextRoom] then
                stats.roomsVisited[nextRoom] = true
            end
            
            -- Reset fog of war for new room
            if CONFIG.FOG_ENABLED then
                visibilityMap = {}
                currentVisibleTiles = {}
            end
            
            -- Reinitialize ghost AI for new room
            AI.initializeGhosts(world)
            Animation.initGhostBobbing(#world.monster.coord)
            Combat.init(#world.monster.coord)

            doorList = extractDoors(worldMap, world.player.currRoom) -- checks connecting doors available and replace doors that should not exist with walls
            openedDoorSpriteCoords = shallowCopy(doorList)
            addDoorAsWall(world,doorList)
            if world.key.totalCount ~= 0 then
                world.door.coord = doorList
            end
            removeDoors(playerLoc[1]) -- removes door player entered from so player can be instantiated

            -- print(inspect(playerLoc))
            -- print("player moves to door" .. inspect(playerLoc[1]) .. " and new coord is " .. inspect(playerLoc[2]))
            -- print("player now in" .. player.currRoom)

        end

    -- ---------- ITEM EFFECT TIMEOUT ----------

        -- Update all active item effects
        Effects.updateItemEffects(dt)
        
        -- Update particles and screen shake
        Effects.updateParticles(dt)
        Effects.updateScreenShake(dt)
        
        -- Update animations
        Animation.update(dt)
        
        -- Update combat
        Combat.update(dt)
        
        -- Update hazards and apply damage
        local hazardDamage = Hazards.update(dt, player.coord)
        
        if hazardDamage > 0 and not godMode and not Effects.activeEffects.invincibility then
            -- Player took damage from hazard
            player.alive = false
            stats.deaths = stats.deaths + 1
            Effects.spawn(player.coord[1], player.coord[2], "death")
            Effects.startScreenShake(10, 0.5)
            print("player died from hazard")
            love.audio.play(playerDeathSound)
        elseif hazardDamage < 0 then
            -- Timed room failed
            player.alive = false
            stats.deaths = stats.deaths + 1
            Effects.spawn(player.coord[1], player.coord[2], "death")
            Effects.startScreenShake(15, 0.7)
            print("player died - time ran out!")
            love.audio.play(playerDeathSound)
        end
        
        -- Update ambient music volume based on game state
        if CONFIG.POSITIONAL_AUDIO_ENABLED then
            local closestGhostDist = math.huge
            for _, monsterCoord in ipairs(monsters.coord) do
                local dist = Audio.calculateDistance(player.coord[1], player.coord[2], monsterCoord[1], monsterCoord[2])
                if dist < closestGhostDist then
                    closestGhostDist = dist
                end
            end
            Audio.updateAmbientMusic(ambientNoiseSound, player.alive, closestGhostDist)
        end

        if player.speed > CONFIG.PLAYER_SPEED then
            elapsedTime = elapsedTime + dt
            if elapsedTime > CONFIG.PLAYER_SPEED_BUFF_DURATION then
                player.speed = player.speed - items.buffSpeed
                elapsedTime = 0
                print("item wore off, player speed", player.speed)
            end
        end

        -- print(player.speed)
        
    -- ---------- TIME ATTACK MODE -----------
    
        if timeAttack.enabled and player.alive then
            -- Update elapsed time
            timeAttack.elapsedGameTime = love.timer.getTime() - timeAttack.gameStartTime
            
            -- Speed scaling: increase ghost speed over time
            if timeAttack.elapsedGameTime - timeAttack.lastSpeedIncrease >= CONFIG.TIME_ATTACK_SPEED_INCREASE_INTERVAL then
                world.monster.speed = world.monster.speed + CONFIG.TIME_ATTACK_SPEED_INCREASE_AMOUNT
                timeAttack.lastSpeedIncrease = timeAttack.elapsedGameTime
                print(string.format("Time Attack: Speed increased! Ghosts now at %d speed", world.monster.speed))
            end
        end

    -- ---------- ENTITY MOVEMENT -----------

    -- MONSTER MOVEMENT
        -- Apply accessibility slow mode to monster speed
        local effectiveMonsterSpeed = Accessibility.getAdjustedSpeed(monsters.speed)
        AI.updateMonsters(world, player.coord, dt, effectiveMonsterSpeed, Effects.activeEffects.ghostSlow)

    -- MONSTER PROXIMITY CHECK & POSITIONAL AUDIO

        if player.alive then
            if CONFIG.POSITIONAL_AUDIO_ENABLED then
                -- Use positional audio system
                Audio.updateGhostAudio(ghostScreamSound, player.coord, monsters.coord)
            else
                -- Original proximity check (simple on/off)
                if ghostProxCheck(player.coord, monsters.coord) then
                    if not ghostScreamSound:isPlaying() then
                        love.audio.play(ghostScreamSound)
                    end
                else
                    if ghostScreamSound:isPlaying() then
                        love.audio.stop(ghostScreamSound)
                    end
                end
            end
        end

    -- PLAYER INPUT

        -- player pause toggle
        if love.keyboard.isDown("p") then
            if not pPressed then
                currentMode = "pauseScreen"
                pPressed = true
                love.audio.pause(playerWalkingSound)
                love.audio.pause(ghostScreamSound)
            end
        else
            pPressed = false
        end

        -- player escape screen

        if love.keyboard.isDown("escape") then 
            currentMode = "pauseScreen"
        end
        
        -- debug mode toggle (F3)
        if love.keyboard.isDown("f3") then
            if not f3Pressed then
                debugMode = not debugMode
                f3Pressed = true
                print("Debug mode:", debugMode)
            end
        else
            f3Pressed = false
        end
        
        -- god mode toggle (F4)
        if love.keyboard.isDown("f4") then
            if not f4Pressed then
                godMode = not godMode
                f4Pressed = true
                print("God mode:", godMode)
            end
        else
            f4Pressed = false
        end
        
        -- fog of war toggle (F5)
        if love.keyboard.isDown("f5") then
            if not f5Pressed then
                CONFIG.FOG_ENABLED = not CONFIG.FOG_ENABLED
                f5Pressed = true
                print("Fog of war:", CONFIG.FOG_ENABLED)
                if not CONFIG.FOG_ENABLED then
                    visibilityMap = {}
                    currentVisibleTiles = {}
                end
            end
        else
            f5Pressed = false
        end
        
        -- minimap toggle (M)
        if love.keyboard.isDown("m") then
            if not mPressed then
                minimapEnabled = not minimapEnabled
                mPressed = true
                print("Minimap:", minimapEnabled)
            end
        else
            mPressed = false
        end
        
        -- profiling toggle (F6)
        if love.keyboard.isDown("f6") then
            if not f6Pressed then
                profilingEnabled = not profilingEnabled
                f6Pressed = true
                print("Profiling:", profilingEnabled)
                if profilingEnabled then
                    -- Reset profiling data
                    profiling.frameHistory = {}
                    profiling.updateTimeHistory = {}
                    profiling.drawTimeHistory = {}
                    profiling.memoryHistory = {}
                    profiling.updateTimer = 0
                end
            end
        else
            f6Pressed = false
        end
        
        -- Inventory item usage (1, 2, 3)
        if CONFIG.INVENTORY_ENABLED then
            if love.keyboard.isDown("1") then
                if not key1Pressed then
                    useInventoryItem(1)
                    key1Pressed = true
                end
            else
                key1Pressed = false
            end
            
            if love.keyboard.isDown("2") then
                if not key2Pressed then
                    useInventoryItem(2)
                    key2Pressed = true
                end
            else
                key2Pressed = false
            end
            
            if love.keyboard.isDown("3") then
                if not key3Pressed then
                    useInventoryItem(3)
                    key3Pressed = true
                end
            else
                key3Pressed = false
            end
        end
        
        -- Accessibility toggles
        -- Toggle colorblind mode (F7)
        if love.keyboard.isDown("f7") then
            if not f7Pressed then
                local newMode = Accessibility.cycleColorblindMode()
                f7Pressed = true
                print("Colorblind mode:", newMode)
            end
        else
            f7Pressed = false
        end
        
        -- Toggle high contrast (F8)
        if love.keyboard.isDown("f8") then
            if not f8Pressed then
                CONFIG.HIGH_CONTRAST_MODE = not CONFIG.HIGH_CONTRAST_MODE
                f8Pressed = true
                print("High contrast mode:", CONFIG.HIGH_CONTRAST_MODE)
            end
        else
            f8Pressed = false
        end
        
        -- Toggle slow mode (F9)
        if love.keyboard.isDown("f9") then
            if not f9Pressed then
                CONFIG.SLOW_MODE = not CONFIG.SLOW_MODE
                f9Pressed = true
                print("Slow mode:", CONFIG.SLOW_MODE)
            end
        else
            f9Pressed = false
        end

        -- PLAYER MOVEMENT

        if player.alive then

            storedX, storedY = player.coord[1], player.coord[2]
            local moved = false
            
            -- Apply accessibility slow mode to player speed
            local effectivePlayerSpeed = Accessibility.getAdjustedSpeed(player.speed)

            if love.keyboard.isDown("w") or love.keyboard.isDown("up") then 
                player.coord[2] = player.coord[2] - (dt * effectivePlayerSpeed)
                lastMoveX, lastMoveY = 0, -1
                moved = true
            elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then 
                player.coord[2] = player.coord[2] + (dt * effectivePlayerSpeed)
                lastMoveX, lastMoveY = 0, 1
                moved = true
            end

            if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
                player.coord[1] = player.coord[1] - (dt * effectivePlayerSpeed)
                lastMoveX, lastMoveY = -1, 0
                moved = true
            elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
                player.coord[1] = player.coord[1] + (dt * effectivePlayerSpeed)
                lastMoveX, lastMoveY = 1, 0
                moved = true
            end
            
            -- Attack input (spacebar)
            if CONFIG.COMBAT_ENABLED and love.keyboard.isDown("space") then
                if not spacePressed then
                    if Combat.tryAttack(player.coord[1], player.coord[2], lastMoveX, lastMoveY) then
                        print("Player attacks!")
                        -- Handle attack hits below in collision section
                    end
                    spacePressed = true
                end
            else
                spacePressed = false
            end

            if love.keyboard.isDown("w", "up", "s", "down", "a", "left", "d", "right") then
                if not playerWalkingSound:isPlaying() then
                    love.audio.play(playerWalkingSound)
                    playerWalkingSound:setLooping(true)
                end
            else
                if playerWalkingSound:isPlaying() then
                    love.audio.stop(playerWalkingSound)
                end
            end

        -- ---------- COLLISION ----------

        -- player and wall

            for _, wallCoord in ipairs(walls.coord) do
                if checkCollision(wallCoord, player.coord) then
                    if not godMode then
                        player.coord[1], player.coord[2] = storedX, storedY
                    end
                end
            end

        -- player and door

            for _, doorCoord in ipairs(doors.coord) do
                if checkCollision(doorCoord, player.coord) then
                    if not godMode then
                        player.coord[1], player.coord[2] = storedX, storedY
                    end
                end
            end

        -- player and monster

            -- Check attack hits first
            if CONFIG.COMBAT_ENABLED and Combat.isCurrentlyAttacking() then
                local attackBox = Combat.getAttackHitbox(player.coord[1], player.coord[2])
                
                for i = #monsters.coord, 1, -1 do
                    local monsterCoord = monsters.coord[i]
                    if Combat.checkAttackHit(attackBox, monsterCoord[1], monsterCoord[2]) then
                        local isDead = Combat.damageMonster(i)
                        Effects.startScreenShake(5, 0.2)
                        
                        if isDead then
                            print("Monster " .. i .. " defeated!")
                            Effects.spawn(monsterCoord[1], monsterCoord[2], "death")
                            
                            -- Trigger monster killed event
                            Events.trigger(Events.GAME_EVENTS.MONSTER_KILLED, i)
                            
                            -- Drop loot (key or item)
                            math.randomseed(os.time() + i)
                            local dropRoll = math.random()
                            if dropRoll < CONFIG.DROP_CHANCE_KEY then
                                table.insert(world.key.coord, {monsterCoord[1], monsterCoord[2]})
                                world.key.totalCount = world.key.totalCount + 1
                                world.key.globalCount = world.key.globalCount + 1
                                print("Monster dropped a key!")
                            elseif dropRoll < CONFIG.DROP_CHANCE_KEY + CONFIG.DROP_CHANCE_ITEM then
                                table.insert(world.item.coord, {monsterCoord[1], monsterCoord[2]})
                                print("Monster dropped an item!")
                            end
                            
                            -- Remove monster
                            table.remove(world.monster.coord, i)
                            table.remove(world.monster.aiTypes, i)
                            if world.monster.patrolPoints[i] then
                                table.remove(world.monster.patrolPoints, i)
                            end
                            if world.monster.currentWaypoint[i] then
                                table.remove(world.monster.currentWaypoint, i)
                            end
                            Combat.removeMonster(i)
                        else
                            print("Monster " .. i .. " hit! Health: " .. Combat.getMonsterHealth(i))
                        end
                        
                        break  -- Only hit one monster per attack
                    end
                end
            end
            
            -- Then check collision damage
            for _, monsterCoord in ipairs(monsters.coord) do
                if checkCollision(monsterCoord, player.coord) then
                    if not godMode and not Effects.activeEffects.invincibility then
                        player.coord[1], player.coord[2] = storedX, storedY
                        player.alive = false
                        stats.deaths = stats.deaths + 1
                        
                        -- Trigger player death event
                        Events.trigger(Events.GAME_EVENTS.PLAYER_DEATH)
                        
                        Effects.spawn(player.coord[1], player.coord[2], "death")
                        Effects.startScreenShake(10, 0.5)
                        print("player died")
                        love.audio.play(playerDeathSound)
                    elseif Effects.activeEffects.invincibility then
                        -- Just bounce back but don't die
                        player.coord[1], player.coord[2] = storedX, storedY
                        Effects.startScreenShake(3, 0.2) -- Lighter shake when invincible
                    end
                    -- love.event.quit()
                end
            end

        -- player and item

            for i, itemCoord in ipairs(items.coord) do 
                if checkCollision(itemCoord, player.coord) then
                    Effects.spawn(itemCoord[1], itemCoord[2], "item")
                    
                    if CONFIG.INVENTORY_ENABLED and not CONFIG.INSTANT_USE_ITEMS then
                        -- Add to inventory
                        local effect = math.random(1, 6)
                        local effectNames = {\"speedBoost\", \"speedReduction\", \"ghostSlow\", \"invincibility\", \"mapReveal\", \"megaSpeed\"}\n                        local item = {effect = effectNames[effect]}\n                        \n                        if addItemToInventory(item) then\n                            table.remove(items.coord, i)\n                            love.audio.play(playerItemSound)\n                        end\n                    else\n                        -- Immediate use (original behavior)\n                        Effects.applyRandomItemEffect(world)\n                        table.remove(items.coord, i)\n                        stats.itemsUsed = stats.itemsUsed + 1\n                        love.audio.play(playerItemSound)\n                    end\n                end\n            end

        -- player and key

            for q, keyCoord in ipairs(keys.coord) do
                if checkCollision(keyCoord, player.coord) then
                    
                    Effects.spawn(keyCoord[1], keyCoord[2], "key")
                    Animation.startChestOpening(keyCoord[1], keyCoord[2])
                    
                    -- Trigger key collected event
                    Events.trigger(Events.GAME_EVENTS.KEY_COLLECTED, keyCoord)
                    
                    table.remove(keys.coord, q)
                    player.keyCount = player.keyCount + 1
                    player.overallKeyCount = player.overallKeyCount + 1
                    stats.keysCollected = stats.keysCollected + 1
                    print("key picked up", player.keyCount)
                    love.audio.play(playerKeySound)

                    if player.keyCount == keys.totalCount then
                        print("all keys collected, opening doors")
                        love.audio.play(doorOpenSound)
                        doors.coord = {}
                        
                        -- Trigger door opened event
                        Events.trigger(Events.GAME_EVENTS.DOOR_OPENED)
                        
                        -- Spawn door particles and animations for all opened doors
                        for _, doorCoord in ipairs(openedDoorSpriteCoords) do
                            Effects.spawn(doorCoord[1], doorCoord[2], "door")
                            Animation.startDoorOpening(doorCoord[1], doorCoord[2])
                        end
                    end

                end
            end
            
        -- Update fog of war visibility
        if CONFIG.FOG_ENABLED then
            updateVisibility(player.coord)
        end
        
        end

    elseif currentMode == "winScreen" then

        if love.keyboard.isDown("return") or love.keyboard.isDown("escape") then
            love.event.quit()
        end

    elseif currentMode  == "loseScreen" then
        
        if love.keyboard.isDown("return") or love.keyboard.isDown("escape") then
            love.event.quit()
        end
    
    elseif currentMode == "pauseScreen" then
        
        -- Handle pause menu selection
        if love.keyboard.isDown("up") then
            if not upPressed then
                pauseMenuSelection = math.max(1, pauseMenuSelection - 1)
                upPressed = true
            end
        else
            upPressed = false
        end
        
        if love.keyboard.isDown("down") then
            if not downPressed then
                pauseMenuSelection = math.min(3, pauseMenuSelection + 1)
                downPressed = true
            end
        else
            downPressed = false
        end
        
        if love.keyboard.isDown("return") then
            if pauseMenuSelection == 1 then
                -- Resume
                currentMode = "gameScreen"
                love.audio.play(playerWalkingSound)
            elseif pauseMenuSelection == 2 then
                -- Restart (reload game)
                love.load()
                currentMode = "titleScreen"
            elseif pauseMenuSelection == 3 then
                -- Quit
                love.event.quit()
            end
        end
        
        if love.keyboard.isDown("p") or love.keyboard.isDown("escape") then
            if not pPressed and not escPressed then
                currentMode = "gameScreen"
                pPressed = true
                escPressed = true
            end
        else
            pPressed = false
            escPressed = false
        end

    end
    
    -- Track update time for profiling
    if profilingEnabled then
        profiling.currentUpdateTime = love.timer.getTime() - updateStartTime
    end

end

function love.draw() -- draw function that runs once every frame

    local drawStartTime = love.timer.getTime()

    if currentMode == "titleScreen" then
        UI.drawTitleScreen(difficultyMenuSelection, {large = AmaticFont80, medium = AmaticFont40, small = AmaticFont25}, dailyChallengeEnabled, timeAttackEnabled)
    elseif currentMode == "gameScreen" then -- draw game

        playerCoord = world.player.coord
        monsters = world.monster.coord
        walls = world.wall.coord
        doors = world.door.coord
        items = world.item.coord
        keys = world.key.coord

        love.graphics.clear()
        
        -- Apply screen shake
        love.graphics.push()
        if Effects.screenShake.active then
            love.graphics.translate(Effects.screenShake.offsetX, Effects.screenShake.offsetY)
        end

        -- SETS OVERLAYS AND SHADERS

        love.graphics.setColor(0.5, 0.5, 0.5, 1) -- makes the screen darker by adding a gray overlay over all sprites

        -- DRAW FLOOR TILESET; everything else is drawn over this

        for _,val in ipairs(randomFloorMap) do
            if val[1] == world.player.currRoom then
                for _,el in ipairs(val[2]) do
                    local x, y = el[1][1], el[1][2]
                    local visible = isVisible(x, y)
                    local visited = hasBeenVisited(x, y)
                    
                    if visible then
                        love.graphics.setColor(0.5, 0.5, 0.5, 1)
                        if el[2] == 1 then
                            love.graphics.draw(floorSprite1, x, y)
                        elseif el[2] == 2 then
                            love.graphics.draw(floorSprite2, x, y)
                        end
                    elseif visited then
                        love.graphics.setColor(0.5, 0.5, 0.5, CONFIG.VISITED_ALPHA)
                        if el[2] == 1 then
                            love.graphics.draw(floorSprite1, x, y)
                        elseif el[2] == 2 then
                            love.graphics.draw(floorSprite2, x, y)
                        end
                    end
                end
            end
        end

        -- love.graphics.setColor(173/255, 216/255, 230/255, 1)
        -- love.graphics.rectangle("fill",0,0,600,600)

        -- DRAW WALLS

        for _, val in ipairs(randomWallMap) do
            if val[1] == world.player.currRoom then
                for _, el in ipairs(val[2]) do
                    local x, y = el[1][1], el[1][2]
                    if inside(el[1], world.wall.coord) then
                        local visible = isVisible(x, y)
                        local visited = hasBeenVisited(x, y)
                        
                        if visible then
                            love.graphics.setColor(0.5, 0.5, 0.5, 1)
                            if el[2] == 1 then
                                love.graphics.draw(wallSprite1, x, y)
                            elseif el[2] == 2 then
                                love.graphics.draw(wallSprite2, x, y)
                            elseif el[2] == 3 then
                                love.graphics.draw(wallSprite3, x, y)
                            end
                        elseif visited then
                            love.graphics.setColor(0.5, 0.5, 0.5, CONFIG.VISITED_ALPHA)
                            if el[2] == 1 then
                                love.graphics.draw(wallSprite1, x, y)
                            elseif el[2] == 2 then
                                love.graphics.draw(wallSprite2, x, y)
                            elseif el[2] == 3 then
                                love.graphics.draw(wallSprite3, x, y)
                            end
                        end
                    end
                end
            end
        end

        --[[
        -- love.graphics.setColor(1,1,1)
        for _, wallCoord in ipairs(walls) do
            love.graphics.draw(wallSprite1, wallCoord[1], wallCoord[2])
            -- love.graphics.rectangle("fill", wallCoord[1], wallCoord[2], 20, 20)
        end 
        ]]--

        -- DRAW BORDERS OF SCREEN

        for y = 0, 580, 20 do
            for x = 0, 580, 20 do
                if y == 0 then 
                    love.graphics.draw(topBorderSprite, x, y)
                elseif y == 580 then
                    love.graphics.draw(bottomBorderSprite, x, y)
                elseif x == 0 then
                    love.graphics.draw(middleLeftBorderSprite, x, y)
                elseif x == 580 then
                    love.graphics.draw(middleRightBorderSprite, x, y)
                else
                    -- do nothing if any other coordinate
                end
            end
        end
        love.graphics.draw(topLeftBorderSprite, 0, 0)
        love.graphics.draw(topRightBorderSprite, 580, 0)
        love.graphics.draw(bottomLeftBorderSprite, 0, 580)
        love.graphics.draw(bottomRightBorderSprite, 580, 580)

        -- DRAW DOORS

        for _, openedDoorCoord in ipairs(openedDoorSpriteCoords) do
            if isVisible(openedDoorCoord[1], openedDoorCoord[2]) then
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.draw(openedDoorSprite, openedDoorCoord[1], openedDoorCoord[2])
            elseif hasBeenVisited(openedDoorCoord[1], openedDoorCoord[2]) then
                love.graphics.setColor(0.5, 0.5, 0.5, CONFIG.VISITED_ALPHA)
                love.graphics.draw(openedDoorSprite, openedDoorCoord[1], openedDoorCoord[2])
            end
        end

        -- love.graphics.setColor(1, 0.5, 0.5)
        for _, doorCoord in ipairs(doors) do
            if isVisible(doorCoord[1], doorCoord[2]) then
                -- Check if door is animating (opening)
                local alpha = 1.0
                if CONFIG.ANIMATIONS_ENABLED and Animation.isDoorAnimating(doorCoord[1], doorCoord[2]) then
                    alpha = Animation.getDoorAnimationAlpha(doorCoord[1], doorCoord[2])
                end
                love.graphics.setColor(0.5, 0.5, 0.5, alpha)
                love.graphics.draw(closedDoorSprite, doorCoord[1], doorCoord[2])
            elseif hasBeenVisited(doorCoord[1], doorCoord[2]) then
                love.graphics.setColor(0.5, 0.5, 0.5, CONFIG.VISITED_ALPHA)
                love.graphics.draw(closedDoorSprite, doorCoord[1], doorCoord[2])
            end
            -- love.graphics.rectangle("fill", doorCoord[1], doorCoord[2], 20, 20)
        end

        -- DRAW MONSTERS

        -- love.graphics.setColor(1,0,0)

        if world.player.alive then 
            for i, monsterCoord in ipairs(monsters) do
                if isVisible(monsterCoord[1], monsterCoord[2]) then
                    love.graphics.setColor(0.5, 0.5, 0.5, 1)
                    local aiType = world.monster.aiTypes[i] or 1
                    
                    -- Apply bobbing animation
                    local bobOffset = 0
                    if CONFIG.ANIMATIONS_ENABLED then
                        bobOffset = Animation.getGhostBobOffset(i, love.timer.getTime())
                    end
                    
                    if aiType == 1 then
                        love.graphics.draw(ghostSprite1, monsterCoord[1], monsterCoord[2] + bobOffset) -- Chase ghost with bob
                    else
                        love.graphics.draw(ghostSprite2, monsterCoord[1], monsterCoord[2] + bobOffset) -- Patrol ghost with bob
                    end
                end
                -- love.graphics.rectangle("fill", monsterCoord[1], monsterCoord[2], 20, 20)
            end 
        else
        end

        -- DRAW ITEM PICKUPS

        -- love.graphics.setColor(0,0,1)
        for _, itemCoord in ipairs(items) do
            if isVisible(itemCoord[1], itemCoord[2]) then
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.draw(itemSprite, itemCoord[1], itemCoord[2])
            end
            -- love.graphics.rectangle("fill", itemCoord[1], itemCoord[2], 20, 20)
        end

        -- DRAW KEYS

        -- love.graphics.setColor(1,1,0)
        for _, keyCoord in ipairs(keys) do
            if isVisible(keyCoord[1], keyCoord[2]) then
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                
                -- Apply chest opening animation
                if CONFIG.ANIMATIONS_ENABLED then
                    local scale = Animation.getChestAnimationScale(keyCoord[1], keyCoord[2])
                    local ox, oy = closedChestSprite:getWidth() / 2, closedChestSprite:getHeight() / 2
                    love.graphics.draw(closedChestSprite, keyCoord[1] + ox, keyCoord[2] + oy, 0, scale, scale, ox, oy)
                else
                    love.graphics.draw(closedChestSprite, keyCoord[1], keyCoord[2])
                end
            end
            -- love.graphics.rectangle("fill", keyCoord[1], keyCoord[2], 20, 20)
        end
        
        -- DRAW HAZARDS (spikes, pressure plates, etc.)
        Hazards.draw(wallSprite1)

        -- DRAW PLAYER CHARACTER

        if world.player.alive then
            -- Apply color based on active effects
            if Effects.activeEffects.invincibility then
                -- Flash yellow/white for invincibility
                local flash = math.sin(love.timer.getTime() * 10) > 0
                if flash then
                    love.graphics.setColor(1, 1, 0, 1)
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
            
            -- Apply idle animation (subtle pulse)
            if CONFIG.ANIMATIONS_ENABLED then
                local scale = Animation.getPlayerIdleScale()
                local ox, oy = playerSprite:getWidth() / 2, playerSprite:getHeight() / 2
                love.graphics.draw(playerSprite, playerCoord[1] + ox, playerCoord[2] + oy, 0, scale, scale, ox, oy)
            else
                love.graphics.draw(playerSprite, playerCoord[1], playerCoord[2])
            end
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.draw(deadPlayerSprite, playerCoord[1], playerCoord[2])
        end

        -- love.graphics.setColor(0,1,0)
        -- love.graphics.rectangle("fill", playerCoord[1], playerCoord[2], 20, 20)

        love.graphics.setShader()
        
        -- DRAW PARTICLES (under screen shake)
        Effects.drawParticles()
        
        -- DRAW HUD (always visible, not just debug mode)
        UI.drawHUD(world, Effects.activeEffects, debugMode, {small = AmaticFont25})
        
        -- DRAW TIMED ROOM UI
        Hazards.drawTimedRoomUI()
        
        -- DRAW TIME ATTACK UI
        UI.drawTimeAttackUI(timeAttack, {small = AmaticFont25})
        
        -- DRAW MINIMAP
        if minimapEnabled and not debugMode then
            UI.drawMinimap(world, minimapEnabled)
        end
        
        -- DRAW DEBUG OVERLAY
        if debugMode then
            love.graphics.setColor(1, 1, 1, 1)
            
            -- FPS counter
            if CONFIG.SHOW_FPS then
                love.graphics.setFont(AmaticFont25)
                love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
                love.graphics.print("God Mode: " .. tostring(godMode), 10, 35)
            end
            
            -- Collision boxes
            if CONFIG.SHOW_COLLISION_BOXES then
                love.graphics.setColor(1, 0, 0, 0.5)
                for _, wallCoord in ipairs(walls) do
                    love.graphics.rectangle("line", wallCoord[1], wallCoord[2], CONFIG.TILE_SIZE, CONFIG.TILE_SIZE)
                end
                
                love.graphics.setColor(1, 1, 0, 0.5)
                for _, doorCoord in ipairs(doors) do
                    love.graphics.rectangle("line", doorCoord[1], doorCoord[2], CONFIG.TILE_SIZE, CONFIG.TILE_SIZE)
                end
                
                love.graphics.setColor(0, 1, 0, 0.8)
                love.graphics.rectangle("line", playerCoord[1], playerCoord[2], CONFIG.TILE_SIZE, CONFIG.TILE_SIZE)
            end
            
            -- AI pathfinding vectors
            if CONFIG.SHOW_AI_VECTORS and world.player.alive then
                for i, monsterCoord in ipairs(monsters) do
                    local aiType = world.monster.aiTypes[i] or 1
                    
                    if aiType == 1 then
                        -- Chase AI - show line to player
                        love.graphics.setColor(1, 0, 1, 0.7)
                        love.graphics.line(
                            monsterCoord[1] + CONFIG.TILE_SIZE/2, 
                            monsterCoord[2] + CONFIG.TILE_SIZE/2,
                            playerCoord[1] + CONFIG.TILE_SIZE/2,
                            playerCoord[2] + CONFIG.TILE_SIZE/2
                        )
                    elseif aiType == 2 then
                        -- Patrol AI - show patrol path
                        love.graphics.setColor(0, 1, 1, 0.5)
                        local waypoints = world.monster.patrolPoints[i]
                        if waypoints then
                            for j = 1, #waypoints do
                                local nextJ = (j % #waypoints) + 1
                                love.graphics.line(
                                    waypoints[j][1] + CONFIG.TILE_SIZE/2,
                                    waypoints[j][2] + CONFIG.TILE_SIZE/2,
                                    waypoints[nextJ][1] + CONFIG.TILE_SIZE/2,
                                    waypoints[nextJ][2] + CONFIG.TILE_SIZE/2
                                )
                            end
                        end
                    end
                end
            end
            
            -- Statistics
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(AmaticFont25)
            local roomCount = 0
            for _ in pairs(stats.roomsVisited) do roomCount = roomCount + 1 end
            love.graphics.print("Rooms: " .. roomCount, 10, 60)
            love.graphics.print("Keys: " .. world.player.overallKeyCount .. "/" .. world.key.globalCount, 10, 85)
            love.graphics.print("Speed: " .. world.player.speed, 10, 110)
            
            -- Active effects
            local yPos = 135
            if Effects.activeEffects.invincibility then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print(string.format("Invincible: %.1fs", Effects.activeEffects.invincibilityTimer), 10, yPos)
                yPos = yPos + 25
            end
            if Effects.activeEffects.ghostSlow then
                love.graphics.setColor(0, 1, 1, 1)
                love.graphics.print(string.format("Ghosts Slowed: %.1fs", Effects.activeEffects.ghostSlowTimer), 10, yPos)
                yPos = yPos + 25
            end
            if Effects.activeEffects.mapReveal then
                love.graphics.setColor(1, 0.5, 0, 1)
                love.graphics.print(string.format("Map Reveal: %.1fs", Effects.activeEffects.mapRevealTimer), 10, yPos)
                yPos = yPos + 25
            end
        end
        
        -- Pop screen shake transform
        love.graphics.pop()

    elseif currentMode == "winScreen" then
        UI.drawWinScreen(world, stats, {large = AmaticFont80, medium = AmaticFont40, small = AmaticFont25}, dailyChallengeEnabled)
    elseif currentMode == "loseScreen" then
        UI.drawLoseScreen(world, stats, {large = AmaticFont80, medium = AmaticFont40, small = AmaticFont25})
    elseif currentMode == "pauseScreen" then
        UI.drawPauseScreen(pauseMenuSelection, {large = AmaticFont80, medium = AmaticFont40, small = AmaticFont25})
    end
    
    -- Track draw time and update profiling
    if profilingEnabled then
        profiling.currentDrawTime = love.timer.getTime() - drawStartTime
        updateProfiling(love.timer.getDelta(), profiling.currentUpdateTime, profiling.currentDrawTime)
        drawProfilingOverlay()
    end
    
    -- Draw accessibility visual indicators
    if currentMode == "gameScreen" and CONFIG.VISUAL_AUDIO_INDICATORS then
        Accessibility.drawAudioIndicator(world.player.coord, world.monster.coord)
    end
end
