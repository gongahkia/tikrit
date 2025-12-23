-- Procedural generation module for room layouts
local CONFIG = require("config")

local ProcGen = {}

-- BSP (Binary Space Partitioning) algorithm for room generation
function ProcGen.generateRoomLayout(width, height, minRoomSize, maxRoomSize)
    -- Create initial room space (0 = floor, 1 = wall)
    local grid = {}
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            grid[y][x] = 1  -- Start with all walls
        end
    end
    
    -- BSP recursive splitting
    local rooms = {}
    local function split(x, y, w, h, depth)
        if depth >= CONFIG.PROCGEN_MAX_DEPTH or w < minRoomSize * 2 or h < minRoomSize * 2 then
            -- Create a room in this space
            local roomW = math.random(minRoomSize, math.min(maxRoomSize, w - 2))
            local roomH = math.random(minRoomSize, math.min(maxRoomSize, h - 2))
            local roomX = x + math.random(1, math.max(1, w - roomW - 1))
            local roomY = y + math.random(1, math.max(1, h - roomH - 1))
            
            -- Carve out the room
            for ry = roomY, roomY + roomH - 1 do
                for rx = roomX, roomX + roomW - 1 do
                    if ry > 0 and ry <= height and rx > 0 and rx <= width then
                        grid[ry][rx] = 0  -- Floor
                    end
                end
            end
            
            table.insert(rooms, {x = roomX, y = roomY, w = roomW, h = roomH})
            return
        end
        
        -- Decide whether to split horizontally or vertically
        local splitHorizontal = math.random() > 0.5
        if w > h then
            splitHorizontal = false
        elseif h > w then
            splitHorizontal = true
        end
        
        if splitHorizontal then
            -- Split horizontally
            local splitPos = math.random(math.floor(h / 3), math.floor(h * 2 / 3))
            split(x, y, w, splitPos, depth + 1)
            split(x, y + splitPos, w, h - splitPos, depth + 1)
        else
            -- Split vertically
            local splitPos = math.random(math.floor(w / 3), math.floor(w * 2 / 3))
            split(x, y, splitPos, h, depth + 1)
            split(x + splitPos, y, w - splitPos, h, depth + 1)
        end
    end
    
    split(1, 1, width, height, 0)
    
    -- Connect rooms with corridors (2 tiles wide)
    for i = 1, #rooms - 1 do
        local room1 = rooms[i]
        local room2 = rooms[i + 1]
        
        local centerX1 = room1.x + math.floor(room1.w / 2)
        local centerY1 = room1.y + math.floor(room1.h / 2)
        local centerX2 = room2.x + math.floor(room2.w / 2)
        local centerY2 = room2.y + math.floor(room2.h / 2)
        
        -- Create L-shaped corridor (2 tiles wide)
        if math.random() > 0.5 then
            -- Horizontal then vertical
            for x = math.min(centerX1, centerX2), math.max(centerX1, centerX2) do
                if x > 0 and x <= width and centerY1 > 0 and centerY1 <= height then
                    grid[centerY1][x] = 0
                    -- Make corridor 2 tiles wide
                    if centerY1 + 1 <= height then
                        grid[centerY1 + 1][x] = 0
                    end
                end
            end
            for y = math.min(centerY1, centerY2), math.max(centerY1, centerY2) do
                if centerX2 > 0 and centerX2 <= width and y > 0 and y <= height then
                    grid[y][centerX2] = 0
                    -- Make corridor 2 tiles wide
                    if centerX2 + 1 <= width then
                        grid[y][centerX2 + 1] = 0
                    end
                end
            end
        else
            -- Vertical then horizontal
            for y = math.min(centerY1, centerY2), math.max(centerY1, centerY2) do
                if centerX1 > 0 and centerX1 <= width and y > 0 and y <= height then
                    grid[y][centerX1] = 0
                    -- Make corridor 2 tiles wide
                    if centerX1 + 1 <= width then
                        grid[y][centerX1 + 1] = 0
                    end
                end
            end
            for x = math.min(centerX1, centerX2), math.max(centerX1, centerX2) do
                if x > 0 and x <= width and centerY2 > 0 and centerY2 <= height then
                    grid[centerY2][x] = 0
                    -- Make corridor 2 tiles wide
                    if centerY2 + 1 <= height then
                        grid[centerY2 + 1][x] = 0
                    end
                end
            end
        end
    end
    
    return grid, rooms
end

-- Cellular automata for more organic room generation
function ProcGen.generateCaveLayout(width, height, fillPercent, smoothIterations)
    -- Initialize grid with random walls/floors
    local grid = {}
    math.randomseed(os.time())
    
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            if x == 1 or x == width or y == 1 or y == height then
                grid[y][x] = 1  -- Border walls
            else
                grid[y][x] = (math.random(100) < fillPercent) and 1 or 0
            end
        end
    end
    
    -- Smooth the cave using cellular automata rules
    for iteration = 1, smoothIterations do
        local newGrid = {}
        for y = 1, height do
            newGrid[y] = {}
            for x = 1, width do
                newGrid[y][x] = grid[y][x]
            end
        end
        
        for y = 2, height - 1 do
            for x = 2, width - 1 do
                local wallCount = 0
                
                -- Count surrounding walls
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if not (dx == 0 and dy == 0) then
                            if grid[y + dy][x + dx] == 1 then
                                wallCount = wallCount + 1
                            end
                        end
                    end
                end
                
                -- Apply cellular automata rules
                if wallCount > 4 then
                    newGrid[y][x] = 1  -- Become/stay wall
                elseif wallCount < 4 then
                    newGrid[y][x] = 0  -- Become/stay floor
                end
            end
        end
        
        grid = newGrid
    end
    
    return grid
end

-- Place entities (monsters, keys, items) in generated room
function ProcGen.placeEntities(grid, entityCounts)
    local entities = {
        monsters = {},
        keys = {},
        items = {},
        doors = {},
        playerStart = nil
    }
    
    -- Find all floor tiles
    local floorTiles = {}
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] == 0 then  -- Floor
                table.insert(floorTiles, {x = x, y = y})
            end
        end
    end
    
    -- Shuffle floor tiles
    for i = #floorTiles, 2, -1 do
        local j = math.random(i)
        floorTiles[i], floorTiles[j] = floorTiles[j], floorTiles[i]
    end
    
    local tileIndex = 1
    
    -- Place player start
    if #floorTiles >= tileIndex then
        entities.playerStart = {(floorTiles[tileIndex].x - 1) * CONFIG.TILE_SIZE, (floorTiles[tileIndex].y - 1) * CONFIG.TILE_SIZE}
        tileIndex = tileIndex + 1
    end
    
    -- Place monsters
    for i = 1, entityCounts.monsters do
        if #floorTiles >= tileIndex then
            table.insert(entities.monsters, {(floorTiles[tileIndex].x - 1) * CONFIG.TILE_SIZE, (floorTiles[tileIndex].y - 1) * CONFIG.TILE_SIZE})
            tileIndex = tileIndex + 1
        end
    end
    
    -- Place keys
    for i = 1, entityCounts.keys do
        if #floorTiles >= tileIndex then
            table.insert(entities.keys, {(floorTiles[tileIndex].x - 1) * CONFIG.TILE_SIZE, (floorTiles[tileIndex].y - 1) * CONFIG.TILE_SIZE})
            tileIndex = tileIndex + 1
        end
    end
    
    -- Place items
    for i = 1, entityCounts.items do
        if #floorTiles >= tileIndex then
            table.insert(entities.items, {(floorTiles[tileIndex].x - 1) * CONFIG.TILE_SIZE, (floorTiles[tileIndex].y - 1) * CONFIG.TILE_SIZE})
            tileIndex = tileIndex + 1
        end
    end
    
    return entities
end

return ProcGen
