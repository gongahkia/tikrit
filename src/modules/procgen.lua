local CONFIG = require("config")
local Items = require("modules/items")
local Utils = require("modules/utils")

local ProcGen = {}

local function newGrid()
    local grid = {}
    for y = 1, CONFIG.GRID_HEIGHT do
        grid[y] = {}
        for x = 1, CONFIG.GRID_WIDTH do
            grid[y][x] = "snow"
        end
    end
    return grid
end

local function inBounds(x, y)
    return x >= 1 and x <= CONFIG.GRID_WIDTH and y >= 1 and y <= CONFIG.GRID_HEIGHT
end

local function setTile(grid, x, y, tile)
    if inBounds(x, y) then
        grid[y][x] = tile
    end
end

local function fillRect(grid, x, y, w, h, tile)
    for gy = y, y + h - 1 do
        for gx = x, x + w - 1 do
            setTile(grid, gx, gy, tile)
        end
    end
end

local function carvePath(grid, x1, y1, x2, y2)
    local x = x1
    local y = y1
    while x ~= x2 do
        setTile(grid, x, y, "path")
        x = x + (x2 > x and 1 or -1)
    end
    while y ~= y2 do
        setTile(grid, x, y, "path")
        y = y + (y2 > y and 1 or -1)
    end
    setTile(grid, x, y, "path")
end

local function buildBorder(grid)
    for x = 1, CONFIG.GRID_WIDTH do
        setTile(grid, x, 1, x % 2 == 0 and "rock" or "tree")
        setTile(grid, x, CONFIG.GRID_HEIGHT, x % 2 == 0 and "tree" or "rock")
    end
    for y = 1, CONFIG.GRID_HEIGHT do
        setTile(grid, 1, y, y % 2 == 0 and "rock" or "tree")
        setTile(grid, CONFIG.GRID_WIDTH, y, y % 2 == 0 and "tree" or "rock")
    end
end

local function worldCoord(gridX, gridY)
    return {(gridX - 1) * CONFIG.TILE_SIZE, (gridY - 1) * CONFIG.TILE_SIZE}
end

local function zoneCenter(zone)
    return {
        (zone.x + math.floor(zone.width / 2)) * CONFIG.TILE_SIZE,
        (zone.y + math.floor(zone.height / 2)) * CONFIG.TILE_SIZE,
    }
end

local function makeZone(x, y, width, height)
    return {x = x, y = y, width = width, height = height}
end

local function addCabin(grid, x, y, name, w, h)
    w = math.max(6, w or 6)
    h = math.max(5, h or 5)
    for gy = y, y + h - 1 do
        for gx = x, x + w - 1 do
            local border = gy == y or gy == y + h - 1 or gx == x or gx == x + w - 1
            setTile(grid, gx, gy, border and "cabin_wall" or "cabin_floor")
        end
    end

    local doorX = x + math.floor(w / 2)
    local doorY = y + h - 1
    local bedX = x + 1
    local bedY = y + 1
    local stoveX = x + w - 2
    local stoveY = y + 1
    local workbenchX = x + 1
    local workbenchY = y + h - 2

    setTile(grid, doorX, doorY, "path")
    setTile(grid, bedX, bedY, "cabin_bed")
    setTile(grid, stoveX, stoveY, "cabin_stove")
    setTile(grid, workbenchX, workbenchY, "cabin_workbench")

    return {
        type = "cabin",
        name = name or "Cabin",
        x = x,
        y = y,
        w = w,
        h = h,
        door = {x = doorX, y = doorY},
        bed = {x = bedX, y = bedY},
        stove = {x = stoveX, y = stoveY},
        workbench = {x = workbenchX, y = workbenchY},
        doorOpen = false,
    }
end

local function addCave(grid, x, y, w, h)
    w = math.max(7, w or 7)
    h = math.max(5, h or 5)
    for gy = y, y + h - 1 do
        for gx = x, x + w - 1 do
            local border = gy == y or gy == y + h - 1 or gx == x or gx == x + w - 1
            setTile(grid, gx, gy, border and "cave_wall" or "cave_floor")
        end
    end

    local mouthX = x + math.floor(w / 2)
    local mouthY = y + h - 1
    local bedX = x + math.max(1, math.floor(w / 2) - 1)
    local bedY = y + math.max(1, math.floor(h / 2))

    setTile(grid, mouthX, mouthY, "path")

    return {
        type = "cave",
        x = x,
        y = y,
        w = w,
        h = h,
        mouth = {x = mouthX, y = mouthY},
        bed = {x = bedX, y = bedY},
    }
end

local function canPlaceResource(grid, x, y)
    local tile = grid[y] and grid[y][x]
    return tile == "snow" or tile == "path" or tile == "fire_safe" or tile == "cabin_floor" or tile == "cave_floor"
end

local function addResourceNode(list, nodeType, x, y, payload)
    local node = {
        type = nodeType,
        coord = worldCoord(x, y),
        opened = false,
    }
    if payload then
        for key, value in pairs(payload) do
            node[key] = value
        end
    end
    table.insert(list, node)
end

local function randomLoot()
    local options = {
        {"canned_food", 1},
        {"water", 1},
        {"cloth", 1},
        {"tea", 1},
        {"bandage", 1},
        {"painkillers", 1},
        {"antiseptic", 1},
        {"antibiotics", 1},
        {"tinder", 2},
        {"matches", 3},
        {"sticks", 2},
        {"firewood", 1},
        {"snow", 1},
        {"raw_meat", 1},
        {"raw_fish", 1},
        {"torch", 1},
        {"flare", 1},
        {"accelerant", 1},
        {"charcoal", 1},
        {"arrow", 2},
        {"fishing_tackle", 1},
        {"bow", 1},
        {"snare", 1},
    }
    local choice = options[math.random(#options)]
    return {Items.create(choice[1], choice[2])}
end

local function makeFishingSpot(x, y, name)
    return {
        coord = worldCoord(x, y),
        name = name or "Fishing Hole",
    }
end

local function makeMapNode(x, y, name)
    return {
        coord = worldCoord(x, y),
        name = name or "Overlook",
    }
end

local function makeClimbNode(x, y, targetX, targetY, name)
    return {
        coord = worldCoord(x, y),
        targetCoord = worldCoord(targetX, targetY),
        name = name or "Rope Climb",
    }
end

local function makeWorkbench(x, y, name)
    return {
        coord = worldCoord(x, y),
        name = name or "Workbench",
    }
end

local function makeCuringStation(x, y, name)
    return {
        coord = worldCoord(x, y),
        name = name or "Curing Rack",
    }
end

local function makeCarcass(kind, x, y)
    return {
        kind = kind,
        coord = worldCoord(x, y),
        meat = kind == "deer" and 3 or 1,
        hide = kind == "deer" and 1 or 1,
        gut = kind == "deer" and 2 or (kind == "rabbit" and 1 or 0),
        feathers = kind == "fish" and 0 or 2,
    }
end

local function placeLake(grid)
    local weakIceTiles = {}
    local lakeArea = {x = 11, y = 10, w = 8, h = 6}

    fillRect(grid, lakeArea.x, lakeArea.y, lakeArea.w, lakeArea.h, "ice")

    local candidates = {}
    for y = lakeArea.y, lakeArea.y + lakeArea.h - 1 do
        for x = lakeArea.x, lakeArea.x + lakeArea.w - 1 do
            table.insert(candidates, {x = x, y = y})
        end
    end
    Utils.shuffle(candidates)

    local weakIceCount = math.random(CONFIG.WEAK_ICE_MIN, CONFIG.WEAK_ICE_MAX)
    for index = 1, weakIceCount do
        local tile = candidates[index]
        setTile(grid, tile.x, tile.y, "weak_ice")
        table.insert(weakIceTiles, {x = tile.x, y = tile.y})
    end

    return weakIceTiles, lakeArea
end

local function generateProceduralRunData(difficultyName)
    local difficultyKey = CONFIG.DIFFICULTY_ALIASES[difficultyName] or difficultyName
    local difficulty = CONFIG.DIFFICULTY_SETTINGS[difficultyKey] or CONFIG.DIFFICULTY_SETTINGS.voyageur
    local grid = newGrid()
    buildBorder(grid)

    local structures = {
        addCabin(grid, 3, 4, "Ranger Cabin"),
        addCabin(grid, 21, 20, "Trapline Cabin"),
        addCave(grid, 20, 4),
    }

    local weakIceTiles, lakeArea = placeLake(grid)
    fillRect(grid, 6, 15, 4, 3, "fire_safe")

    carvePath(grid, structures[1].door.x, structures[1].door.y, 8, 16)
    carvePath(grid, 8, 16, 11, 13)
    carvePath(grid, 18, 13, 24, 13)
    carvePath(grid, 24, 13, structures[3].mouth.x, structures[3].mouth.y)
    carvePath(grid, 18, 15, structures[2].door.x, structures[2].door.y)

    for x = 7, 9 do
        for y = 19, 23 do
            if grid[y][x] == "snow" then
                setTile(grid, x, y, (x + y) % 2 == 0 and "tree" or "rock")
            end
        end
    end

    local resourceNodes = {}
    local safeSleepSpots = {
        worldCoord(structures[1].bed.x, structures[1].bed.y),
        worldCoord(structures[2].bed.x, structures[2].bed.y),
        worldCoord(structures[3].bed.x, structures[3].bed.y),
    }
    local temperatureBands = {
        {type = "shelter", zone = makeZone(3, 4, 6, 5), modifier = 8},
        {type = "shelter", zone = makeZone(21, 20, 6, 5), modifier = 8},
        {type = "cave", zone = makeZone(20, 4, 7, 5), modifier = 10},
        {type = "lake", zone = lakeArea, modifier = -6},
    }
    local workbenches = {
        makeWorkbench(structures[1].workbench.x, structures[1].workbench.y, "Ranger Workbench"),
        makeWorkbench(structures[2].workbench.x, structures[2].workbench.y, "Trapline Workbench"),
    }
    local curingStations = {
        makeCuringStation(structures[1].workbench.x, structures[1].workbench.y, "Ranger Curing Rack"),
        makeCuringStation(structures[2].workbench.x, structures[2].workbench.y, "Trapline Curing Rack"),
    }
    local fishingSpots = {
        makeFishingSpot(lakeArea.x + 1, lakeArea.y + 2, "Lower Fishing Hole"),
        makeFishingSpot(lakeArea.x + lakeArea.w - 2, lakeArea.y + 3, "North Fishing Hole"),
    }
    local climbNodes = {
        makeClimbNode(18, 7, 10, 4, "Ridge Rope"),
    }
    local mapNodes = {
        makeMapNode(10, 4, "Frozen Overlook"),
        makeMapNode(structures[3].mouth.x, structures[3].mouth.y, "Cave Mouth Overlook"),
    }
    local carcasses = {
        makeCarcass("deer", 22, 24),
    }
    local pointsOfInterest = {
        {name = "Ranger Cabin", coord = worldCoord(structures[1].bed.x, structures[1].bed.y)},
        {name = "Trapline Cabin", coord = worldCoord(structures[2].bed.x, structures[2].bed.y)},
        {name = "Frozen Lake", coord = worldCoord(lakeArea.x + 3, lakeArea.y + 2)},
        {name = "North Cave", coord = worldCoord(structures[3].mouth.x, structures[3].mouth.y)},
    }

    addResourceNode(resourceNodes, "cache", structures[1].x + 3, structures[1].y + 2, {loot = randomLoot()})
    addResourceNode(resourceNodes, "cache", structures[2].x + 3, structures[2].y + 2, {loot = randomLoot()})
    addResourceNode(resourceNodes, "loot", 8, 16, {loot = randomLoot()})
    addResourceNode(resourceNodes, "loot", 24, 13, {loot = randomLoot()})
    addResourceNode(resourceNodes, "loot", 22, 6, {loot = randomLoot()})
    addResourceNode(resourceNodes, "loot", 24, 22, {loot = randomLoot()})

    local lootTarget = math.max(CONFIG.RESOURCE_LOOT_MIN, math.floor(CONFIG.RESOURCE_LOOT_MAX * difficulty.lootMultiplier))
    local lootCandidates = {
        {x = 14, y = 8}, {x = 16, y = 19}, {x = 11, y = 20},
        {x = 18, y = 23}, {x = 9, y = 9}, {x = 26, y = 10},
    }
    Utils.shuffle(lootCandidates)
    while #resourceNodes < lootTarget + 2 do
        local candidate = table.remove(lootCandidates)
        if not candidate then
            break
        end
        addResourceNode(resourceNodes, "loot", candidate.x, candidate.y, {loot = randomLoot()})
    end

    local woodTarget = math.random(CONFIG.RESOURCE_WOOD_MIN, CONFIG.RESOURCE_WOOD_MAX)
    local woodCandidates = {}
    for y = 2, CONFIG.GRID_HEIGHT - 1 do
        for x = 2, CONFIG.GRID_WIDTH - 1 do
            if canPlaceResource(grid, x, y) and math.abs(x - 15) + math.abs(y - 13) > 6 then
                table.insert(woodCandidates, {x = x, y = y})
            end
        end
    end
    Utils.shuffle(woodCandidates)
    for index = 1, woodTarget do
        local candidate = woodCandidates[index]
        if candidate then
            addResourceNode(resourceNodes, "wood", candidate.x, candidate.y, {
                loot = {
                    Items.create("sticks", math.random(2, 4)),
                    Items.create("firewood", 1),
                    Items.create("snow", 1),
                },
            })
        end
    end

    local wolfTerritory = makeZone(17, 10, 10, 9)
    local wolves = {}
    for index = 1, difficulty.wolfCount do
        table.insert(wolves, {
            kind = "wolf",
            coord = worldCoord(20 + index * 2, 12 + index),
            territory = wolfTerritory,
            territoryCenter = zoneCenter(wolfTerritory),
            state = "roam",
            target = nil,
            fearHours = 0,
        })
    end

    local rabbitZones = {
        makeZone(4, 9, 5, 4),
        makeZone(5, 22, 5, 4),
    }
    local deerZone = makeZone(19, 23, 7, 4)

    local rabbits = {}
    for _, zone in ipairs(rabbitZones) do
        table.insert(rabbits, {
            kind = "rabbit",
            zone = zone,
            coord = worldCoord(zone.x + 1, zone.y + 1),
            speed = 20,
        })
    end

    local deer = {
        {
            kind = "deer",
            zone = deerZone,
            coord = worldCoord(deerZone.x + 2, deerZone.y + 1),
            speed = 24,
        }
    }

    return {
        grid = grid,
        playerStart = worldCoord(structures[1].bed.x, structures[1].bed.y),
        structures = structures,
        resourceNodes = resourceNodes,
        fires = {},
        traps = {},
        carcasses = carcasses,
        fishingSpots = fishingSpots,
        climbNodes = climbNodes,
        mapNodes = mapNodes,
        workbenches = workbenches,
        curingStations = curingStations,
        curing = {},
        mappedTiles = {},
        pointsOfInterest = pointsOfInterest,
        wildlife = {
            wolves = wolves,
            rabbits = rabbits,
            deer = deer,
        },
        weather = {
            current = "clear",
            hoursUntilChange = math.random(CONFIG.WEATHER_CHANGE_MIN_HOURS, CONFIG.WEATHER_CHANGE_MAX_HOURS),
        },
        timeOfDay = 8,
        dayCount = 1,
        temperatureBands = temperatureBands,
        safeSleepSpots = safeSleepSpots,
        weakIceTiles = weakIceTiles,
        snowShelters = {},
        wolfTerritory = wolfTerritory,
        rabbitZones = rabbitZones,
        deerZone = deerZone,
        carcassSites = {
            {coord = worldCoord(22, 24), kind = "deer"},
        },
        source = "procedural",
    }
end

local function normalizeLayout(layout)
    local lines = (layout and layout.lines) or {}
    local grid = {}
    for y = 1, CONFIG.GRID_HEIGHT do
        local line = lines[y] or ""
        grid[y] = {}
        for x = 1, CONFIG.GRID_WIDTH do
            local symbol = line:sub(x, x)
            grid[y][x] = symbol ~= "" and symbol or " "
        end
    end
    return grid
end

local function firstSymbol(symbolGrid, symbol)
    for y = 1, CONFIG.GRID_HEIGHT do
        for x = 1, CONFIG.GRID_WIDTH do
            if symbolGrid[y][x] == symbol then
                return x, y
            end
        end
    end
    return nil
end

local function collectComponents(symbolGrid, symbol)
    local components = {}
    local visited = {}
    local directions = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
    }

    for y = 1, CONFIG.GRID_HEIGHT do
        visited[y] = {}
    end

    for y = 1, CONFIG.GRID_HEIGHT do
        for x = 1, CONFIG.GRID_WIDTH do
            if symbolGrid[y][x] == symbol and not visited[y][x] then
                local queue = {{x = x, y = y}}
                local index = 1
                local cells = {}
                local minX, maxX = x, x
                local minY, maxY = y, y
                visited[y][x] = true

                while index <= #queue do
                    local current = queue[index]
                    index = index + 1
                    table.insert(cells, current)
                    minX = math.min(minX, current.x)
                    maxX = math.max(maxX, current.x)
                    minY = math.min(minY, current.y)
                    maxY = math.max(maxY, current.y)

                    for _, direction in ipairs(directions) do
                        local nextX = current.x + direction[1]
                        local nextY = current.y + direction[2]
                        if inBounds(nextX, nextY)
                            and symbolGrid[nextY][nextX] == symbol
                            and not visited[nextY][nextX] then
                            visited[nextY][nextX] = true
                            table.insert(queue, {x = nextX, y = nextY})
                        end
                    end
                end

                table.insert(components, {
                    cells = cells,
                    x = minX,
                    y = minY,
                    width = maxX - minX + 1,
                    height = maxY - minY + 1,
                })
            end
        end
    end

    return components
end

local function normalizeBounds(component, minWidth, minHeight)
    local centerX = component.x + math.floor((component.width - 1) / 2)
    local centerY = component.y + math.floor((component.height - 1) / 2)
    local width = math.max(component.width, minWidth)
    local height = math.max(component.height, minHeight)
    local maxX = math.max(2, CONFIG.GRID_WIDTH - width)
    local maxY = math.max(2, CONFIG.GRID_HEIGHT - height)

    return {
        x = Utils.clamp(centerX - math.floor(width / 2), 2, maxX),
        y = Utils.clamp(centerY - math.floor(height / 2), 2, maxY),
        width = width,
        height = height,
    }
end

local function applyLayoutTiles(grid, symbolGrid)
    local weakIceTiles = {}
    local shelterCells = {}

    for y = 1, CONFIG.GRID_HEIGHT do
        for x = 1, CONFIG.GRID_WIDTH do
            local symbol = symbolGrid[y][x]
            if symbol == "#" then
                setTile(grid, x, y, "rock")
            elseif symbol == "." then
                setTile(grid, x, y, "snow")
            elseif symbol == " " then
                setTile(grid, x, y, "path")
            elseif symbol == "F" then
                setTile(grid, x, y, "fire_safe")
            elseif symbol == "L" then
                setTile(grid, x, y, "ice")
            elseif symbol == "W" then
                setTile(grid, x, y, "weak_ice")
                table.insert(weakIceTiles, {x = x, y = y})
            elseif symbol == "B" then
                setTile(grid, x, y, "cabin_workbench")
            elseif symbol == "H" then
                setTile(grid, x, y, "snow")
                table.insert(shelterCells, {x = x, y = y})
            else
                setTile(grid, x, y, "snow")
            end
        end
    end

    return weakIceTiles, shelterCells
end

local function nodeTypeForTile(tile)
    if tile == "cabin_floor" or tile == "cabin_bed" or tile == "cabin_stove" or tile == "cabin_workbench" or tile == "cave_floor" then
        return "cache"
    end
    return "loot"
end

local function generateEditorRunData(difficultyName, layout)
    local symbolGrid = normalizeLayout(layout)
    local grid = newGrid()
    local structures = {}
    local resourceNodes = {}
    local safeSleepSpots = {}
    local temperatureBands = {}
    local snowShelters = {}
    local weakIceTiles, shelterCells = applyLayoutTiles(grid, symbolGrid)
    local workbenches = {}
    local curingStations = {}
    local fishingSpots = {}
    local climbNodes = {}
    local mapNodes = {}
    local carcasses = {}
    local pointsOfInterest = {}

    local cabinCount = 0
    for _, component in ipairs(collectComponents(symbolGrid, "C")) do
        local bounds = normalizeBounds(component, 6, 5)
        cabinCount = cabinCount + 1
        local cabin = addCabin(grid, bounds.x, bounds.y, string.format("Editor Cabin %d", cabinCount), bounds.width, bounds.height)
        table.insert(structures, cabin)
        table.insert(safeSleepSpots, worldCoord(cabin.bed.x, cabin.bed.y))
        table.insert(workbenches, makeWorkbench(cabin.workbench.x, cabin.workbench.y, string.format("Editor Workbench %d", cabinCount)))
        table.insert(curingStations, makeCuringStation(cabin.workbench.x, cabin.workbench.y, string.format("Editor Curing Rack %d", cabinCount)))
        table.insert(pointsOfInterest, {name = cabin.name, coord = worldCoord(cabin.bed.x, cabin.bed.y)})
        table.insert(temperatureBands, {
            type = "shelter",
            zone = makeZone(bounds.x, bounds.y, bounds.width, bounds.height),
            modifier = 8,
        })
    end

    for _, component in ipairs(collectComponents(symbolGrid, "V")) do
        local bounds = normalizeBounds(component, 7, 5)
        local cave = addCave(grid, bounds.x, bounds.y, bounds.width, bounds.height)
        table.insert(structures, cave)
        table.insert(safeSleepSpots, worldCoord(cave.bed.x, cave.bed.y))
        table.insert(pointsOfInterest, {name = "Editor Cave", coord = worldCoord(cave.mouth.x, cave.mouth.y)})
        table.insert(temperatureBands, {
            type = "cave",
            zone = makeZone(bounds.x, bounds.y, bounds.width, bounds.height),
            modifier = 10,
        })
    end

    for _, component in ipairs(collectComponents(symbolGrid, "L")) do
        table.insert(temperatureBands, {
            type = "lake",
            zone = makeZone(component.x, component.y, component.width, component.height),
            modifier = -6,
        })
    end

    for _, cell in ipairs(shelterCells) do
        table.insert(snowShelters, {
            coord = worldCoord(cell.x, cell.y),
            integrity = 100,
        })
        table.insert(safeSleepSpots, worldCoord(cell.x, cell.y))
        table.insert(temperatureBands, {
            type = "snow_shelter",
            zone = makeZone(cell.x, cell.y, 1, 1),
            modifier = 6,
        })
    end

    for _, component in ipairs(collectComponents(symbolGrid, "O")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        addResourceNode(resourceNodes, nodeTypeForTile(grid[centerY][centerX]), centerX, centerY, {loot = randomLoot()})
    end

    for _, component in ipairs(collectComponents(symbolGrid, "B")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        table.insert(workbenches, makeWorkbench(centerX, centerY, "Editor Workbench"))
        table.insert(curingStations, makeCuringStation(centerX, centerY, "Editor Curing Rack"))
    end

    for _, component in ipairs(collectComponents(symbolGrid, "I")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        table.insert(fishingSpots, makeFishingSpot(centerX, centerY, "Editor Fishing Hole"))
    end

    for _, component in ipairs(collectComponents(symbolGrid, "M")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        table.insert(mapNodes, makeMapNode(centerX, centerY, "Editor Overlook"))
    end

    for _, component in ipairs(collectComponents(symbolGrid, "P")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        table.insert(climbNodes, makeClimbNode(centerX, centerY, math.max(2, centerX - 2), math.max(2, centerY - 2), "Editor Rope"))
    end

    for _, component in ipairs(collectComponents(symbolGrid, "Q")) do
        local centerX = component.x + math.floor(component.width / 2)
        local centerY = component.y + math.floor(component.height / 2)
        table.insert(carcasses, makeCarcass("deer", centerX, centerY))
    end

    local wolfZones = {}
    local wolves = {}
    for _, component in ipairs(collectComponents(symbolGrid, "K")) do
        local zone = makeZone(component.x, component.y, component.width, component.height)
        table.insert(wolfZones, zone)
        table.insert(wolves, {
            kind = "wolf",
            coord = worldCoord(component.x + math.floor(component.width / 2), component.y + math.floor(component.height / 2)),
            territory = zone,
            territoryCenter = zoneCenter(zone),
            state = "roam",
            target = nil,
            fearHours = 0,
        })
    end

    local rabbitZones = {}
    local rabbits = {}
    for _, component in ipairs(collectComponents(symbolGrid, "R")) do
        local zone = makeZone(component.x, component.y, component.width, component.height)
        table.insert(rabbitZones, zone)
        table.insert(rabbits, {
            kind = "rabbit",
            zone = zone,
            coord = worldCoord(component.x + math.floor(component.width / 2), component.y + math.floor(component.height / 2)),
            speed = 20,
        })
    end

    local deerZones = {}
    local deer = {}
    for _, component in ipairs(collectComponents(symbolGrid, "D")) do
        local zone = makeZone(component.x, component.y, component.width, component.height)
        table.insert(deerZones, zone)
        table.insert(deer, {
            kind = "deer",
            zone = zone,
            coord = worldCoord(component.x + math.floor(component.width / 2), component.y + math.floor(component.height / 2)),
            speed = 24,
        })
    end

    local startX, startY = firstSymbol(symbolGrid, "@")
    local playerStart
    if startX and startY then
        playerStart = worldCoord(startX, startY)
    elseif safeSleepSpots[1] then
        playerStart = {safeSleepSpots[1][1], safeSleepSpots[1][2]}
    else
        playerStart = worldCoord(2, 2)
    end

    return {
        grid = grid,
        playerStart = playerStart,
        structures = structures,
        resourceNodes = resourceNodes,
        fires = {},
        traps = {},
        carcasses = carcasses,
        fishingSpots = fishingSpots,
        climbNodes = climbNodes,
        mapNodes = mapNodes,
        workbenches = workbenches,
        curingStations = curingStations,
        curing = {},
        mappedTiles = {},
        pointsOfInterest = pointsOfInterest,
        wildlife = {
            wolves = wolves,
            rabbits = rabbits,
            deer = deer,
        },
        weather = {
            current = "clear",
            hoursUntilChange = math.random(CONFIG.WEATHER_CHANGE_MIN_HOURS, CONFIG.WEATHER_CHANGE_MAX_HOURS),
        },
        timeOfDay = 8,
        dayCount = 1,
        temperatureBands = temperatureBands,
        safeSleepSpots = safeSleepSpots,
        weakIceTiles = weakIceTiles,
        snowShelters = snowShelters,
        wolfTerritory = wolfZones[1],
        rabbitZones = rabbitZones,
        deerZone = deerZones[1],
        carcassSites = {},
        source = "editor",
        editorLayout = {
            filename = layout and layout.filename or "custom.txt",
        },
    }
end

function ProcGen.generateRunData(difficultyName, options)
    options = options or {}
    if options.layout then
        return generateEditorRunData(difficultyName, options.layout)
    end
    return generateProceduralRunData(difficultyName)
end

return ProcGen
