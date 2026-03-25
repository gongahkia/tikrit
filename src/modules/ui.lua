local CONFIG = require("config")
local Accessibility = require("modules/accessibility")
local Items = require("modules/items")

local UI = {}

local SKILL_ICON_KEYS = {
    FireStarting = "firestarting",
    Cooking = "cooking",
    Fishing = "fishing",
    Harvesting = "harvesting",
    Mending = "mending",
    Archery = "archery",
}

local EQUIPMENT_ICON_KEYS = {
    knife = "knife",
    hatchet = "hatchet",
    bow = "bow",
    torch = "loot",
    flare = "loot",
}

local PANEL_HEIGHT = 74
local PANEL_GAP = 8
local PANEL_Y = 8

local function drawCentered(font, text, y, settings, color)
    Accessibility.setColor(settings, color[1], color[2], color[3], color[4] or 1)
    love.graphics.setFont(font)
    love.graphics.print(text, (CONFIG.WINDOW_WIDTH - font:getWidth(text)) / 2, y)
end

local function drawMenu(items, selectedIndex, startY, fonts, settings)
    for index, item in ipairs(items) do
        local text = item.label
        if item.value ~= nil then
            text = string.format("%s: %s", item.label, tostring(item.value))
        end
        local color = index == selectedIndex and {1, 0.93, 0.35, 1} or {0.82, 0.82, 0.82, 1}
        if index == selectedIndex then
            text = "> " .. text .. " <"
        end
        drawCentered(fonts.medium, text, startY + ((index - 1) * 42), settings, color)
    end
end

local function formatPercent(value)
    return string.format("%d%%", math.floor(value + 0.5))
end

local function modeLabel(run)
    if run.mode == "replay" then
        return string.format("Replay (%s)", string.upper(run.sourceMode or "survival"))
    end
    return string.upper(run.mode or "survival")
end

local function fontWidth(font, text)
    if font and font.getWidth then
        return font:getWidth(text)
    end
    return #tostring(text) * 8
end

local function fitText(font, text, maxWidth)
    text = tostring(text or "")
    if fontWidth(font, text) <= maxWidth then
        return text
    end

    local clipped = text
    while #clipped > 3 and fontWidth(font, clipped .. "...") > maxWidth do
        clipped = clipped:sub(1, -2)
    end
    return clipped .. "..."
end

local function drawIcon(image, x, y, settings, alpha, targetSize)
    if not image or not love.graphics.draw then
        return false
    end
    targetSize = targetSize or 12
    local width = image.getWidth and image:getWidth() or 20
    local height = image.getHeight and image:getHeight() or 20
    local scale = math.min(targetSize / math.max(1, width), targetSize / math.max(1, height))
    Accessibility.setColor(settings, 1, 1, 1, alpha or 1)
    love.graphics.draw(image, x, y, 0, scale, scale)
    return true
end

local function appendConditionMarker(item)
    local definition = Items.getDefinition(item.kind)
    if item.condition == nil then
        return ""
    end

    if definition and definition.perishable then
        if item.condition <= 20 then
            return " [spoiled]"
        elseif item.condition <= 45 then
            return " [stale]"
        elseif item.condition <= 75 then
            return " [cool]"
        end
        return " [fresh]"
    end

    if item.condition <= 50 then
        return string.format(" [%d%%]", math.floor(item.condition + 0.5))
    end
    return ""
end

local function drawLevelPips(level, x, y, settings, size, gap)
    if not love.graphics.rectangle then
        return
    end
    size = size or 6
    gap = gap or (size + 2)
    for index = 1, CONFIG.SKILL_LEVEL_CAP do
        local filled = index <= level
        Accessibility.setColor(settings, filled and 1 or 0.36, filled and 0.9 or 0.36, filled and 0.32 or 0.4, 1)
        love.graphics.rectangle(filled and "fill" or "line", x + ((index - 1) * gap), y, size, size)
    end
end

local function drawPanel(x, y, width, height, settings)
    Accessibility.setColor(settings, 0.03, 0.06, 0.08, 0.66)
    love.graphics.rectangle("fill", x, y, width, height)
    Accessibility.setColor(settings, 0.28, 0.34, 0.4, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
end

local function inventorySummary(inventory)
    local compactLabels = {
        ["Raw Meat"] = "Meat",
        ["Cooked Meat"] = "Cooked",
        ["Raw Fish"] = "Fish",
        ["Cooked Fish"] = "Cooked Fish",
        ["Canned Food"] = "Canned",
        ["Fishing Tackle"] = "Tackle",
        ["Rabbit Pelt"] = "Pelt",
        ["Fresh Gut"] = "Gut",
    }
    local parts = {}
    for index, item in ipairs(inventory or {}) do
        local label = compactLabels[Items.describe(item.kind)] or Items.describe(item.kind)
        if (item.quantity or 1) > 1 then
            label = string.format("%s x%d", label, item.quantity)
        end
        parts[#parts + 1] = string.format("%d:%s%s", index, label, appendConditionMarker(item))
        if #parts >= 3 then
            break
        end
    end
    return #parts > 0 and table.concat(parts, "  ") or "empty"
end

local function skillSummary(skills, keys)
    local parts = {}
    for _, key in ipairs(keys) do
        local level = ((skills[key] or {}).level) or 1
        parts[#parts + 1] = string.format("%s%d", key:sub(1, 1), level)
    end
    return table.concat(parts, "  ")
end

function UI.drawTitleScreen(state, fonts, settings)
    drawCentered(fonts.large, "TIKRIT", 36, settings, {0.93, 0.95, 0.98, 1})
    drawCentered(fonts.small, "Cold-weather survival", 112, settings, {0.7, 0.78, 0.86, 1})
    drawMenu(state.titleItems, state.titleIndex, 180, fonts, settings)

    if settings.gameplay.showHints then
        local help = {
            "WASD move, Left Shift sprint, E interact, F fire, R rest",
            "C craft, X context, H repair, T treat, M map",
            "Number keys use items, B ready bow, Space fire bow, Esc pauses",
        }
        for index, line in ipairs(help) do
            drawCentered(fonts.small, line, 500 + ((index - 1) * 22), settings, {0.56, 0.6, 0.66, 1})
        end
    end
end

function UI.drawSettingsScreen(screenState, fonts, settings)
    drawCentered(fonts.large, "SETTINGS", 26, settings, {0.95, 0.95, 0.98, 1})
    for index, category in ipairs(screenState.categories) do
        local color = index == screenState.categoryIndex and {1, 0.93, 0.35, 1} or {0.62, 0.62, 0.65, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.setFont(fonts.small)
        love.graphics.print(category, 80 + ((index - 1) * 160), 100)
    end

    for index, item in ipairs(screenState.options) do
        local color = index == screenState.optionIndex and {1, 0.93, 0.35, 1} or {0.85, 0.85, 0.85, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.setFont(fonts.medium)
        love.graphics.print(string.format("%s: %s", item.label, tostring(item.value)), 80, 170 + ((index - 1) * 36))
    end

    drawCentered(fonts.small, "Left/Right adjust values, Tab changes category, Esc returns", 548, settings, {0.55, 0.58, 0.65, 1})
end

function UI.drawReplayScreen(screenState, fonts, settings)
    drawCentered(fonts.large, "REPLAYS", 30, settings, {0.95, 0.95, 0.98, 1})
    if #screenState.entries == 0 then
        drawCentered(fonts.medium, "No saved runs", 250, settings, {0.8, 0.8, 0.8, 1})
        drawCentered(fonts.small, "Save one from the pause or death screen", 296, settings, {0.58, 0.6, 0.65, 1})
    else
        for index, entry in ipairs(screenState.entries) do
            local color = index == screenState.index and {1, 0.93, 0.35, 1} or {0.82, 0.82, 0.82, 1}
            Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
            love.graphics.setFont(fonts.medium)
            love.graphics.print(entry.file, 72, 150 + ((index - 1) * 54))
            love.graphics.setFont(fonts.small)
            love.graphics.print(entry.details, 92, 180 + ((index - 1) * 54))
        end
    end
    drawCentered(fonts.small, "Enter plays, R refreshes, Esc returns", 552, settings, {0.55, 0.58, 0.65, 1})
end

function UI.drawProfileScreen(profile, fonts, settings)
    drawCentered(fonts.large, "PROFILE", 26, settings, {0.95, 0.95, 0.98, 1})

    local lines = {
        string.format("Runs: %d", profile.totalRuns),
        string.format("Best Days: %d", profile.bestDays),
        string.format("Total Days: %d", profile.totalDaysSurvived),
        string.format("Fires Lit: %d", profile.totalFiresLit),
        string.format("Water Boiled: %d", profile.totalWaterBoiled),
        string.format("Meat Cooked: %d", profile.totalMeatCooked),
        string.format("Clothing Repairs: %d", profile.totalClothingRepairs),
        string.format("Wolves Repelled: %d", profile.totalWolvesRepelled),
    }

    Accessibility.setColor(settings, 0.82, 0.88, 0.96, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print("Survival Record", 80, 110)
    Accessibility.setColor(settings, 0.84, 0.84, 0.84, 1)
    for index, line in ipairs(lines) do
        love.graphics.print(line, 80, 140 + ((index - 1) * 24))
    end

    Accessibility.setColor(settings, 0.82, 0.88, 0.96, 1)
    love.graphics.print("Feats", 350, 110)
    local featY = 140
    for feat, unlocked in pairs(profile.unlocks) do
        local color = unlocked and {0.45, 0.98, 0.58, 1} or {0.45, 0.45, 0.48, 1}
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.print(string.format("%s %s", unlocked and "+" or "-", feat), 350, featY)
        featY = featY + 24
    end

    drawCentered(fonts.small, "Esc returns", 552, settings, {0.55, 0.58, 0.65, 1})
end

function UI.drawPauseScreen(options, selectedIndex, fonts, settings)
    Accessibility.setColor(settings, 0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)
    drawCentered(fonts.large, "PAUSED", 110, settings, {1, 1, 1, 1})
    drawMenu(options, selectedIndex, 230, fonts, settings)
end

function UI.drawHUD(run, fonts, settings, sprites)
    local player = run.player
    local world = run.world or {}
    local runtime = run.runtime or {}
    local gameplay = settings.gameplay or {}
    local itemSprites = sprites and sprites.items or {}
    local skillIcons = itemSprites.skills or {}
    local hudFont = fonts.hud or fonts.small
    local tinyFont = fonts.tiny or fonts.small
    local panelWidth = math.floor((CONFIG.WINDOW_WIDTH - (PANEL_GAP * 4)) / 3)
    local panelOneX = PANEL_GAP
    local panelTwoX = panelOneX + panelWidth + PANEL_GAP
    local panelThreeX = panelTwoX + panelWidth + PANEL_GAP
    local panelThreeWidth = CONFIG.WINDOW_WIDTH - panelThreeX - PANEL_GAP
    local afflictionsState = player.afflictions or {
        hypothermia = false,
        hypothermiaRisk = 0,
        sprain = false,
        infection = false,
        infectionRiskHours = 0,
        foodPoisoningHours = 0,
    }
    local skills = player.skills or {
        FireStarting = {level = 1},
        Cooking = {level = 1},
        Fishing = {level = 1},
        Harvesting = {level = 1},
        Mending = {level = 1},
        Archery = {level = 1},
    }
    local weatherText = string.format("%s  D%d  %02d:%02d  %s",
        modeLabel(run),
        world.dayCount or 1,
        math.floor(world.timeOfDay or 0),
        math.floor(((world.timeOfDay or 0) % 1) * 60),
        string.upper((((world.weather or {}).current or "clear"):sub(1, 3)))
    )
    local stationText = nil
    if runtime.currentStation and runtime.currentStation.label then
        local stationName = runtime.currentStation.label
        if stationName == "Workbench / Curing Rack" then
            stationName = "Bench/Cure"
        elseif stationName == "Curing Rack" then
            stationName = "Cure"
        end
        stationText = string.format("Stn %s %s", stationName, runtime.currentStation.state or "idle")
    end

    drawPanel(panelOneX, PANEL_Y, panelWidth, PANEL_HEIGHT, settings)
    drawPanel(panelTwoX, PANEL_Y, panelWidth, PANEL_HEIGHT, settings)
    drawPanel(panelThreeX, PANEL_Y, panelThreeWidth, PANEL_HEIGHT, settings)

    Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    love.graphics.setFont(hudFont)
    love.graphics.print(fitText(hudFont, weatherText, panelWidth - 16), panelOneX + 8, PANEL_Y + 6)
    if runtime.currentPOI then
        Accessibility.setColor(settings, 0.75, 0.86, 0.96, 1)
        love.graphics.print(fitText(tinyFont, "POI " .. runtime.currentPOI, panelWidth - 16), panelOneX + 8, PANEL_Y + 22)
    end
    if stationText then
        Accessibility.setColor(settings, 0.7, 0.84, 0.9, 1)
        love.graphics.print(
            fitText(tinyFont, stationText, panelWidth - 16),
            panelOneX + 8,
            PANEL_Y + 34
        )
    end

    Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    love.graphics.print(
        fitText(tinyFont, string.format("Condition %s  Warmth %s", formatPercent((player.condition / player.maxCondition) * 100), formatPercent(player.warmth)), panelWidth - 16),
        panelOneX + 8,
        PANEL_Y + 48
    )
    love.graphics.print(
        fitText(tinyFont, string.format("Fatigue %s  Thirst %s", formatPercent(player.fatigue), formatPercent(player.thirst)), panelWidth - 16),
        panelOneX + 8,
        PANEL_Y + 60
    )

    Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    love.graphics.setFont(hudFont)
    love.graphics.print(fitText(hudFont, string.format("Calories %d", math.floor(player.calories)), panelWidth - 16), panelTwoX + 8, PANEL_Y + 6)
    love.graphics.print(fitText(hudFont, string.format("Carry %.1f / %.1f", player.carryWeight, player.carryCapacity), panelWidth - 16), panelTwoX + 8, PANEL_Y + 24)
    love.graphics.print(fitText(tinyFont, string.format("Fire %d  Repelled %d", run.stats.firesLit, run.stats.wolvesRepelled), panelWidth - 16), panelTwoX + 8, PANEL_Y + 42)

    love.graphics.setFont(tinyFont)
    local inventoryText = inventorySummary(player.inventory)
    love.graphics.print(fitText(tinyFont, "Inv " .. inventoryText, panelWidth - 16), panelTwoX + 8, PANEL_Y + 58)

    local afflictions = {}
    if afflictionsState.hypothermia then
        table.insert(afflictions, {label = "Hypothermia", icon = itemSprites.affliction and itemSprites.affliction.hypothermia})
    elseif afflictionsState.hypothermiaRisk > 0 then
        table.insert(afflictions, {
            label = string.format("Hypothermia Risk %d%%", math.floor(afflictionsState.hypothermiaRisk + 0.5)),
            icon = itemSprites.affliction and itemSprites.affliction.hypothermia,
        })
    end
    if afflictionsState.sprain then
        table.insert(afflictions, {label = "Sprain", icon = itemSprites.affliction and itemSprites.affliction.sprain})
    end
    if afflictionsState.infection then
        table.insert(afflictions, {label = "Infection", icon = itemSprites.affliction and itemSprites.affliction.infection})
    elseif (afflictionsState.infectionRiskHours or 0) > 0 then
        table.insert(afflictions, {
            label = string.format("Infection Risk %.1fh", afflictionsState.infectionRiskHours),
            icon = itemSprites.affliction and itemSprites.affliction.infection,
        })
    end
    if (afflictionsState.foodPoisoningHours or 0) > 0 then
        table.insert(afflictions, {label = "Food Poisoning", icon = itemSprites.affliction and itemSprites.affliction.food_poisoning})
    end

    Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    love.graphics.setFont(tinyFont)
    local equipmentY = PANEL_Y + 8
    local equipmentWidth = math.floor((panelThreeWidth - 24) / 3)
    local function drawEquipment(kind, x, maxWidth)
        local iconKey = EQUIPMENT_ICON_KEYS[kind]
        if iconKey then
            drawIcon(itemSprites[iconKey] or itemSprites.loot, x, equipmentY, settings, 0.95, 10)
        end
        Accessibility.setColor(settings, 0.86, 0.9, 0.96, 1)
        love.graphics.print(fitText(tinyFont, kind and Items.describe(kind) or "-", maxWidth - 14), x + 14, equipmentY)
    end
    drawEquipment(player.equippedTool, panelThreeX + 8, equipmentWidth)
    drawEquipment(player.equippedWeapon, panelThreeX + 8 + equipmentWidth, equipmentWidth)
    drawEquipment(player.equippedLight, panelThreeX + 8 + (equipmentWidth * 2), equipmentWidth)

    love.graphics.setFont(tinyFont)
    local afflictionText = #afflictions > 0 and table.concat((function()
        local labels = {}
        for _, affliction in ipairs(afflictions) do
            labels[#labels + 1] = affliction.label
        end
        return labels
    end)(), ", ") or "none"
    if #afflictions > 0 then
        drawIcon(afflictions[1].icon, panelThreeX + 8, PANEL_Y + 28, settings, 0.95, 10)
    end
    Accessibility.setColor(settings, 0.84, 0.88, 0.94, 1)
    love.graphics.print(fitText(tinyFont, "Aff " .. afflictionText, panelThreeWidth - 22), panelThreeX + 22, PANEL_Y + 26)

    local skillOrder = {
        {"FireStarting", panelThreeX + 8, PANEL_Y + 48},
        {"Cooking", panelThreeX + 68, PANEL_Y + 48},
        {"Fishing", panelThreeX + 128, PANEL_Y + 48},
        {"Harvesting", panelThreeX + 8, PANEL_Y + 61},
        {"Mending", panelThreeX + 68, PANEL_Y + 61},
        {"Archery", panelThreeX + 128, PANEL_Y + 61},
    }
    for _, entry in ipairs(skillOrder) do
        local key = entry[1]
        local x = entry[2]
        local y = entry[3]
        local icon = skillIcons[SKILL_ICON_KEYS[key]]
        if not drawIcon(icon, x, y, settings, 0.95, 8) then
            Accessibility.setColor(settings, 0.84, 0.88, 0.94, 1)
            love.graphics.print(key:sub(1, 2), x, y - 1)
        end
        drawLevelPips(((skills[key] or {}).level) or 1, x + 10, y + 2, settings, 3, 4)
    end

    if gameplay.showHints and (runtime.interactionHint or "") ~= "" then
        local hintText = fitText(hudFont, runtime.interactionHint, CONFIG.WINDOW_WIDTH - 120)
        local hintWidth = fontWidth(hudFont, hintText) + 20
        local hintX = (CONFIG.WINDOW_WIDTH - hintWidth) / 2
        local hintY = PANEL_Y + PANEL_HEIGHT + 8
        Accessibility.setColor(settings, 0.03, 0.06, 0.08, 0.7)
        love.graphics.rectangle("fill", hintX, hintY, hintWidth, 20)
        Accessibility.setColor(settings, 0.74, 0.82, 0.9, 1)
        love.graphics.setFont(hudFont)
        love.graphics.print(hintText, hintX + 10, hintY + 2)
    end

    if runtime.discoveryToastTimer and runtime.discoveryToastTimer > 0 and (runtime.discoveryToast or "") ~= "" then
        local toastText = fitText(hudFont, "Discovered " .. runtime.discoveryToast, 220)
        local toastWidth = fontWidth(hudFont, toastText) + 20
        local toastX = CONFIG.WINDOW_WIDTH - toastWidth - 12
        local toastY = PANEL_Y + PANEL_HEIGHT + 8
        Accessibility.setColor(settings, 0.14, 0.12, 0.04, 0.8)
        love.graphics.rectangle("fill", toastX, toastY, toastWidth, 20)
        Accessibility.setColor(settings, 1, 0.93, 0.44, 1)
        love.graphics.setFont(hudFont)
        love.graphics.print(toastText, toastX + 10, toastY + 2)
    end

    if (runtime.message or "") ~= "" then
        local messageText = fitText(hudFont, runtime.message, CONFIG.WINDOW_WIDTH - 40)
        local messageWidth = fontWidth(hudFont, messageText) + 20
        Accessibility.setColor(settings, 0.03, 0.06, 0.08, 0.78)
        love.graphics.rectangle("fill", 12, CONFIG.WINDOW_HEIGHT - 28, messageWidth, 18)
        Accessibility.setColor(settings, 1, 0.93, 0.44, 1)
        love.graphics.setFont(hudFont)
        love.graphics.print(messageText, 22, CONFIG.WINDOW_HEIGHT - 27)
    end
end

function UI.drawCraftMenu(run, fonts, settings)
    if not run.runtime.craftMenuOpen then
        return
    end

    local recipes = run.runtime.craftRecipes or {}
    Accessibility.setColor(settings, 0.02, 0.03, 0.05, 0.92)
    love.graphics.rectangle("fill", 80, 160, 440, 240)
    drawCentered(fonts.medium, "CRAFT", 178, settings, {0.96, 0.96, 0.98, 1})

    for index, recipe in ipairs(recipes) do
        local selected = index == (run.runtime.craftIndex or 1)
        local color = selected and {1, 0.93, 0.35, 1} or (recipe.craftable and {0.82, 0.86, 0.9, 1} or {0.46, 0.48, 0.52, 1})
        Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
        love.graphics.setFont(fonts.small)
        love.graphics.print(string.format("%s%s", selected and "> " or "", recipe.label), 116, 208 + ((index - 1) * 28))
    end

    drawCentered(fonts.small, "Up/Down choose, Enter craft, Esc close", 376, settings, {0.6, 0.65, 0.72, 1})
end

function UI.drawDeathScreen(run, fonts, settings)
    drawCentered(fonts.large, "YOU FROZE OUT HERE", 86, settings, {0.95, 0.95, 0.98, 1})
    drawCentered(fonts.small, string.format("Mode: %s", modeLabel(run)), 168, settings, {0.7, 0.78, 0.86, 1})
    drawCentered(fonts.medium, string.format("Days survived: %d", run.stats.daysSurvived), 210, settings, {0.8, 0.84, 0.9, 1})
    drawCentered(fonts.medium, string.format("Fires lit: %d", run.stats.firesLit), 254, settings, {0.8, 0.84, 0.9, 1})
    drawCentered(fonts.medium, string.format("Cause of death: %s", run.runtime.causeOfDeath or "exposure"), 298, settings, {0.8, 0.84, 0.9, 1})
    local prompt = run.replayMode and "Enter returns to title" or "S saves replay, Enter returns to title"
    drawCentered(fonts.small, prompt, 520, settings, {0.56, 0.6, 0.66, 1})
end

return UI
