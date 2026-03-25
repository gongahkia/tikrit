local CONFIG = require("config")
local Items = require("modules/items")
local Survival = require("modules/survival")
local Utils = require("modules/utils")

local Fire = {}

local function isShelteredTile(tile)
    return tile == "cabin_floor"
        or tile == "cabin_bed"
        or tile == "cabin_stove"
        or tile == "cave_floor"
        or tile == "fire_safe"
        or tile == "snow_shelter"
end

local function currentTile(run)
    local gx, gy = Utils.pixelToGrid(run.player.coord[1], run.player.coord[2])
    local row = run.world.grid[gy + 1]
    return row and row[gx + 1]
end

function Fire.start(run, useAccelerant)
    local player = run.player
    local tile = currentTile(run)
    local sheltered = isShelteredTile(tile)
    local weather = run.world.weather.current

    if weather == "blizzard" and not sheltered then
        return false, "The blizzard snuffs every spark."
    end
    if Items.count(player.inventory, "matches") < 1
        or Items.count(player.inventory, "tinder") < 1
        or Items.count(player.inventory, "firewood") < 1 then
        return false, "Need matches, tinder, and fuel."
    end

    local successChance = CONFIG.FIRE_BASE_SUCCESS
        - (CONFIG.FIRE_WEATHER_PENALTY[weather] or 0)
        + ((CONFIG.DIFFICULTY_SETTINGS[CONFIG.DIFFICULTY_ALIASES[run.difficultyName] or run.difficultyName] or {}).fireBonus or 0)
    if run.feats.Firestarter then
        successChance = successChance + 0.12
    end
    if run.player.skills and run.player.skills.FireStarting then
        successChance = successChance + ((run.player.skills.FireStarting.level - 1) * 0.03)
    end
    if sheltered then
        successChance = successChance + 0.1
    end

    local guaranteed = useAccelerant and Items.count(player.inventory, "accelerant") > 0

    Items.remove(player.inventory, "matches", 1)
    Items.remove(player.inventory, "tinder", 1)
    Items.remove(player.inventory, "firewood", 1)
    if guaranteed then
        Items.remove(player.inventory, "accelerant", 1)
    end

    if not guaranteed and math.random() > Utils.clamp(successChance, 0.1, 0.95) then
        return false, "The fire fizzles out."
    end

    table.insert(run.world.fires, {
        coord = {player.coord[1], player.coord[2]},
        remainingBurnHours = CONFIG.FIRE_BURN_HOURS,
        remainingEmbersHours = CONFIG.FIRE_EMBERS_HOURS,
        sheltered = sheltered,
    })
    run.stats.firesLit = run.stats.firesLit + 1
    return true, "A fire catches."
end

function Fire.findNearest(run)
    local closest
    local closestDistance = math.huge
    for _, fire in ipairs(run.world.fires or {}) do
        local distance = Utils.distance(run.player.coord[1], run.player.coord[2], fire.coord[1], fire.coord[2])
        if distance < closestDistance then
            closestDistance = distance
            closest = fire
        end
    end
    return closest, closestDistance
end

function Fire.update(run, hours)
    for index = #run.world.fires, 1, -1 do
        local fire = run.world.fires[index]
        if fire.remainingBurnHours > 0 then
            fire.remainingBurnHours = math.max(0, fire.remainingBurnHours - hours)
        elseif fire.remainingEmbersHours > 0 then
            fire.remainingEmbersHours = math.max(0, fire.remainingEmbersHours - hours)
        end
        if fire.remainingBurnHours <= 0 and fire.remainingEmbersHours <= 0 then
            table.remove(run.world.fires, index)
        end
    end
end

function Fire.feed(run)
    local fire, distance = Fire.findNearest(run)
    if not fire or distance > CONFIG.FIRE_HEAT_RADIUS_TILES * CONFIG.TILE_SIZE then
        return false, "No fire close enough."
    end
    if Items.count(run.player.inventory, "firewood") < 1 then
        return false, "You need more fuel."
    end
    Items.remove(run.player.inventory, "firewood", 1)
    fire.remainingBurnHours = fire.remainingBurnHours + CONFIG.FIRE_ADD_FUEL_HOURS
    return true, "Fed the fire."
end

function Fire.interact(run)
    local fire, distance = Fire.findNearest(run)
    if not fire or distance > CONFIG.FIRE_HEAT_RADIUS_TILES * CONFIG.TILE_SIZE then
        return false, "No fire to work from."
    end
    if fire.remainingBurnHours <= 0 then
        return false, "The embers are too weak."
    end

    if Items.count(run.player.inventory, "raw_meat") > 0 then
        Items.remove(run.player.inventory, "raw_meat", 1)
        Items.add(run.player.inventory, "cooked_meat", 1)
        Items.sortInventory(run.player.inventory)
        run.stats.meatCooked = run.stats.meatCooked + 1
        Survival.gainSkillXP(run.player, "Cooking", 8)
        return true, "Cooked some meat."
    end
    if Items.count(run.player.inventory, "raw_fish") > 0 then
        Items.remove(run.player.inventory, "raw_fish", 1)
        Items.add(run.player.inventory, "cooked_fish", 1)
        Items.sortInventory(run.player.inventory)
        run.stats.meatCooked = run.stats.meatCooked + 1
        Survival.gainSkillXP(run.player, "Cooking", 8)
        return true, "Cooked a fish."
    end
    if Items.count(run.player.inventory, "snow") > 0 then
        Items.remove(run.player.inventory, "snow", 1)
        Items.add(run.player.inventory, "water", 1)
        Items.sortInventory(run.player.inventory)
        run.stats.waterBoiled = run.stats.waterBoiled + 1
        return true, "Melted snow into water."
    end

    return false, "Nothing to cook or boil."
end

return Fire
