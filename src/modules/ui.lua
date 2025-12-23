-- UI module for menus and screens
local CONFIG = require("config")

local UI = {}

-- Draw functions for various screens
function UI.drawTitleScreen(difficultyMenuSelection, fonts, dailyChallengeEnabled, timeAttackEnabled)
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
    
    -- Mode indicators
    love.graphics.setFont(fonts.small)
    local yOffset = 420
    
    -- Daily challenge indicator
    if dailyChallengeEnabled then
        love.graphics.setColor(1, 0.84, 0, 1)  -- Gold for daily challenge
        local Utils = require("modules/utils")
        local dailyText = "DAILY CHALLENGE: " .. Utils.getDailyDateString()
        love.graphics.print(dailyText, (love.graphics.getWidth() - fonts.small:getWidth(dailyText))/2, yOffset)
        yOffset = yOffset + 25
    end
    
    -- Time attack indicator
    if timeAttackEnabled then
        love.graphics.setColor(1, 0.4, 0.4, 1)  -- Red for time attack
        local timeAttackText = "TIME ATTACK MODE ENABLED"
        love.graphics.print(timeAttackText, (love.graphics.getWidth() - fonts.small:getWidth(timeAttackText))/2, yOffset)
        yOffset = yOffset + 25
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("Use UP/DOWN arrows to select, ENTER to start", (love.graphics.getWidth() - fonts.small:getWidth("Use UP/DOWN arrows to select, ENTER to start"))/2, 460)
    love.graphics.print("Press D to toggle Daily Challenge | T to toggle Time Attack", (love.graphics.getWidth() - fonts.small:getWidth("Press D to toggle Daily Challenge | T to toggle Time Attack"))/2, 485)
    love.graphics.print("Press P to view Progression & Unlocks", (love.graphics.getWidth() - fonts.small:getWidth("Press P to view Progression & Unlocks"))/2, 510)
    love.graphics.print("Press F5 for Level Editor | F6 to Save Replay | F7 to Load Replay", (love.graphics.getWidth() - fonts.small:getWidth("Press F5 for Level Editor | F6 to Save Replay | F7 to Load Replay"))/2, 535)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth(text3) - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
end

-- Draw progression/unlocks screen
function UI.drawProgressionScreen(fonts)
    local Progression = require("modules/progression")
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.large)
    local title = "PROGRESSION & UNLOCKS"
    love.graphics.print(title, (love.graphics.getWidth() - fonts.large:getWidth(title))/2, 30)
    
    love.graphics.setFont(fonts.small)
    
    -- Overall stats
    love.graphics.setColor(0.7, 0.7, 1, 1)
    love.graphics.print("Overall Statistics:", 50, 100)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print(string.format("Total Runs: %d", Progression.data.totalRuns), 70, 125)
    love.graphics.print(string.format("Total Wins: %d", Progression.data.totalWins), 70, 145)
    love.graphics.print(string.format("Total Deaths: %d", Progression.data.totalDeaths), 70, 165)
    love.graphics.print(string.format("Keys Collected: %d", Progression.data.totalKeysCollected), 70, 185)
    love.graphics.print(string.format("Monsters Killed: %d", Progression.data.totalMonstersKilled), 70, 205)
    local fastestTime = Progression.data.fastestTime < math.huge and string.format("%.1fs", Progression.data.fastestTime) or "N/A"
    love.graphics.print("Fastest Time: " .. fastestTime, 70, 225)
    
    -- Unlocks
    love.graphics.setColor(0.7, 1, 0.7, 1)
    love.graphics.print("Unlocked Abilities:", 50, 270)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    
    local unlockY = 295
    local unlocks = Progression.data.unlocks
    local unlockList = {
        {name = "Speed Boost Start (+50)", unlocked = unlocks.speedBoostStart},
        {name = "Invincibility Start (3s)", unlocked = unlocks.invincibilityStart},
        {name = "Extra Inventory Slot (4)", unlocked = unlocks.extraInventorySlot},
        {name = "Ghost Slow Start", unlocked = unlocks.ghostSlowStart},
        {name = "Map Reveal (+3 vision)", unlocked = unlocks.mapReveal},
        {name = "Combat Master (2x damage)", unlocked = unlocks.combatMaster},
        {name = "Speed Runner (+100)", unlocked = unlocks.speedRunner},
        {name = "Survivor (extra life)", unlocked = unlocks.survivor},
    }
    
    for _, unlock in ipairs(unlockList) do
        if unlock.unlocked then
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.print("✓ " .. unlock.name, 70, unlockY)
        else
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
            love.graphics.print("✗ " .. unlock.name, 70, unlockY)
        end
        unlockY = unlockY + 20
    end
    
    -- Unlock requirements
    love.graphics.setColor(1, 1, 0.7, 1)
    love.graphics.print("Unlock Requirements:", 320, 270)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    
    local reqs = Progression.getUnlockRequirements()
    local reqY = 295
    for _, req in ipairs(reqs) do
        love.graphics.print(req, 340, reqY)
        reqY = reqY + 20
    end
    
    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("Press ESC to return to title screen", (love.graphics.getWidth() - fonts.small:getWidth("Press ESC to return to title screen"))/2, 550)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth("Made by @gongahkia on Github in Love2D") - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
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
    
    -- Progression stats
    local Progression = require("modules/progression")
    love.graphics.setColor(0.7, 0.7, 1, 1)
    local progText = string.format("Total: %d runs | %d wins | %d deaths", 
        Progression.data.totalRuns, Progression.data.totalWins, Progression.data.totalDeaths)
    love.graphics.print(progText, (love.graphics.getWidth() - fonts.small:getWidth(progText))/2, 330)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print("Made by @gongahkia on Github in Love2D", (love.graphics.getWidth() - fonts.small:getWidth(text3) - 10), (love.graphics.getHeight() - fonts.small:getHeight() - 10))
end

function UI.drawWinScreen(world, stats, fonts, dailyChallengeEnabled)
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
    
    -- Daily challenge indicator
    if dailyChallengeEnabled then
        love.graphics.setColor(1, 0.84, 0, 1)
        local Utils = require("modules/utils")
        local dailyText = "Daily Challenge: " .. Utils.getDailyDateString()
        love.graphics.print(dailyText, (love.graphics.getWidth() - fonts.small:getWidth(dailyText))/2, 315)
    end
    
    -- Grade system
    local grade = UI.calculateGrade(stats.deaths, elapsedGameTime)
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("Grade: " .. grade, (love.graphics.getWidth() - fonts.large:getWidth("Grade: " .. grade))/2, 340)
    
    -- Progression stats and unlocks
    local Progression = require("modules/progression")
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.7, 0.7, 1, 1)
    local progText = string.format("Total: %d runs | %d wins | Best: %ds", 
        Progression.data.totalRuns, Progression.data.totalWins, 
        Progression.data.fastestTime < math.huge and math.floor(Progression.data.fastestTime) or 0)
    love.graphics.print(progText, (love.graphics.getWidth() - fonts.small:getWidth(progText))/2, 400)
    
    -- Show new unlocks if any
    local newUnlocks = Progression.checkUnlocks()
    if #newUnlocks > 0 then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.print("NEW UNLOCKS!", (love.graphics.getWidth() - fonts.small:getWidth("NEW UNLOCKS!"))/2, 430)
        for i, unlock in ipairs(newUnlocks) do
            love.graphics.print("- " .. unlock, 150, 450 + (i-1)*20)
        end
    end
    
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
        love.graphics.rectangle("fill", 0, 0, 200, 140)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.print("Keys: " .. world.player.overallKeyCount .. "/" .. world.key.globalCount, 10, 10)
        love.graphics.print("Room: " .. world.player.currRoom, 10, 35)
        
        -- Show inventory
        local CONFIG = require("config")
        if CONFIG.INVENTORY_ENABLED then
            love.graphics.print("Inventory (1-3):", 10, 60)
            for i = 1, CONFIG.INVENTORY_SIZE do
                local item = world.player.inventory[i]
                if item then
                    love.graphics.setColor(0, 1, 1, 1)  -- Cyan for items
                    love.graphics.print(i .. ": Item", 10, 60 + (i * 20))
                else
                    love.graphics.setColor(0.5, 0.5, 0.5, 1)  -- Gray for empty
                    love.graphics.print(i .. ": ---", 10, 60 + (i * 20))
                end
            end
        end
        
        -- Show active effects
        love.graphics.setColor(1, 1, 1, 1)
        if activeEffects.invincibility then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("Invincible!", 10, 130)
        elseif activeEffects.ghostSlow then
            love.graphics.setColor(0, 1, 1, 1)
            love.graphics.print("Ghosts Slowed", 10, 130)
        elseif activeEffects.mapReveal then
            love.graphics.setColor(1, 0.5, 0, 1)
            love.graphics.print("Map Revealed", 10, 130)
        end
    end
end

-- Draw minimap overlay
function UI.drawMinimap(world, minimapEnabled)
    if not minimapEnabled then
        return
    end
    
    local scale = CONFIG.MINIMAP_SCALE
    local offsetX = CONFIG.MINIMAP_POSITION_X
    local offsetY = CONFIG.MINIMAP_POSITION_Y
    local mapSize = CONFIG.MINIMAP_SIZE
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, CONFIG.MINIMAP_BACKGROUND_ALPHA)
    love.graphics.rectangle("fill", offsetX, offsetY, mapSize, mapSize)
    
    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", offsetX, offsetY, mapSize, mapSize)
    
    -- Draw walls (gray)
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    for _, wallCoord in ipairs(world.wall.coord) do
        local x = offsetX + (wallCoord[1] * scale)
        local y = offsetY + (wallCoord[2] * scale)
        local size = CONFIG.TILE_SIZE * scale
        if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
            love.graphics.rectangle("fill", x, y, math.max(1, size), math.max(1, size))
        end
    end
    
    -- Draw doors (yellow)
    love.graphics.setColor(1, 1, 0, 0.7)
    for _, doorCoord in ipairs(world.door.coord) do
        local x = offsetX + (doorCoord[1] * scale)
        local y = offsetY + (doorCoord[2] * scale)
        local size = CONFIG.TILE_SIZE * scale
        if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
            love.graphics.rectangle("fill", x, y, math.max(2, size), math.max(2, size))
        end
    end
    
    -- Draw keys (gold)
    if CONFIG.MINIMAP_SHOW_KEYS then
        love.graphics.setColor(1, 0.84, 0, 1)
        for _, keyCoord in ipairs(world.key.coord) do
            local x = offsetX + (keyCoord[1] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            local y = offsetY + (keyCoord[2] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
                love.graphics.circle("fill", x, y, math.max(2, 3 * scale))
            end
        end
    end
    
    -- Draw items (cyan)
    if CONFIG.MINIMAP_SHOW_ITEMS then
        love.graphics.setColor(0, 1, 1, 1)
        for _, itemCoord in ipairs(world.item.coord) do
            local x = offsetX + (itemCoord[1] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            local y = offsetY + (itemCoord[2] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
                love.graphics.circle("fill", x, y, math.max(2, 2 * scale))
            end
        end
    end
    
    -- Draw ghosts (red)
    if CONFIG.MINIMAP_SHOW_GHOSTS and world.player.alive then
        love.graphics.setColor(1, 0, 0, 0.8)
        for _, monsterCoord in ipairs(world.monster.coord) do
            local x = offsetX + (monsterCoord[1] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            local y = offsetY + (monsterCoord[2] * scale) + (CONFIG.TILE_SIZE * scale / 2)
            if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
                love.graphics.circle("fill", x, y, math.max(2, 3 * scale))
            end
        end
    end
    
    -- Draw player (green)
    if world.player.alive then
        love.graphics.setColor(0, 1, 0, 1)
        local x = offsetX + (world.player.coord[1] * scale) + (CONFIG.TILE_SIZE * scale / 2)
        local y = offsetY + (world.player.coord[2] * scale) + (CONFIG.TILE_SIZE * scale / 2)
        if x >= offsetX and x < offsetX + mapSize and y >= offsetY and y < offsetY + mapSize then
            love.graphics.circle("fill", x, y, math.max(3, 4 * scale))
        end
    end
    
    -- Draw label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("MAP (M)", offsetX + 5, offsetY + mapSize + 5)
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

-- Draw time attack UI (timer, par time, bonuses)
function UI.drawTimeAttackUI(timeAttack, fonts)
    if not timeAttack.enabled then return end
    
    love.graphics.setFont(fonts.small)
    
    -- Calculate adjusted time (actual time - bonuses)
    local adjustedTime = math.max(0, timeAttack.elapsedGameTime - timeAttack.itemBonus)
    local minutes = math.floor(adjustedTime / 60)
    local seconds = math.floor(adjustedTime % 60)
    local parMinutes = math.floor(timeAttack.parTime / 60)
    local parSeconds = math.floor(timeAttack.parTime % 60)
    
    -- Determine color based on performance
    local color
    if adjustedTime < timeAttack.parTime * 0.8 then
        color = {0, 1, 0, 1}  -- Green - excellent
    elseif adjustedTime < timeAttack.parTime then
        color = {1, 1, 0, 1}  -- Yellow - good
    elseif adjustedTime < timeAttack.parTime * 1.2 then
        color = {1, 0.6, 0, 1}  -- Orange - par
    else
        color = {1, 0, 0, 1}  -- Red - over par
    end
    
    -- Draw timer
    love.graphics.setColor(unpack(color))
    local timerText = string.format("Time: %02d:%02d", minutes, seconds)
    love.graphics.print(timerText, 10, 60)
    
    -- Draw par time
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local parText = string.format("Par: %02d:%02d", parMinutes, parSeconds)
    love.graphics.print(parText, 10, 85)
    
    -- Draw bonus time if any
    if timeAttack.itemBonus > 0 then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.print(string.format("Bonus: -%ds", timeAttack.itemBonus), 10, 110)
    end
end

return UI

