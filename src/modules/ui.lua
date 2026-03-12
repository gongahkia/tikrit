local CONFIG = require("config")
local Accessibility = require("modules/accessibility")

local UI = {}

local function drawCenteredText(font, text, y, settings, color)
    Accessibility.setColor(settings, color[1], color[2], color[3], color[4] or 1)
    love.graphics.setFont(font)
    love.graphics.print(text, (CONFIG.WINDOW_WIDTH - font:getWidth(text)) / 2, y)
end

local function drawMenuList(items, selectedIndex, startY, fonts, settings)
    for index, item in ipairs(items) do
        local text = item.label
        if item.value ~= nil then
            text = string.format("%s: %s", item.label, tostring(item.value))
        end

        local color = {0.72, 0.72, 0.72, 1}
        if index == selectedIndex then
            color = {1, 0.93, 0.35, 1}
            text = "> " .. text .. " <"
        end
        drawCenteredText(fonts.medium, text, startY + ((index - 1) * 42), settings, color)
    end
end

function UI.drawTitleScreen(state, fonts, settings)
    drawCenteredText(fonts.large, "TIKRIT", 40, settings, {0.9, 0.9, 0.9, 1})
    drawCenteredText(fonts.small, "Foundation-first survival horror build", 120, settings, {0.75, 0.75, 0.75, 1})
    drawMenuList(state.titleItems, state.titleIndex, 180, fonts, settings)

    local footer = {
        "Up/Down selects, Left/Right changes values, Enter confirms",
        "Settings and progression are available from the title and pause screens",
        "F5 opens the editor only when debug tools are enabled",
    }

    for index, line in ipairs(footer) do
        drawCenteredText(fonts.small, line, 470 + ((index - 1) * 24), settings, {0.55, 0.55, 0.55, 1})
    end
end

function UI.drawSettingsScreen(screenState, fonts, settings)
    drawCenteredText(fonts.large, "SETTINGS", 30, settings, {0.92, 0.92, 0.92, 1})

    local categoryX = 70
    for index, category in ipairs(screenState.categories) do
        local active = index == screenState.categoryIndex
        local color = active and {1, 0.93, 0.35, 1} or {0.6, 0.6, 0.6, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.setFont(fonts.small)
        love.graphics.print(category, categoryX + ((index - 1) * 160), 100)
    end

    for index, item in ipairs(screenState.options) do
        local y = 170 + ((index - 1) * 34)
        local color = index == screenState.optionIndex and {1, 0.93, 0.35, 1} or {0.8, 0.8, 0.8, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.setFont(fonts.medium)
        love.graphics.print(string.format("%s: %s", item.label, tostring(item.value)), 90, y)
    end

    local helpLines = {
        "Left/Right adjusts values",
        "Tab switches category",
        "R resets defaults",
        "Esc returns",
    }
    for index, line in ipairs(helpLines) do
        drawCenteredText(fonts.small, line, 500 + ((index - 1) * 22), settings, {0.55, 0.55, 0.55, 1})
    end
end

function UI.drawProgressionScreen(progressionData, fonts, settings)
    drawCenteredText(fonts.large, "PROGRESSION", 30, settings, {0.92, 0.92, 0.92, 1})

    local leftX = 70
    local rightX = 330
    local y = 110

    Accessibility.setColor(settings, 0.7, 0.8, 1, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print("Overall Stats", leftX, y)
    y = y + 30

    local statsLines = {
        "Runs: " .. progressionData.totalRuns,
        "Wins: " .. progressionData.totalWins,
        "Deaths: " .. progressionData.totalDeaths,
        "Keys: " .. progressionData.totalKeysCollected,
        "Monsters: " .. progressionData.totalMonstersKilled,
        "Items: " .. progressionData.totalItemsCollected,
        "Fastest: " .. (progressionData.fastestTime == math.huge and "N/A" or string.format("%.1fs", progressionData.fastestTime)),
    }

    Accessibility.setColor(settings, 0.82, 0.82, 0.82, 1)
    for _, line in ipairs(statsLines) do
        love.graphics.print(line, leftX, y)
        y = y + 24
    end

    Accessibility.setColor(settings, 0.7, 1, 0.76, 1)
    love.graphics.print("Unlocks", rightX, 110)

    local unlockY = 140
    for key, unlocked in pairs(progressionData.unlocks) do
        local color = unlocked and {0.42, 1, 0.42, 1} or {0.45, 0.45, 0.45, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.print(string.format("%s %s", unlocked and "+" or "-", key), rightX, unlockY)
        unlockY = unlockY + 20
    end

    drawCenteredText(fonts.small, "Press Esc to return", 550, settings, {0.55, 0.55, 0.55, 1})
end

function UI.drawPauseScreen(options, selectedIndex, fonts, settings)
    Accessibility.setColor(settings, 0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)
    drawCenteredText(fonts.large, "PAUSED", 120, settings, {1, 1, 1, 1})
    drawMenuList(options, selectedIndex, 240, fonts, settings)
end

function UI.drawHUD(run, fonts, settings)
    local player = run.world.player

    Accessibility.setColor(settings, 0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, 240, 170)

    Accessibility.setColor(settings, 1, 1, 1, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print(string.format("Keys: %d/%d", player.overallKeyCount, run.world.totalKeys), 10, 10)
    love.graphics.print("Difficulty: " .. run.difficultyName, 10, 34)
    love.graphics.print("Inventory:", 10, 58)

    for index = 1, player.inventorySize do
        local item = player.inventory[index]
        local label = item and item.kind or "---"
        love.graphics.print(string.format("%d: %s", index, label), 20, 58 + (index * 18))
    end

    love.graphics.print("Sanity", 10, 132)
    Accessibility.setColor(settings, 0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", 70, 136, 140, 14)

    local sanityRatio = player.sanity / player.maxSanity
    local color = {0.35, 0.92, 0.48, 1}
    if player.sanity <= CONFIG.SANITY_BREAK_THRESHOLD then
        color = {1, 0.32, 0.32, 1}
    elseif player.sanity <= CONFIG.SANITY_CRITICAL_THRESHOLD then
        color = {1, 0.72, 0.2, 1}
    elseif player.sanity <= CONFIG.SANITY_LOW_THRESHOLD then
        color = {0.95, 0.88, 0.28, 1}
    end
    Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
    love.graphics.rectangle("fill", 70, 136, 140 * sanityRatio, 14)

    Accessibility.setColor(settings, 1, 1, 1, 1)
    love.graphics.print(string.format("%d", math.floor(player.sanity)), 220, 132)
end

function UI.drawSanityOverlay(run, fonts, settings)
    local tier = run.runtime.sanityEffects.tier
    if tier == "stable" then
        return
    end

    local alpha = 0.08
    if tier == "low" then
        alpha = 0.14
    elseif tier == "critical" then
        alpha = 0.2
    elseif tier == "broken" then
        alpha = 0.26
    elseif tier == "panic" then
        alpha = 0.34
    end

    Accessibility.setColor(settings, 1, 0.08, 0.08, alpha)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)

    if tier == "broken" or tier == "panic" then
        drawCenteredText(fonts.medium, "THE DARK IS LISTENING", 30, settings, {1, 0.35, 0.35, 1})
    elseif tier == "critical" then
        drawCenteredText(fonts.medium, "KEEP IT TOGETHER", 30, settings, {1, 0.55, 0.3, 1})
    end
end

function UI.drawWinScreen(run, fonts, settings)
    drawCenteredText(fonts.large, "YOU ESCAPED", 90, settings, {0.95, 0.95, 0.95, 1})
    drawCenteredText(fonts.medium, string.format("Time: %.1fs", run.stats.finishTime - run.stats.startTime), 200, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.medium, string.format("Keys: %d", run.stats.keysCollected), 250, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.medium, string.format("Sanity left: %d", math.floor(run.world.player.sanity)), 300, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.small, "Enter returns to title", 520, settings, {0.55, 0.55, 0.55, 1})
end

function UI.drawLoseScreen(run, fonts, settings)
    drawCenteredText(fonts.large, "YOU WERE CONSUMED", 90, settings, {0.95, 0.95, 0.95, 1})
    drawCenteredText(fonts.medium, string.format("Time: %.1fs", run.stats.finishTime - run.stats.startTime), 200, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.medium, string.format("Deaths: %d", run.stats.deaths), 250, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.medium, string.format("Sanity left: %d", math.floor(run.world.player.sanity)), 300, settings, {0.72, 0.72, 0.72, 1})
    drawCenteredText(fonts.small, "Enter returns to title", 520, settings, {0.55, 0.55, 0.55, 1})
end

function UI.drawMinimap(run, settings)
    local tileSize = CONFIG.TILE_SIZE * CONFIG.MINIMAP_SCALE
    local offsetX = CONFIG.MINIMAP_POSITION_X
    local offsetY = CONFIG.MINIMAP_POSITION_Y

    Accessibility.setColor(settings, 0, 0, 0, CONFIG.MINIMAP_BACKGROUND_ALPHA)
    love.graphics.rectangle("fill", offsetX, offsetY, CONFIG.MINIMAP_SIZE, CONFIG.MINIMAP_SIZE)

    for y = 1, #run.world.grid do
        for x = 1, #run.world.grid[y] do
            local color = run.world.grid[y][x] == 1 and {0.24, 0.24, 0.24, 1} or {0.48, 0.48, 0.48, 1}
            Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
            love.graphics.rectangle("fill", offsetX + ((x - 1) * tileSize), offsetY + ((y - 1) * tileSize), tileSize, tileSize)
        end
    end

    Accessibility.setColor(settings, 1, 0.84, 0, 1)
    for _, key in ipairs(run.world.keys) do
        local gx = (key.coord[1] / CONFIG.TILE_SIZE) * tileSize
        local gy = (key.coord[2] / CONFIG.TILE_SIZE) * tileSize
        love.graphics.circle("fill", offsetX + gx + (tileSize / 2), offsetY + gy + (tileSize / 2), 2)
    end

    Accessibility.setColor(settings, 1, 0.3, 0.3, 0.9)
    for _, monster in ipairs(run.world.monsters) do
        local gx = (monster.coord[1] / CONFIG.TILE_SIZE) * tileSize
        local gy = (monster.coord[2] / CONFIG.TILE_SIZE) * tileSize
        love.graphics.circle("fill", offsetX + gx + (tileSize / 2), offsetY + gy + (tileSize / 2), 2)
    end

    Accessibility.setColor(settings, 0.3, 1, 0.45, 1)
    local player = run.world.player
    local px = (player.coord[1] / CONFIG.TILE_SIZE) * tileSize
    local py = (player.coord[2] / CONFIG.TILE_SIZE) * tileSize
    love.graphics.circle("fill", offsetX + px + (tileSize / 2), offsetY + py + (tileSize / 2), 3)
end

return UI
