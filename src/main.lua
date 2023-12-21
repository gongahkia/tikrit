-- FUA

-- immediate
    -- exit door for player (?)
    -- link rooms together
        -- implement roguelike room generation similar to miziziz roguelike, where template rooms are created and items can be spawned in subsequently, rooms are randomly linked together
    -- perhaps consider making enemies ghosts or implement different behaviour that circumvents the path-finding issue, maybe ghosts can just go through walls LOL
        -- implement seperate path finding algorithm that is easier than astar to reduce loading time
        -- https://youtu.be/rbYxbIMOZkE?si=OaYR9GwL9hIovhGO
    -- work out how to slow down monster movement
    -- implement mutliple monsters
    -- figure out how to implement dithering for light surrounding the player
    -- import sprites
    -- animation for sprites
    -- map generation => ensure that one block tall corridors cannot be generated

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
    }

}

-- ---------- UTLITY ----------

-- FUA 
-- add code for map generation via wave function collapse or some cellular automata function to generate a random map
function genMap()

end

-- FUA 
-- add code to write the map data to a txt file
function serialize() 

end

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
    items = world.item
    keys = world.key

-- ---------- ITEM EFFECT TIMEOUT ----------

    if player.speed > 200 then
        elapsedTime = elapsedTime + dt
        if elapsedTime > 5 then
            player.speed = player.speed - items.buffSpeed
            elapsedTime = 0
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
            print("item picked up")
        end
    end

-- player and key

    for q, keyCoord in ipairs(keys.coord) do
        if checkCollision(keyCoord, player.coord) then

            table.remove(keys.coord, q)
            player.keyCount = player.keyCount + 1
            print("key pickedup", player.keyCount)

            if player.keyCount == keys.totalCount then
                love.event.quit()
                print("all keys collected")
            end

        end
    end

end

function love.draw() -- draw function that runs once every frame

    playerCoord = world.player.coord
    monsters = world.monster.coord
    walls = world.wall.coord
    items = world.item.coord
    keys = world.key.coord

    love.graphics.clear()

    love.graphics.setColor(1,1,1)
    for _, wallCoord in ipairs(walls) do
        love.graphics.rectangle("fill", wallCoord[1], wallCoord[2], 20, 20)
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