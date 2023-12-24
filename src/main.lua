-- FUA

-- immediate
    -- debug line 529 and 729 to work out why I can't load player sprites to the screen
    -- work out code to determine which sprite to paint for which kind of floor, wall and door, render it dynamically, vary the walls floor and door tiles
    -- add offset to render 16 by 16 sprite in centre of a 20 by 20 frame, with 2px offset on each side of the sprite? (add in love.draw() portion)
    -- add sprites for dead player that appears when player touches ghost
    -- add sprites for opening chest (?)
    -- add logic for variations of player character who can move faster, teleport and other upgrades
    -- add sprites for other characters and shop keeper and ranged attacks from Kenny's tiny dungeon art pack
    -- randomise key locations and spawn points for certain items in each room
    -- add title screen, cutscenes, game over screen
    -- figure out how to implement dithering for light surrounding the player
    -- add ambient noise and sounds similar to this video (https://youtu.be/WAk6BzOKlzw?si=6nmL9BblVLtzDa63) for walking and unlocking to make game unnerving and for monsters
    -- integrate make file commands into main program loop
    -- graphics
        -- import sprites
        -- animation for sprites
        -- import background sprites to be painted below every other layer in the love.draw() function
    -- continue testing room rendering logic
    -- monster logic
        -- perhaps consider making enemies ghosts that can ignore walls or implement different behaviour that circumvents the path-finding issue, maybe ghosts can just go through walls LOL
            -- implement seperate path finding algorithm that is easier than astar to reduce loading time
            -- https://youtu.be/rbYxbIMOZkE?si=OaYR9GwL9hIovhGO
        -- work out how to slow down monster movement
        -- taking speed boost increases your speed but also the sound of your steps, which attracts monsters to your location
        -- implement state machine for monsters similar to this enemy ai (https://youtu.be/LojAdI4eQsM?si=xFz7FxsnvlLw8fDM)
        -- implement mutliple monsters
    -- implement a function that checks if a room only has one connection, if so, then it removes all key drops since those are unnecessary and replaces them with something else
    -- check installation on different platforms (OSX, Windows, Linux)

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
    }, 

    monster = {
        coord = {},
        speed = 150,
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
    tbl.monster.coord = {}
    tbl.monster.speed = 150
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

-- ---------- EVENT LOOP ----------

function love.load() -- load function that runs once at the beginning

    love.window.setTitle("tikrit")
    love.window.setMode(600,600)
    randomiseMap("map/layout.txt")
    worldMap = generateMap("map/layout.txt")
    world.key.globalCount = totalKeys(worldMap)
    playerRoomCoord = validStartingRoomAndCoord(worldMap)
    world.player.currRoom = playerRoomCoord[1]
    world.player.coord = playerRoomCoord[2]
    deserialize(string.format("map/%s.txt", playerRoomCoord[1]))
    doorList = extractDoors(worldMap, world.player.currRoom) -- checks connecting doors available and replace doors that should not exist with walls
    addDoorAsWall(world,doorList)
    world.door.coord = doorList

    -- print(inspect(worldMap))
    -- print(totalKeys(worldMap))
    -- print(inspect(validStartingRoomAndCoord(worldMap)))

    -- SPRITE LOADING

    -- playerSprite = love.graphics.newImage("../asset/sprite/player-default.png")

end

function love.update(dt) -- update function that runs once every frame; dt is change in time and can be used for different tasks

    player = world.player
    monsters = world.monster
    walls = world.wall
    doors = world.door
    items = world.item
    keys = world.key

-- ---------- WIN CONDITION WHEN ALL KEYS COLLECTED ----------

-- FUA
-- further spruce up this screen later
    if player.overallKeyCount == keys.globalCount then
        serialize(string.format("map/%s.txt",player.currRoom))
        love.event.quit()
    end 

-- ---------- PLAYER MOVE DIFFERENT ROOM ----------

    if checkPlayerOutBounds(player.coord) then -- player moves to different room, instantiate new room

        playerLoc = checkPlayerRoom(player.coord) 
        serialize(string.format("map/%s.txt",player.currRoom)) -- save past room data
        world = reset(world) -- resets world table data
        nextRoom = checkNextRoom(worldMap, player.currRoom, playerLoc[1])
        deserialize(string.format("map/%s.txt",nextRoom)) -- load new room data
        player.currRoom = nextRoom
        player.coord = playerLoc[2] -- new player location

        doorList = extractDoors(worldMap, world.player.currRoom) -- checks connecting doors available and replace doors that should not exist with walls
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
-- FUA
-- add code here

-- player input

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

    if love.keyboard.isDown("escape") then 
        love.event.quit()
        print("event loop ended")
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
            love.event.quit()
            print("player died")
        end
    end

-- player and item

    for i, itemCoord in ipairs(items.coord) do 
        if checkCollision(itemCoord, player.coord) then
            player.speed = player.speed + items.buffSpeed
            table.remove(items.coord, i)
            print("item picked up, player speed increased" , player.speed)
        end
    end

-- player and key

    for q, keyCoord in ipairs(keys.coord) do
        if checkCollision(keyCoord, player.coord) then

            table.remove(keys.coord, q)
            player.keyCount = player.keyCount + 1
            player.overallKeyCount = player.overallKeyCount + 1
            print("key picked up", player.keyCount)

            if player.keyCount == keys.totalCount then
                print("all keys collected, opening doors")
                doors.coord = {}
            end

        end
    end

end

function love.draw() -- draw function that runs once every frame

    playerCoord = world.player.coord
    monsters = world.monster.coord
    walls = world.wall.coord
    doors = world.door.coord
    items = world.item.coord
    keys = world.key.coord

    love.graphics.clear()

    -- draw floor background tileset; everything else is drawn over this

    love.graphics.setColor(173/255, 216/255, 230/255, 1)
    love.graphics.rectangle("fill",0,0,600,600) -- sets background tile set, all the other graphics are overlayed on top

    -- draw walls

    love.graphics.setColor(1,1,1)
    for _, wallCoord in ipairs(walls) do
        love.graphics.rectangle("fill", wallCoord[1], wallCoord[2], 20, 20)
    end 

    -- draw doors

    love.graphics.setColor(1, 0.5, 0.5)
    for _, doorCoord in ipairs(doors) do
        love.graphics.rectangle("fill", doorCoord[1], doorCoord[2], 20, 20)
    end

    -- draw monsters

    love.graphics.setColor(1,0,0)
    for _, monsterCoord in ipairs(monsters) do
        love.graphics.rectangle("fill", monsterCoord[1], monsterCoord[2], 20, 20)
    end 

    -- draw item pickups

    love.graphics.setColor(0,0,1)
    for _, itemCoord in ipairs(items) do
        love.graphics.rectangle("fill", itemCoord[1], itemCoord[2], 20, 20)
    end

    -- draw keys 

    love.graphics.setColor(1,1,0)
    for _, keyCoord in ipairs(keys) do
        love.graphics.rectangle("fill", keyCoord[1], keyCoord[2], 20, 20)
    end

    -- draw player character

    love.graphics.setColor(0,1,0)
    love.graphics.rectangle("fill", playerCoord[1], playerCoord[2], 20, 20)
    -- love.graphics.draw(playerSprite, playerCoord[1], playerCoord[2])

end