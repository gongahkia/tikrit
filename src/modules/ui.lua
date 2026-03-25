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

local function drawIcon(image, x, y, settings, alpha)
    if not image or not love.graphics.draw then
        return false
    end
    Accessibility.setColor(settings, 1, 1, 1, alpha or 1)
    love.graphics.draw(image, x, y)
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

local function drawLevelPips(level, x, y, settings)
    if not love.graphics.rectangle then
        return
    end
    for index = 1, CONFIG.SKILL_LEVEL_CAP do
        local filled = index <= level
        Accessibility.setColor(settings, filled and 1 or 0.36, filled and 0.9 or 0.36, filled and 0.32 or 0.4, 1)
        love.graphics.rectangle(filled and "fill" or "line", x + ((index - 1) * 8), y, 6, 6)
    end
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
    Accessibility.setColor(settings, 0.03, 0.06, 0.08, 0.82)
    love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, 164)

    local player = run.player
    local itemSprites = sprites and sprites.items or {}
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
    local weatherText = string.format("%s  Day %d  %02d:%02d  %s",
        modeLabel(run),
        run.world.dayCount,
        math.floor(run.world.timeOfDay),
        math.floor((run.world.timeOfDay % 1) * 60),
        string.upper(run.world.weather.current)
    )

    Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print(weatherText, 12, 10)
    if run.runtime.currentPOI then
        Accessibility.setColor(settings, 0.75, 0.86, 0.96, 1)
        love.graphics.print("POI " .. run.runtime.currentPOI, 390, 10)
        Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    end
    if run.runtime.currentStation and run.runtime.currentStation.label then
        Accessibility.setColor(settings, 0.7, 0.84, 0.9, 1)
        love.graphics.print(string.format("Station %s (%s)", run.runtime.currentStation.label, run.runtime.currentStation.state or "idle"), 390, 22)
        Accessibility.setColor(settings, 0.9, 0.95, 1, 1)
    end
    love.graphics.print(string.format("Condition %s", formatPercent((player.condition / player.maxCondition) * 100)), 12, 34)
    love.graphics.print(string.format("Warmth %s", formatPercent(player.warmth)), 12, 56)
    love.graphics.print(string.format("Fatigue %s", formatPercent(player.fatigue)), 150, 34)
    love.graphics.print(string.format("Thirst %s", formatPercent(player.thirst)), 150, 56)
    love.graphics.print(string.format("Calories %d", math.floor(player.calories)), 280, 34)
    love.graphics.print(string.format("Carry %.1f / %.1f", player.carryWeight, player.carryCapacity), 280, 56)
    love.graphics.print(string.format("Fire lit %d", run.stats.firesLit), 460, 34)
    love.graphics.print(string.format("Repelled %d", run.stats.wolvesRepelled), 460, 56)
    local equipmentX = 280
    local equipmentY = 78
    local function drawEquipment(kind, label)
        local iconKey = EQUIPMENT_ICON_KEYS[kind]
        if iconKey then
            drawIcon(itemSprites[iconKey] or itemSprites.loot, equipmentX, equipmentY, settings, 0.95)
        end
        Accessibility.setColor(settings, 0.86, 0.9, 0.96, 1)
        love.graphics.print(string.format("%s %s", label, kind or "-"), equipmentX + 22, equipmentY + 2)
        equipmentX = equipmentX + 96
    end
    drawEquipment(player.equippedTool, "Tool")
    drawEquipment(player.equippedWeapon, "Weapon")
    drawEquipment(player.equippedLight, "Light")

    love.graphics.print("Inventory", 12, 84)
    local inventoryText = {}
    for index, item in ipairs(player.inventory) do
        local segment = string.format("%d:%s x%d", index, Items.describe(item.kind), item.quantity or 1)
        segment = segment .. appendConditionMarker(item)
        table.insert(inventoryText, segment)
        if #inventoryText >= 6 then
            break
        end
    end
    love.graphics.print(table.concat(inventoryText, "  "), 90, 84)

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
    love.graphics.print("Afflictions", 12, 108)
    if #afflictions > 0 then
        local afflictionX = 90
        for _, affliction in ipairs(afflictions) do
            drawIcon(affliction.icon, afflictionX, 106, settings, 0.95)
            love.graphics.print(affliction.label, afflictionX + 22, 108)
            afflictionX = afflictionX + 22 + fonts.small:getWidth(affliction.label) + 16
        end
    else
        love.graphics.print("None", 90, 108)
    end

    local skillX = 280
    local skillY = 106
    for _, key in ipairs(CONFIG.SKILL_NAMES) do
        local iconKey = SKILL_ICON_KEYS[key]
        local icon = iconKey and itemSprites.skills and itemSprites.skills[iconKey] or nil
        local level = ((skills[key] or {}).level) or 1
        if icon and drawIcon(icon, skillX, skillY, settings, 0.95) then
            drawLevelPips(level, skillX + 24, skillY + 6, settings)
            love.graphics.print(string.format("%s %d", key, level), skillX + 24, skillY - 10)
        else
            love.graphics.print(string.format("%s %d", key, level), skillX, skillY)
        end
        skillX = skillX + 96
        if skillX > 520 then
            skillX = 280
            skillY = skillY + 20
        end
    end

    if settings.gameplay.showHints and run.runtime.interactionHint ~= "" then
        Accessibility.setColor(settings, 0.74, 0.82, 0.9, 1)
        love.graphics.print(run.runtime.interactionHint, 12, 146)
    end

    if run.runtime.discoveryToastTimer and run.runtime.discoveryToastTimer > 0 and run.runtime.discoveryToast ~= "" then
        Accessibility.setColor(settings, 1, 0.93, 0.44, 1)
        love.graphics.print("Discovered " .. run.runtime.discoveryToast, 390, 146)
    end

    if run.runtime.message ~= "" then
        Accessibility.setColor(settings, 1, 0.93, 0.44, 1)
        love.graphics.print(run.runtime.message, 12, CONFIG.WINDOW_HEIGHT - 26)
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
