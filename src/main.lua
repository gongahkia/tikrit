-- FUA

-- immediate
    -- handle update function when entering another room to render map for entering map 2 after saving state for map 1
        -- determine location of player at door based on the previous door location
        -- then write code to determine which D should be rendered as a door and which should just be rendered as a wall
        -- subsequently write code to determine which map to open based on an overall render map in the following style
--[[
+------+                  
| map1 |                  
|      |                  
+------+                  
+------+ +------+ +------+
| map2 | | map6 | | map4 |
|      | |      | |      |
+------+ +------+ +------+
+------+          +------+
| map3 |          | map7 |
|      |          |      |
+------+          +------+
                  +------+
                  |  ap5 |
                  |      |
                  +------+
]]--
        -- link rooms together
    -- map generation
        -- work out system to track player current room on a map => store each map as a file name like map1 - map7(?)
            -- randomise which of the 4 doors open
            -- implement roguelike room generation similar to miziziz roguelike, where template rooms are created and items can be spawned in subsequently, rooms are randomly linked together
        -- map generation => ensure that one block tall corridors cannot be generated
    -- monster logic
        -- perhaps consider making enemies ghosts or implement different behaviour that circumvents the path-finding issue, maybe ghosts can just go through walls LOL
            -- implement seperate path finding algorithm that is easier than astar to reduce loading time
            -- https://youtu.be/rbYxbIMOZkE?si=OaYR9GwL9hIovhGO
        -- work out how to slow down monster movement
        -- implement mutliple monsters
    -- graphics
        -- figure out how to implement dithering for light surrounding the player
        -- import sprites
        -- animation for sprites

-- 2 implement
    -- check installation on different platforms (OSX, Windows, Linux)

-- ---------- PRESETS ----------

-- local inspect = require("inspect")

local elapsedTime = 0

local world = {

    player = {
        coord = {0,0},
        speed = 200,
        keyCount = 0,
        currRoom = 0,
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

function inside(targetCoord, table)
    for _, coord in ipairs(table) do
        if targetCoord[1] == coord[1] and targetCoord[2] == coord[2] then
            return true
        end 
    end
    return false
end

-- ---------- UTILITY ----------

-- FUA 
-- add code for map generation via wave function collapse or some cellular automata function to generate a random map
function genMap()

end

-- writes the map data to a txt file
function serialize(fileName) 
    local fhand = io.open(fileName, "w")
    local fin = ""
    for y = 0, 580, 20 do
        local tem = ""
        for x = 0, 580, 20 do
            if inside({x,y}, world.wall.coord) then
                tem = tem .. "#"
            elseif #world.monster.coord ~= 0 and inside({x,y}, world.monster.coord) then
                tem = tem .. "!"
            elseif #world.item.coord ~= 0 and inside({x,y}, world.item.coord) then
                tem = tem .. "?"
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
        return 2
    elseif playerCoord[1] > 600 then
        return 3
    elseif playerCoord[2] < 0 then 
        return 1
    elseif playerCoord[2] > 600 then
        return 4
    end
end

-- ---------- EVENT LOOP ----------

function love.load() -- load function that runs once at the beginning; sets defaults
    love.window.setTitle("tikrit")
    love.window.setMode(600,600)
    print(deserialize("map/map1.txt"))
end

-- FUA
-- add other update loops here for the monster logic, encapsulate in a function based on player location => if too slow, then determine based on every 5 squares player moves
-- find a simpler quicker algorithm instead of astar
function love.update(dt) -- update function that runs once every frame; dt is change in time and can be used for different tasks

    player = world.player
    monsters = world.monster
    walls = world.wall
    doors = world.door
    items = world.item
    keys = world.key

-- ---------- PLAYER MOVE DIFFERENT ROOM ----------

    if checkPlayerOutBounds(player.coord) then
        print("player moves to room " .. checkPlayerRoom(player.coord))
        love.event.quit()
        serialize("map/map1-saved.txt")
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
    -- FUA implement something here based on above instructions

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
            print("key pickedup", player.keyCount)

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

    love.graphics.setColor(1,1,1)
    for _, wallCoord in ipairs(walls) do
        love.graphics.rectangle("fill", wallCoord[1], wallCoord[2], 20, 20)
    end 

    love.graphics.setColor(1, 0.5, 0.5)
    for _, doorCoord in ipairs(doors) do
        love.graphics.rectangle("fill", doorCoord[1], doorCoord[2], 20, 20)
    end

    love.graphics.setColor(1,0,0)
    for _, monsterCoord in ipairs(monsters) do
        love.graphics.rectangle("fill", monsterCoord[1], monsterCoord[2], 20, 20)
    end 

    love.graphics.setColor(0,0,1)
    for _, itemCoord in ipairs(items) do
        love.graphics.rectangle("fill", itemCoord[1], itemCoord[2], 20, 20)
    end

    love.graphics.setColor(1,1,0)
    for _, keyCoord in ipairs(keys) do
        love.graphics.rectangle("fill", keyCoord[1], keyCoord[2], 20, 20)
    end

    love.graphics.setColor(0,1,0)
    love.graphics.rectangle("fill", playerCoord[1], playerCoord[2], 20, 20)

end