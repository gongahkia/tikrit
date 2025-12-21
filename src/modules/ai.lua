-- AI module for ghost behaviors
local CONFIG = require("config")

local AI = {}

-- Initialize AI for all ghosts in the current room
function AI.initializeGhosts(world)
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

-- Chase AI: Move directly toward player
function AI.chase(monsterCoord, playerCoord, dt, speed)
    local xOffset = playerCoord[1] - monsterCoord[1]
    local yOffset = playerCoord[2] - monsterCoord[2]
    local angle = math.atan2(yOffset, xOffset)
    local dx = speed * math.cos(angle)
    local dy = speed * math.sin(angle)
    monsterCoord[1] = monsterCoord[1] + (dt * dx)
    monsterCoord[2] = monsterCoord[2] + (dt * dy)
end

-- Patrol AI: Move between waypoints
function AI.patrol(monsterIndex, world, dt, speed)
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

-- Update all monsters based on their AI type
function AI.updateMonsters(world, playerCoord, dt, baseSpeed, ghostSlowActive)
    local effectiveSpeed = baseSpeed
    
    -- Apply ghost slow effect
    if ghostSlowActive then
        effectiveSpeed = effectiveSpeed * CONFIG.GHOST_SLOW_MULTIPLIER
    end
    
    for i, monsterCoord in ipairs(world.monster.coord) do
        local aiType = world.monster.aiTypes[i] or 1
        
        if aiType == 1 then
            AI.chase(monsterCoord, playerCoord, dt, effectiveSpeed)
        elseif aiType == 2 then
            AI.patrol(i, world, dt, effectiveSpeed)
        end
    end
end

return AI
