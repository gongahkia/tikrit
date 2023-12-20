-- FUA

-- immediate
    -- implement collisions as another function in line 105 and abstract away
    -- when factoring in monster logic, i need to implement collisions as well
    -- figure out how to implement path finding
    -- figure out how to implement dithering for light surrounding the player
    -- import sprites

-- 2 implement
    -- work out gameplay loop and things to spice up gameplay

-- ---------- PRESETS ----------

-- local inspect = require("inspect")

local world = {

    player = {
        coord = {0,0},
        items = {},
        speed = 200,
        health = 3,
    }, 

    monster = {
        coord = {0,0},
        speed = 250,
        health = 1
    },

    wall = {
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
                    table.insert(world.wall, {x * 20, y * 20})
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

-- ---------- EVENT LOOP ----------

function love.load() -- load function that runs once at the beginning; sets defaults
    love.window.setTitle("tikrit")
    love.window.setMode(600,600)
    print(deserialize("map/map1.txt"))
end

-- FUA
-- add other update loops here for the monster 
function love.update(dt) -- update function that runs once every frame; dt is change in time

    player = world.player
    monster = world.monster
    walls = world.wall

-- player input

    storedX, storedY = player.coord[1], player.coord[2]

    if love.keyboard.isDown("w") then 
        player.coord[2] = player.coord[2] - (dt * player.speed)
    elseif love.keyboard.isDown("s") then 
        player.coord[2] = player.coord[2] + (dt * player.speed)
    end

    if love.keyboard.isDown("a") then
        player.coord[1] = player.coord[1] - (dt * player.speed)
    elseif love.keyboard.isDown("d") then
        player.coord[1] = player.coord[1] + (dt * player.speed)
    end

    for _, wallCoord in ipairs(walls) do
        if wallCoord[1] + 20 > player.coord[1] and wallCoord[2] + 20 > player.coord[2] and player.coord[1] + 20 > wallCoord[1] and player.coord[2] + 20 > wallCoord[2] then
            player.coord[1], player.coord[2] = storedX, storedY         
        end
    end

    if love.keyboard.isDown("escape") then 
        love.event.quit()
        print("event loop ended")
    end

end

function love.draw() -- draw function that runs once every frame
    playerCoord = world.player.coord
    walls = world.wall
    love.graphics.clear()
    for _, wallCoord in ipairs(walls) do
        love.graphics.rectangle("fill", wallCoord[1], wallCoord[2], 20, 20)
    end 
    love.graphics.rectangle("fill", playerCoord[1], playerCoord[2], 20, 20)
end