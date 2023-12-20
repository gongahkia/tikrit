-- FUA

-- immediate
    -- learn general framework of engine
    -- add function that parses text files
    -- work out how i want to render entities and global elements through a dictionary or??
    -- figure out core event loop
    -- work out player collissions
    -- work out player input

-- 2 implement
    -- add here

-- ---------- PRESETS ----------

local inspect = require("inspect")

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

-- FUA implement the below

-- FUA add wave function collapse or some cellular automata function to generate a random map
function createMap()

end

-- FUA add code to write the map data to a txt file
function serialize() 

end

-- FUA add code to create the static map data fed to the draw function based on the text file, this parses the text file
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
                    table.insert(world.wall, {x, y})
                elseif char == "@" then
                    world.player.coord = {x * 20, y * 20}
                end
                x = x + 1
            end 
            x = 0
            y = y + 1
        end
        return inspect(world)
    else
        print("error, unable to open local map file")
    end 
end

-- ---------- EVENT LOOP ----------

-- load function that runs once at the beginning
function love.load()
    love.window.setTitle("tikrit")
    love.window.setMode(800,800)
    print(deserialize("map/map1.txt"))
end

-- update function that runs once every frame
-- dt is change in time

-- FUA: add other update loops here like for the monster

function love.update(dt)

    player = world.player
    monster = world.monster

-- player input

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

    if love.keyboard.isDown("escape") then 
        love.event.quit()
        print("event loop ended")
    end

end

-- draw function that runs once every frame

-- FUA debug why rendering not working
function love.draw()
    love.graphics.clear()
    for _, coord in pairs(world.wall) do
        love.graphics.rectangle("fill", coord[1] * 20, coord[2] * 20, 20, 20)
    end 
    love.graphics.rectangle("fill", world.player.coord[1], world.player.coord[2], 20, 20)
end