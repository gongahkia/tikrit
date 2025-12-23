-- UI module for menus and screens
local CONFIG = require("config")

local UI = {}

-- Draw functions for various screens
function UI.drawTitleScreen(difficultyMenuSelection, fonts)
    local text1 = "TIKRIT"
    local text2 = "Select Difficulty"
    local text3 = "Made by @gongahkia on Github in Love2D"
    local difficulties = {"Easy", "Normal", "Hard", "Nightmare"}
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.large)
    love.graphics.print("TIKRIT", (love.graphics.getWidth() - fonts.large:getWidth(text1))/2, 50)
    
    love.graphics.setFont(fonts.medium)
    love.graphics.print("Select Difficulty", (love.graphics.getWidth() - fonts.medium:getWidth(text2))/2, 150)
    
    -- Draw difficulty options
    for i, diff in ipairs(difficulties) do
        local y = 200 + (i * 50)
        if i == difficultyMenuSelection then
            love.graphics.setColor(1, 1, 0, 1)  -- Highlight selected
            love.graphics.print("> " .. diff .. " <", (love.graphics.getWidth() - fonts.medium:getWidth("> " .. diff .. " <"))/2, y)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.print(diff, (love.graphics.getWidth() - fonts.medium:getWidth(diff))/2, y)
        end
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print("Use UP/DOWN arrows to select, ENTER to start", (love.graphics.getWidth() - fonts.small:getWidth("Use UP/DOWN arrows to select, ENTER to start"))/2, 500)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth(text3) - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
end

function UI.drawLoseScreen(world, stats, fonts)
    local text1 = "Try again next time!"
    local text2 = string.format("You collected %d out of %d keys.", world.player.overallKeyCount, world.key.globalCount)
    local text3 = "Made by @gongahkia on Github in Love2D"
    local roomCount = 0
    for _ in pairs(stats.roomsVisited) do roomCount = roomCount + 1 end
    local elapsedGameTime = math.floor((stats.finishTime > 0 and stats.finishTime or love.timer.getTime()) - stats.startTime)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.large)
    love.graphics.print("Try again next time!", (love.graphics.getWidth() - fonts.large:getWidth(text1))/2, 80)
    love.graphics.setFont(fonts.medium)
    love.graphics.print(string.format("You collected %d out of %d keys.", world.player.overallKeyCount, world.key.globalCount), (love.graphics.getWidth() - fonts.medium:getWidth(text2))/2, 200)
    
    -- Display statistics
    love.graphics.setFont(fonts.small)
    local statsText = string.format("Time: %d seconds | Rooms: %d | Items: %d", elapsedGameTime, roomCount, stats.itemsUsed)
    love.graphics.print(statsText, (love.graphics.getWidth() - fonts.small:getWidth(statsText))/2, 260)
    love.graphics.print("Difficulty: " .. CONFIG.DIFFICULTY, (love.graphics.getWidth() - fonts.small:getWidth("Difficulty: " .. CONFIG.DIFFICULTY))/2, 290)
    
    love.graphics.setFont(fonts.small)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth(text3) - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
end

function UI.drawWinScreen(world, stats, fonts)
    local text1 = "You Win!"
    local text3 = "Made by @gongahkia on Github in Love2D"
    local roomCount = 0
    for _ in pairs(stats.roomsVisited) do roomCount = roomCount + 1 end
    local elapsedGameTime = math.floor((stats.finishTime > 0 and stats.finishTime or love.timer.getTime()) - stats.startTime)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.large)
    love.graphics.print("You Win!", (love.graphics.getWidth() - fonts.large:getWidth(text1))/2, 80)
    love.graphics.setFont(fonts.medium)
    love.graphics.print(string.format("You collected all %d keys!", world.key.globalCount), (love.graphics.getWidth() - fonts.medium:getWidth(string.format("You collected all %d keys!", world.key.globalCount)))/2, 200)
    
    -- Display statistics
    love.graphics.setFont(fonts.small)
    local statsText = string.format("Time: %d seconds | Rooms: %d | Items: %d | Deaths: %d", elapsedGameTime, roomCount, stats.itemsUsed, stats.deaths)
    love.graphics.print(statsText, (love.graphics.getWidth() - fonts.small:getWidth(statsText))/2, 260)
    love.graphics.print("Difficulty: " .. CONFIG.DIFFICULTY, (love.graphics.getWidth() - fonts.small:getWidth("Difficulty: " .. CONFIG.DIFFICULTY))/2, 290)
    
    -- Grade system
    local grade = UI.calculateGrade(stats.deaths, elapsedGameTime)
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("Grade: " .. grade, (love.graphics.getWidth() - fonts.large:getWidth("Grade: " .. grade))/2, 340)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth(text3) - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
end

function UI.drawPauseScreen(pauseMenuSelection, fonts)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)
    
    -- Draw menu
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.large)
    local title = "PAUSED"
    love.graphics.print(title, (CONFIG.WINDOW_WIDTH - fonts.large:getWidth(title))/2, 150)
    
    love.graphics.setFont(fonts.medium)
    local options = {"Resume", "Restart", "Quit to Title"}
    for i, option in ipairs(options) do
        local y = 300 + (i * 60)
        if i == pauseMenuSelection then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("> " .. option .. " <", (CONFIG.WINDOW_WIDTH - fonts.medium:getWidth("> " .. option .. " <"))/2, y)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.print(option, (CONFIG.WINDOW_WIDTH - fonts.medium:getWidth(option))/2, y)
        end
    end
end

function UI.drawHUD(world, activeEffects, debugMode, fonts)
    if not debugMode then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 200, 100)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.print("Keys: " .. world.player.overallKeyCount .. "/" .. world.key.globalCount, 10, 10)
        love.graphics.print("Room: " .. world.player.currRoom, 10, 35)
        
        -- Show active effects
        if activeEffects.invincibility then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("Invincible!", 10, 60)
        elseif activeEffects.ghostSlow then
            love.graphics.setColor(0, 1, 1, 1)
            love.graphics.print("Ghosts Slowed", 10, 60)
        elseif activeEffects.mapReveal then
            love.graphics.setColor(1, 0.5, 0, 1)
            love.graphics.print("Map Revealed", 10, 60)
        end
    end
end

-- Calculate grade based on performance
function UI.calculateGrade(deaths, elapsedTime)
    if deaths == 0 and elapsedTime < 120 then 
        return "S"
    elseif deaths == 0 and elapsedTime < 180 then 
        return "A"
    elseif deaths <= 1 and elapsedTime < 240 then 
        return "B"
    elseif deaths <= 2 then 
        return "C"
    else
        return "D"
    end
end

return UI
