-- FUA
    -- Immediate
        -- work on win and lose condition => copy win condition for what i did for lose condition, add a winning sound effect and screen of other sprites cheering for you like the shinji in a chair scene?
        -- add a quick time event when a player is caught by a ghost that gives them a chance of escaping death by beating a minigame, add a few different minigames w interesting inputs, and let ghosts track ur location only when u make noise by picking up items or keys or when running
        -- randomise key locations and spawn points for certain items in each room
    -- Graphics and Sound
        -- make the walking sound louder when running after consuming a potion
        -- implement limited light and VHS and shadow shaders in love2d
    -- UI
        -- add title screen, cutscenes, game over screen
        -- work in UI that shows the number of keys collected and a minimap(?) that shows rooms covered
        -- rework the screen to be 800 by 600, so there is vertical space on either side of the 600 by 600 grid, UI can be space on the side of the screen 
        -- during boss fight, the sidebars and UI disappear and the game shows a 800 by 600 full view window for a large arena
        -- OR have UI just be floating text sprites that fade away after a while; implement a system to achieve this
    -- Boss fight
        -- ensure complete integration with existing systems
        -- 3 phase boss battle
        -- fresh room design
        -- different attack patterns
    -- Misc
        -- check installation on different platforms (OSX, Windows, Linux)
        -- integrate make file commands into main program loop
        -- add a speed run option w a random seed taken in as input for room generation of layout.txt map file
        -- continue testing room rendering logic

-- ---------- PRESETS ----------

-- local inspect = require("inspect")

local elapsedTime = 0

local world = {

    player = {
        coord = {0,0},
        speed = 200,
        keyCount = 0,
        currRoom = "1",
        overallKeyCount = 0,
        alive = true,
    }, 

    monster = {
        coord = {},
        speed = 50,
    },

    wall = {
        coord = {},
    },

    item = {
        coord = {},
        buffSpeed = 200,
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

-- ---------- UTILITY ----------

function randomiseMap(fileName) -- generates map layouts which are applied on layout.txt before generating the map

    while true do

        math.randomseed(os.time())
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
    tbl.player.speed = 200
    tbl.player.keyCount = 0
    tbl.player.alive = true
    tbl.monster.coord = {}
    tbl.monster.speed = 50
    tbl.wall.coord = {}
    tbl.item.coord = {}
    tbl.item.buffSpeed = 200
    tbl.key.coord = {}
    tbl.key.totalCount = 0
    tbl.door.coord = {}
    return tbl
end

function checkCollision(ACoord, BCoord)
    return ACoord[1] + 20 > BCoord[1] and ACoord[2] + 20 > BCoord[2] and BCoord[1] + 20 > ACoord[1] and BCoord[2] + 20 > ACoord[2]
end

function checkPlayerOutBounds(playerCoord)
    return playerCoord[1] < 0 or playerCoord[1] > 600 or playerCoord[2] < 0 or playerCoord[2] > 600
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
    math.randomseed(os.time())
    local tem = {}
    for _,el in ipairs(worldMap) do
        table.insert(tem,el)
    end
    return tem[math.random(1,#tem)][1]
end

function startingCoord(roomNumber, map)
    math.randomseed(os.time())
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
    math.randomseed(os.time())
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
    math.randomseed(os.time())
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

    math.randomseed(os.time())

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

-- ---------- EVENT LOOP ----------

function love.load() -- load function that runs once at the beginning

    love.window.setTitle("tikrit")
    love.window.setMode(600,600)
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

    ambientNoiseSound:setLooping(true)
    love.audio.play(ambientNoiseSound)

end

function love.update(dt) -- update function that runs once every frame; dt is change in time and can be used for different tasks

    math.randomseed(os.time())

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
        -- love.event.quit()
    end

-- ---------- WIN CONDITION WHEN ALL KEYS COLLECTED ----------

-- FUA
-- further spruce up the win screen later
    if player.overallKeyCount == keys.globalCount and player.alive then
        serialize(string.format("map/%s.txt",player.currRoom))
        love.audio.stop(playerWalkingSound)
        love.audio.stop(ambientNoiseSound)
        love.event.quit()
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

    if player.speed > 200 then
        elapsedTime = elapsedTime + dt
        if elapsedTime > 5 then
            player.speed = player.speed - items.buffSpeed
            elapsedTime = 0
            print("item wore off, player speed", player.speed)
        end
    end

    -- print(player.speed)

-- ---------- ENTITY MOVEMENT -----------

-- monster logic

    for _, monsterCoord in ipairs(monsters.coord) do
        local xOffset = player.coord[1] - monsterCoord[1]
        local yOffset = player.coord[2] - monsterCoord[2]
        local angle = math.atan2(yOffset, xOffset) -- angle offset between ghost and player
        local dx = monsters.speed * math.cos(angle) -- ghost horizontal movement in x direction
        local dy = monsters.speed * math.sin(angle) -- ghost vertical movement in y direction
        monsterCoord[1] = monsterCoord[1] + (dt * dx) -- moves ghosts towards player
        monsterCoord[2] = monsterCoord[2] + (dt * dy)
    end

-- player input

    -- player escape screen

    if love.keyboard.isDown("escape") then 
        love.event.quit()
        print("event loop ended")
    end

    -- player movement

    if player.alive then

        storedX, storedY = player.coord[1], player.coord[2]

        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then 
            player.coord[2] = player.coord[2] - (dt * player.speed)
        elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then 
            player.coord[2] = player.coord[2] + (dt * player.speed)
        end

        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            player.coord[1] = player.coord[1] - (dt * player.speed)
        elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            player.coord[1] = player.coord[1] + (dt * player.speed)
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
                player.coord[1], player.coord[2] = storedX, storedY         
            end
        end

    -- player and door

        for _, doorCoord in ipairs(doors.coord) do
            if checkCollision(doorCoord, player.coord) then
                player.coord[1], player.coord[2] = storedX, storedY 
            end
        end

    -- player and monster

        for _, monsterCoord in ipairs(monsters.coord) do
            if checkCollision(monsterCoord, player.coord) then
                player.coord[1], player.coord[2] = storedX, storedY
                player.alive = false
                print("player died")
                love.audio.play(playerDeathSound)
                -- love.event.quit()
            end
        end

    -- player and item

        for i, itemCoord in ipairs(items.coord) do 
            if checkCollision(itemCoord, player.coord) then
                player.speed = player.speed + items.buffSpeed
                table.remove(items.coord, i)
                print("item picked up, player speed increased" , player.speed)
                love.audio.play(playerItemSound)
            end
        end

    -- player and key

        for q, keyCoord in ipairs(keys.coord) do
            if checkCollision(keyCoord, player.coord) then

                table.remove(keys.coord, q)
                player.keyCount = player.keyCount + 1
                player.overallKeyCount = player.overallKeyCount + 1
                print("key picked up", player.keyCount)
                love.audio.play(playerKeySound)

                if player.keyCount == keys.totalCount then
                    print("all keys collected, opening doors")
                    love.audio.play(doorOpenSound)
                    doors.coord = {}
                end

            end
        end
    end

end

function love.draw() -- draw function that runs once every frame

    math.randomseed(os.time())

    playerCoord = world.player.coord
    monsters = world.monster.coord
    walls = world.wall.coord
    doors = world.door.coord
    items = world.item.coord
    keys = world.key.coord

    love.graphics.clear()

    -- SETS OVERLAYS AND SHADERS

    love.graphics.setColor(0.5, 0.5, 0.5, 1) -- makes the screen darker by adding a gray overlay over all sprites

    -- DRAW FLOOR TILESET; everything else is drawn over this

    for _,val in ipairs(randomFloorMap) do
        if val[1] == world.player.currRoom then
            for _,el in ipairs(val[2]) do
                if el[2] == 1 then
                    love.graphics.draw(floorSprite1, el[1][1], el[1][2])
                elseif el[2] == 2 then
                    love.graphics.draw(floorSprite2, el[1][1], el[1][2])
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
                if inside(el[1], world.wall.coord) then
                    if el[2] == 1 then
                        love.graphics.draw(wallSprite1, el[1][1], el[1][2])
                    elseif el[2] == 2 then
                        love.graphics.draw(wallSprite2, el[1][1], el[1][2])
                    elseif el[2] == 3 then
                        love.graphics.draw(wallSprite3, el[1][1], el[1][2])
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
        love.graphics.draw(openedDoorSprite, openedDoorCoord[1], openedDoorCoord[2])
    end

    -- love.graphics.setColor(1, 0.5, 0.5)
    for _, doorCoord in ipairs(doors) do
        love.graphics.draw(closedDoorSprite, doorCoord[1], doorCoord[2])
        -- love.graphics.rectangle("fill", doorCoord[1], doorCoord[2], 20, 20)
    end

    -- DRAW MONSTERS

    -- love.graphics.setColor(1,0,0)

    if world.player.alive then 
        for _, monsterCoord in ipairs(monsters) do
            love.graphics.draw(ghostSprite1, monsterCoord[1], monsterCoord[2])
            -- love.graphics.rectangle("fill", monsterCoord[1], monsterCoord[2], 20, 20)
        end 
    else
    end

    -- DRAW ITEM PICKUPS

    -- love.graphics.setColor(0,0,1)
    for _, itemCoord in ipairs(items) do
        love.graphics.draw(itemSprite, itemCoord[1], itemCoord[2])
        -- love.graphics.rectangle("fill", itemCoord[1], itemCoord[2], 20, 20)
    end

    -- DRAW KEYS

    -- love.graphics.setColor(1,1,0)
    for _, keyCoord in ipairs(keys) do
        love.graphics.draw(closedChestSprite, keyCoord[1], keyCoord[2])
        -- love.graphics.rectangle("fill", keyCoord[1], keyCoord[2], 20, 20)
    end

    -- DRAW PLAYER CHARACTER

    if world.player.alive then
        love.graphics.draw(playerSprite, playerCoord[1], playerCoord[2])
    else
        love.graphics.draw(deadPlayerSprite, playerCoord[1], playerCoord[2])
    end

    -- love.graphics.setColor(0,1,0)
    -- love.graphics.rectangle("fill", playerCoord[1], playerCoord[2], 20, 20)

end