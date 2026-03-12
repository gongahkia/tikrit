local CONFIG = require("config")
local Utils = require("modules/utils")

local ProcGen = {}

local function cloneRoom(room)
    return {x = room.x, y = room.y, w = room.w, h = room.h}
end

function ProcGen.generateRoomLayout(width, height)
    local grid = {}
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            grid[y][x] = 1
        end
    end

    local rooms = {}

    local function carveRoom(roomX, roomY, roomW, roomH)
        for y = roomY, roomY + roomH - 1 do
            for x = roomX, roomX + roomW - 1 do
                if y > 1 and y < height and x > 1 and x < width then
                    grid[y][x] = 0
                end
            end
        end
    end

    local function split(x, y, w, h, depth)
        if depth >= CONFIG.PROCGEN_MAX_DEPTH
            or w < CONFIG.PROCGEN_MIN_ROOM_SIZE * 2
            or h < CONFIG.PROCGEN_MIN_ROOM_SIZE * 2 then
            local minRoomW = math.min(CONFIG.PROCGEN_MIN_ROOM_SIZE, math.max(3, w - 2))
            local maxRoomW = math.max(minRoomW, math.min(CONFIG.PROCGEN_MAX_ROOM_SIZE, math.max(3, w - 2)))
            local minRoomH = math.min(CONFIG.PROCGEN_MIN_ROOM_SIZE, math.max(3, h - 2))
            local maxRoomH = math.max(minRoomH, math.min(CONFIG.PROCGEN_MAX_ROOM_SIZE, math.max(3, h - 2)))

            local roomW = math.random(minRoomW, maxRoomW)
            local roomH = math.random(minRoomH, maxRoomH)
            local roomX = x + math.random(1, math.max(1, w - roomW - 1))
            local roomY = y + math.random(1, math.max(1, h - roomH - 1))
            local room = {x = roomX, y = roomY, w = roomW, h = roomH}
            carveRoom(room.x, room.y, room.w, room.h)
            table.insert(rooms, room)
            return
        end

        local splitHorizontal = math.random() > 0.5
        if w > h then
            splitHorizontal = false
        elseif h > w then
            splitHorizontal = true
        end

        if splitHorizontal then
            local splitPos = math.random(math.floor(h / 3), math.floor(h * 2 / 3))
            split(x, y, w, splitPos, depth + 1)
            split(x, y + splitPos, w, h - splitPos, depth + 1)
        else
            local splitPos = math.random(math.floor(w / 3), math.floor(w * 2 / 3))
            split(x, y, splitPos, h, depth + 1)
            split(x + splitPos, y, w - splitPos, h, depth + 1)
        end
    end

    split(1, 1, width, height, 0)

    for i = 1, #rooms - 1 do
        local roomA = rooms[i]
        local roomB = rooms[i + 1]
        local ax = roomA.x + math.floor(roomA.w / 2)
        local ay = roomA.y + math.floor(roomA.h / 2)
        local bx = roomB.x + math.floor(roomB.w / 2)
        local by = roomB.y + math.floor(roomB.h / 2)

        for x = math.min(ax, bx), math.max(ax, bx) do
            grid[ay][x] = 0
            if ay + 1 <= height then
                grid[ay + 1][x] = 0
            end
        end

        for y = math.min(ay, by), math.max(ay, by) do
            grid[y][bx] = 0
            if bx + 1 <= width then
                grid[y][bx + 1] = 0
            end
        end
    end

    return grid, rooms
end

local function roomTiles(room)
    local tiles = {}
    for y = room.y + 1, room.y + room.h - 2 do
        for x = room.x + 1, room.x + room.w - 2 do
            table.insert(tiles, {x = x, y = y})
        end
    end
    Utils.shuffle(tiles)
    return tiles
end

local function tileKey(tile)
    return tile.x .. ":" .. tile.y
end

local function chooseTile(room, used)
    local tiles = roomTiles(room)
    for _, tile in ipairs(tiles) do
        if not used[tileKey(tile)] then
            used[tileKey(tile)] = true
            return tile
        end
    end
    return nil
end

local function toWorld(tile)
    return {(tile.x - 1) * CONFIG.TILE_SIZE, (tile.y - 1) * CONFIG.TILE_SIZE}
end

local function makeZone(room, padding)
    padding = padding or 0
    local x = math.max(0, (room.x - 1) * CONFIG.TILE_SIZE - padding)
    local y = math.max(0, (room.y - 1) * CONFIG.TILE_SIZE - padding)
    local width = math.min(CONFIG.WINDOW_WIDTH - x, room.w * CONFIG.TILE_SIZE + padding * 2)
    local height = math.min(CONFIG.WINDOW_HEIGHT - y, room.h * CONFIG.TILE_SIZE + padding * 2)
    return {x = x, y = y, width = width, height = height}
end

local function pickMonsterType(difficultyName, counts)
    local weights = {
        easy = {
            chaser = 5,
            patrol_warden = 3,
            lurker = 1,
            wailer = 1,
            stalker = 1,
        },
        normal = {
            chaser = 4,
            patrol_warden = 3,
            lurker = 2,
            wailer = 2,
            stalker = 2,
        },
        hard = {
            chaser = 3,
            patrol_warden = 3,
            lurker = 2,
            wailer = 3,
            stalker = 3,
        },
        nightmare = {
            chaser = 2,
            patrol_warden = 3,
            lurker = 3,
            wailer = 3,
            stalker = 4,
        }
    }

    local pool = weights[difficultyName] or weights.normal
    if counts.wailer >= 2 then
        pool.wailer = 0
    end
    if counts.stalker >= 2 then
        pool.stalker = 0
    end

    local total = 0
    for _, weight in pairs(pool) do
        total = total + weight
    end

    local roll = math.random(total)
    local running = 0
    for monsterType, weight in pairs(pool) do
        running = running + weight
        if roll <= running then
            counts[monsterType] = (counts[monsterType] or 0) + 1
            return monsterType
        end
    end

    counts.chaser = (counts.chaser or 0) + 1
    return "chaser"
end

local function buildVariants(grid)
    local floorVariants = {}
    local wallVariants = {}

    for y = 1, #grid do
        floorVariants[y] = {}
        wallVariants[y] = {}
        for x = 1, #grid[y] do
            floorVariants[y][x] = math.random(1, 2)
            wallVariants[y][x] = math.random(1, 3)
        end
    end

    return floorVariants, wallVariants
end

function ProcGen.generateRunData(difficultyName)
    local grid, rooms = ProcGen.generateRoomLayout(CONFIG.GRID_WIDTH, CONFIG.GRID_HEIGHT)
    Utils.shuffle(rooms)

    local difficulty = CONFIG.DIFFICULTY_SETTINGS[difficultyName] or CONFIG.DIFFICULTY_SETTINGS.normal
    local used = {}
    local monsters = {}
    local keys = {}
    local items = {}
    local darkZones = {}
    local safeZones = {}
    local shrines = {}

    local startRoom = cloneRoom(rooms[1])
    local recoveryRoom = cloneRoom(rooms[math.min(#rooms, 2)])
    local candidateRooms = {}
    for index = 3, #rooms do
        table.insert(candidateRooms, cloneRoom(rooms[index]))
    end
    Utils.shuffle(candidateRooms)

    local playerTile = chooseTile(startRoom, used)
    local playerStart = toWorld(playerTile)

    table.insert(safeZones, makeZone(startRoom, CONFIG.SAFE_ZONE_PADDING))
    table.insert(safeZones, makeZone(recoveryRoom, CONFIG.SAFE_ZONE_PADDING))
    table.insert(shrines, toWorld(chooseTile(recoveryRoom, used)))

    for index = 1, math.min(CONFIG.PROCGEN_DARK_ZONE_COUNT, #candidateRooms) do
        table.insert(darkZones, makeZone(candidateRooms[index], 0))
    end

    for _ = 1, difficulty.keyCount do
        local room = candidateRooms[math.random(#candidateRooms)] or recoveryRoom
        local tile = chooseTile(room, used)
        if tile then
            table.insert(keys, {coord = toWorld(tile)})
        end
    end

    local itemCount = math.max(2, math.floor((difficulty.spawnBudget * difficulty.itemMultiplier) + 0.5))
    for index = 1, itemCount do
        local room = candidateRooms[((index - 1) % math.max(#candidateRooms, 1)) + 1] or recoveryRoom
        local tile = chooseTile(room, used)
        if tile then
            local kind = "calming_tonic"
            if index % 3 == 0 then
                kind = "ward_charge"
            elseif index % 2 == 0 then
                kind = "speed_tonic"
            end
            table.insert(items, {coord = toWorld(tile), kind = kind})
        end
    end

    local monsterCounts = {
        chaser = 0,
        patrol_warden = 0,
        lurker = 0,
        wailer = 0,
        stalker = 0,
    }

    for index = 1, difficulty.spawnBudget do
        local room = candidateRooms[((index - 1) % math.max(#candidateRooms, 1)) + 1]
        if room then
            local tile = chooseTile(room, used)
            if tile then
                local monsterType = pickMonsterType(difficultyName, monsterCounts)
                local patrolTiles = roomTiles(room)
                local patrolPoints = {}
                for patrolIndex = 1, math.min(4, #patrolTiles) do
                    table.insert(patrolPoints, toWorld(patrolTiles[patrolIndex]))
                end
                table.insert(monsters, {
                    type = monsterType,
                    coord = toWorld(tile),
                    patrolPoints = patrolPoints,
                    room = room,
                })
            end
        end
    end

    local floorVariants, wallVariants = buildVariants(grid)

    return {
        grid = grid,
        rooms = rooms,
        playerStart = playerStart,
        monsters = monsters,
        keys = keys,
        items = items,
        safeZones = safeZones,
        darkZones = darkZones,
        shrines = shrines,
        floorVariants = floorVariants,
        wallVariants = wallVariants,
    }
end

return ProcGen
