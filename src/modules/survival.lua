local CONFIG = require("config")
local Items = require("modules/items")
local Utils = require("modules/utils")

local Survival = {}

local CLOTHING_ORDER = {"head", "torso", "hands", "legs", "feet"}

local CRAFT_RECIPES = {
    {
        key = "bandage",
        label = "Bandage",
        inputs = {cloth = 1},
        outputs = {bandage = 2},
        skill = "Mending",
    },
    {
        key = "snare",
        label = "Snare",
        requiresWorkbench = true,
        inputs = {sticks = 2, cured_gut = 1},
        outputs = {snare = 1},
        skill = "Harvesting",
    },
    {
        key = "fishing_tackle",
        label = "Fishing Tackle",
        requiresWorkbench = true,
        inputs = {cloth = 1, cured_gut = 1},
        outputs = {fishing_tackle = 1},
        skill = "Fishing",
    },
    {
        key = "arrow",
        label = "Arrow",
        requiresWorkbench = true,
        inputs = {sticks = 1, feather = 2, cured_gut = 1},
        outputs = {arrow = 2},
        skill = "Archery",
    },
    {
        key = "rabbit_wraps",
        label = "Rabbit Wraps",
        requiresWorkbench = true,
        inputs = {cured_rabbit_pelt = 2, cured_gut = 1},
        outputs = {rabbit_wraps = 1},
        skill = "Mending",
    },
}

local function clamp(value, maxValue)
    return Utils.clamp(value, 0, maxValue)
end

local function tileAt(grid, coord)
    local gx, gy = Utils.pixelToGrid(coord[1], coord[2])
    local row = grid[gy + 1]
    return row and row[gx + 1], gx + 1, gy + 1
end

local function isShelterTile(tile)
    return tile == "cabin_floor"
        or tile == "cabin_bed"
        or tile == "cabin_stove"
        or tile == "cabin_workbench"
        or tile == "cave_floor"
        or tile == "snow_shelter"
        or tile == "fire_safe"
end

local function isWalkableTile(tile)
    return tile ~= "tree"
        and tile ~= "rock"
        and tile ~= "lake"
        and tile ~= "cabin_wall"
        and tile ~= "cave_wall"
end

local function createClothing(name, warmth, windproof, waterproof)
    return {
        name = name,
        warmth = warmth,
        windproof = windproof,
        waterproof = waterproof,
        condition = 100,
        wetness = 0,
        frostbitten = false,
    }
end

local function createDefaultClothing()
    return {
        head = createClothing("Wool Cap", 7, 3, 0.2),
        torso = createClothing("Parka", 18, 8, 0.35),
        hands = createClothing("Worn Mitts", 5, 2, 0.1),
        legs = createClothing("Field Pants", 8, 4, 0.15),
        feet = createClothing("Winter Boots", 10, 6, 0.45),
    }
end

local function createSkillSet()
    local skills = {}
    for _, name in ipairs(CONFIG.SKILL_NAMES) do
        skills[name] = {
            level = 1,
            xp = 0,
        }
    end
    return skills
end

local function getDifficulty(run)
    local key = CONFIG.DIFFICULTY_ALIASES[run.difficultyName] or run.difficultyName
    return CONFIG.DIFFICULTY_SETTINGS[key] or CONFIG.DIFFICULTY_SETTINGS.voyageur
end

local function eachClothing(player, callback)
    for _, slot in ipairs(CLOTHING_ORDER) do
        callback(slot, player.clothing[slot])
    end
end

local function clothingTotals(player)
    local warmth = 0
    local windproof = 0
    local wetness = 0

    eachClothing(player, function(_, item)
        local conditionScale = (item.condition or 100) / 100
        local wetFactor = 1 - (((item.wetness or 0) / 100) * (1 - (item.waterproof or 0)) * 0.7)
        warmth = warmth + (item.warmth * conditionScale * wetFactor)
        windproof = windproof + (item.windproof * conditionScale * wetFactor)
        wetness = math.max(wetness, item.wetness or 0)
    end)

    return warmth, windproof, wetness
end

local function getFireHeatHours(run)
    local heatBonus = 0
    local fireRadius = CONFIG.FIRE_HEAT_RADIUS_TILES * CONFIG.TILE_SIZE

    for _, fire in ipairs(run.world.fires or {}) do
        if fire.remainingBurnHours > 0 then
            local distance = Utils.distance(run.player.coord[1], run.player.coord[2], fire.coord[1], fire.coord[2])
            if distance <= fireRadius then
                heatBonus = math.max(heatBonus, 1 - (distance / fireRadius))
            end
        end
    end

    return heatBonus
end

local function changeWeather(run, force)
    if not force and run.world.weather.hoursUntilChange > 0 then
        return
    end

    local current = run.world.weather.current
    local options = CONFIG.WEATHER_TRANSITIONS[current] or CONFIG.WEATHER_TRANSITIONS.clear
    run.world.weather.current = options[math.random(#options)]
    run.world.weather.hoursUntilChange = math.random(
        CONFIG.WEATHER_CHANGE_MIN_HOURS,
        CONFIG.WEATHER_CHANGE_MAX_HOURS
    )
end

local function applyWetness(player, amount)
    eachClothing(player, function(_, item)
        local resistance = (item.waterproof or 0) * 0.75
        local gain = amount * math.max(0.2, 1 - resistance)
        item.wetness = clamp((item.wetness or 0) + gain, 100)
    end)
end

local function dryClothing(player, hours, heatFactor, sheltered)
    eachClothing(player, function(_, item)
        local rate = CONFIG.PASSIVE_DRY_RATE_PER_HOUR
        if sheltered then
            rate = rate + 2
        end
        if heatFactor > 0 then
            rate = rate + (CONFIG.NEAR_FIRE_DRY_RATE_PER_HOUR * heatFactor)
        end
        item.wetness = clamp((item.wetness or 0) - (rate * hours), 100)
    end)
end

local function nextFrostbiteSlot(player)
    for _, slot in ipairs(CLOTHING_ORDER) do
        local item = player.clothing[slot]
        if item and not item.frostbitten then
            return item
        end
    end
    return nil
end

local function applyFrostbite(player)
    local slot = nextFrostbiteSlot(player)
    if not slot then
        return false
    end

    slot.frostbitten = true
    player.maxCondition = math.max(20, player.maxCondition - CONFIG.FROSTBITE_CONDITION_LOSS)
    player.condition = math.min(player.condition, player.maxCondition)
    player.frostbiteCount = (player.frostbiteCount or 0) + 1
    return true
end

local function setDeathCause(run, cause)
    if run.player.condition <= 0 then
        run.runtime.causeOfDeath = cause
    end
end

local function hasMaterials(inventory, requirements)
    for kind, quantity in pairs(requirements or {}) do
        if Items.count(inventory, kind) < quantity then
            return false
        end
    end
    return true
end

local function findNearby(list, coord, radius)
    radius = radius or (CONFIG.TILE_SIZE * 1.2)
    for index, entry in ipairs(list or {}) do
        if Utils.distance(coord[1], coord[2], entry.coord[1], entry.coord[2]) <= radius then
            return entry, index
        end
    end
    return nil
end

local function roomTemperatureModifier(run, coord)
    local _, gx, gy = tileAt(run.world.grid, coord)
    if not gx or not gy then
        return 0
    end
    for _, band in ipairs(run.world.temperatureBands or {}) do
        local zone = band.zone
        local width = zone and (zone.width or zone.w)
        local height = zone and (zone.height or zone.h)
        if zone and zone.x and zone.y and width and height
            and gx >= zone.x and gx < zone.x + width
            and gy >= zone.y and gy < zone.y + height then
            return band.modifier or 0
        end
    end
    return 0
end

local function markMappedTiles(run, centerCoord, radius)
    run.world.mappedTiles = run.world.mappedTiles or {}
    local gx, gy = Utils.pixelToGrid(centerCoord[1], centerCoord[2])
    for dy = -radius, radius do
        for dx = -radius, radius do
            if math.sqrt((dx * dx) + (dy * dy)) <= radius then
                local tileX = gx + dx + 1
                local tileY = gy + dy + 1
                if run.world.grid[tileY] and run.world.grid[tileY][tileX] then
                    run.world.mappedTiles[tileX .. ":" .. tileY] = true
                end
            end
        end
    end
end

local function conditionDecayMultiplier(run, heatFactor)
    if heatFactor > 0 then
        return 1.25
    end
    if Survival.isSheltered(run, run.player.coord) then
        return 0.6
    end
    if run.world.weather.current == "blizzard" or run.world.weather.current == "snow" then
        return 0.85
    end
    return 1.0
end

local function updatePerishables(run, hours, heatFactor)
    local decayMultiplier = conditionDecayMultiplier(run, heatFactor)
    for _, item in ipairs(run.player.inventory or {}) do
        local definition = Items.getDefinition(item.kind)
        if definition and definition.perishable then
            local decay = (definition.decayPerHour or 0.5) * decayMultiplier * hours
            item.condition = Utils.clamp((item.condition or 100) - decay, 0, 100)
        end
    end
end

local function updateCuring(run, hours)
    run.world.curing = run.world.curing or {}
    for index = #run.world.curing, 1, -1 do
        local curing = run.world.curing[index]
        curing.hoursRemaining = math.max(0, curing.hoursRemaining - hours)
    end
end

local function skillBonus(player, name)
    local skill = player.skills and player.skills[name]
    return skill and skill.level or 1
end

local function addSkillXP(player, skillName, amount)
    local skill = player.skills and player.skills[skillName]
    if not skill or amount <= 0 then
        return skill and skill.level or 1
    end

    if skill.level >= CONFIG.SKILL_LEVEL_CAP then
        return skill.level
    end

    skill.xp = skill.xp + amount
    while skill.level < CONFIG.SKILL_LEVEL_CAP and skill.xp >= CONFIG.SKILL_XP_PER_LEVEL do
        skill.xp = skill.xp - CONFIG.SKILL_XP_PER_LEVEL
        skill.level = skill.level + 1
    end
    return skill.level
end

local function inflictFoodPoisoning(run)
    run.player.afflictions.foodPoisoningHours = math.max(
        run.player.afflictions.foodPoisoningHours or 0,
        CONFIG.FOOD_POISONING_HOURS
    )
end

local function updateAfflictions(run, hours, options, sheltered, peakWetness)
    local player = run.player
    local afflictions = player.afflictions
    local difficulty = getDifficulty(run)

    if player.warmth <= CONFIG.HYPOTHERMIA_RISK_WARMTH_THRESHOLD and not sheltered then
        local risk = CONFIG.HYPOTHERMIA_RISK_PER_HOUR * difficulty.hypothermiaMultiplier * hours
        if peakWetness >= CONFIG.FROSTBITE_WETNESS_THRESHOLD then
            risk = risk + (10 * hours)
        end
        afflictions.hypothermiaRisk = Utils.clamp(afflictions.hypothermiaRisk + risk, 0, 100)
        if afflictions.hypothermiaRisk >= 100 then
            afflictions.hypothermia = true
        end
    else
        afflictions.hypothermiaRisk = Utils.clamp(
            afflictions.hypothermiaRisk - (CONFIG.HYPOTHERMIA_RECOVERY_PER_HOUR * hours),
            0,
            100
        )
        if sheltered and player.warmth > 40 then
            afflictions.hypothermiaRecovery = (afflictions.hypothermiaRecovery or 0) + hours
            if afflictions.hypothermiaRecovery >= 2 then
                afflictions.hypothermia = false
            end
        else
            afflictions.hypothermiaRecovery = 0
        end
    end

    if afflictions.hypothermia then
        player.condition = clamp(
            player.condition - (CONFIG.HYPOTHERMIA_CONDITION_DRAIN_PER_HOUR * hours),
            player.maxCondition
        )
        setDeathCause(run, "hypothermia")
    end

    if options.sprinting and math.max(0, player.carryWeight - player.carryCapacity) > 0 then
        afflictions.sprainRisk = (afflictions.sprainRisk or 0)
            + (CONFIG.SPRAIN_RISK_PER_HOUR * hours * difficulty.afflictionMultiplier)
        if afflictions.sprainRisk >= 12 then
            afflictions.sprain = true
        end
    else
        afflictions.sprainRisk = math.max(0, (afflictions.sprainRisk or 0) - (hours * 4))
    end

    if afflictions.sprain then
        afflictions.sprainRecovery = (afflictions.sprainRecovery or CONFIG.SPRAIN_RECOVERY_HOURS) - hours
        if afflictions.sprainRecovery <= 0 then
            afflictions.sprain = false
            afflictions.sprainRecovery = CONFIG.SPRAIN_RECOVERY_HOURS
        end
    end

    if afflictions.infectionRiskHours and afflictions.infectionRiskHours > 0 then
        afflictions.infectionRiskHours = afflictions.infectionRiskHours - hours
        if afflictions.infectionRiskHours <= 0 then
            afflictions.infectionRiskHours = 0
            afflictions.infection = true
        end
    end

    if afflictions.infection then
        player.condition = clamp(
            player.condition - (CONFIG.INFECTION_CONDITION_DRAIN_PER_HOUR * hours),
            player.maxCondition
        )
        setDeathCause(run, "infection")
    end

    if afflictions.foodPoisoningHours and afflictions.foodPoisoningHours > 0 then
        afflictions.foodPoisoningHours = math.max(0, afflictions.foodPoisoningHours - hours)
        player.condition = clamp(
            player.condition - (CONFIG.FOOD_POISONING_CONDITION_DRAIN_PER_HOUR * hours),
            player.maxCondition
        )
        player.fatigue = clamp(
            player.fatigue - (CONFIG.FOOD_POISONING_FATIGUE_DRAIN_PER_HOUR * hours),
            CONFIG.MAX_FATIGUE
        )
        setDeathCause(run, "food poisoning")
    end
end

local function applyRecipeOutput(run, recipe)
    for kind, quantity in pairs(recipe.outputs) do
        Items.add(run.player.inventory, kind, quantity)
        if kind == "rabbit_wraps" then
            run.player.clothing.hands = {
                name = "Rabbit Wraps",
                warmth = 5 + CONFIG.CLOTHING_UPGRADE_WARMTH,
                windproof = 3,
                waterproof = 0.2,
                condition = 100,
                wetness = 0,
                frostbitten = false,
            }
        end
    end
    Items.sortInventory(run.player.inventory)
    Survival.updateCarryWeight(run.player)
    addSkillXP(run.player, recipe.skill, 14)
end

function Survival.createPlayer(feats)
    local player = {
        coord = {0, 0},
        lastMoveX = 0,
        lastMoveY = 1,
        lastSafeCoord = {0, 0},
        condition = CONFIG.MAX_CONDITION,
        maxCondition = CONFIG.MAX_CONDITION,
        warmth = 80,
        fatigue = CONFIG.MAX_FATIGUE,
        thirst = CONFIG.MAX_THIRST,
        calories = 1800,
        carryWeight = 0,
        carryCapacity = CONFIG.CARRY_CAPACITY,
        clothing = createDefaultClothing(),
        inventory = {},
        bedrollDeployed = false,
        equippedLight = nil,
        equippedLightHours = 0,
        equippedTool = "knife",
        equippedWeapon = nil,
        weakIceHours = 0,
        frostbiteHours = 0,
        frostbiteCount = 0,
        afflictions = {
            hypothermiaRisk = 0,
            hypothermia = false,
            hypothermiaRecovery = 0,
            sprain = false,
            sprainRisk = 0,
            sprainRecovery = CONFIG.SPRAIN_RECOVERY_HOURS,
            infectionRiskHours = 0,
            infection = false,
            foodPoisoningHours = 0,
        },
        skills = createSkillSet(),
        alive = true,
    }

    Items.add(player.inventory, "matches", 8)
    Items.add(player.inventory, "tinder", 3)
    Items.add(player.inventory, "firewood", 2)
    Items.add(player.inventory, "water", 2)
    Items.add(player.inventory, "canned_food", 2)
    Items.add(player.inventory, "cloth", 2)
    Items.add(player.inventory, "sewing_kit", 3)
    Items.add(player.inventory, "bedroll", 1)
    Items.add(player.inventory, "knife", 1)
    Items.add(player.inventory, "hatchet", 1)
    Items.add(player.inventory, "bandage", 1)
    Items.add(player.inventory, "painkillers", 1)
    Items.add(player.inventory, "charcoal", 1)
    Items.sortInventory(player.inventory)

    feats = feats or {}
    if feats.PackMule then
        player.carryCapacity = player.carryCapacity + 3.0
    end
    if feats.Outdoorsman then
        player.warmth = 90
    end

    player.carryWeight = Items.totalWeight(player.inventory)
    return player
end

function Survival.updateCarryWeight(player)
    player.carryWeight = Items.totalWeight(player.inventory)
    return player.carryWeight
end

function Survival.currentTile(run, coord)
    return tileAt(run.world.grid, coord or run.player.coord)
end

function Survival.isWalkableTile(tile)
    return isWalkableTile(tile)
end

function Survival.isSheltered(run, coord)
    coord = coord or run.player.coord
    local tile = Survival.currentTile(run, coord)
    if isShelterTile(tile) then
        return true
    end

    for _, shelter in ipairs(run.world.snowShelters or {}) do
        if shelter.integrity > 0 and Utils.distance(coord[1], coord[2], shelter.coord[1], shelter.coord[2]) < CONFIG.TILE_SIZE then
            return true
        end
    end

    return false
end

function Survival.visibleRadius(run)
    local radius = CONFIG.VISIBLE_RADIUS_DAY
    local weather = run.world.weather.current
    local hour = run.world.timeOfDay

    if hour < 6 or hour >= 18 then
        radius = CONFIG.VISIBLE_RADIUS_NIGHT
    end
    if weather == "blizzard" then
        radius = math.min(radius, CONFIG.VISIBLE_RADIUS_BLIZZARD)
    elseif weather == "wind" then
        radius = radius - 1
    elseif weather == "snow" then
        radius = radius - 0.5
    end
    if Survival.isSheltered(run, run.player.coord) then
        radius = radius + CONFIG.VISIBLE_RADIUS_SHELTER_BONUS
    end
    if run.player.equippedLight and run.player.equippedLightHours > 0 then
        radius = radius + CONFIG.VISIBLE_RADIUS_LIGHT_BONUS
    end

    return Utils.clamp(math.floor(radius + 0.5), 2, 10)
end

function Survival.getSkillLevel(player, skillName)
    return skillBonus(player, skillName)
end

function Survival.gainSkillXP(player, skillName, amount)
    return addSkillXP(player, skillName, amount)
end

function Survival.applyInfectionRisk(player, hours)
    player.afflictions.infectionRiskHours = math.max(player.afflictions.infectionRiskHours or 0, hours or CONFIG.INFECTION_RISK_HOURS)
end

function Survival.applyFoodPoisoning(run)
    inflictFoodPoisoning(run)
end

function Survival.canSleepAt(run)
    local player = run.player
    local tile = Survival.currentTile(run)
    if tile == "cabin_bed" or tile == "cabin_floor" or tile == "cave_floor" or tile == "snow_shelter" then
        return true
    end

    for _, shelter in ipairs(run.world.snowShelters or {}) do
        if shelter.integrity > 0 and Utils.distance(player.coord[1], player.coord[2], shelter.coord[1], shelter.coord[2]) < CONFIG.TILE_SIZE then
            return true
        end
    end

    if Items.count(player.inventory, "bedroll") > 0 and tile ~= "weak_ice" and tile ~= "ice" and tile ~= "lake" then
        return isWalkableTile(tile)
    end

    return false
end

function Survival.availableCraftRecipes(run)
    local available = {}
    for _, recipe in ipairs(CRAFT_RECIPES) do
        local craftable = hasMaterials(run.player.inventory, recipe.inputs)
        if recipe.requiresWorkbench then
            craftable = craftable and Survival.isWorkbenchNearby(run)
        else
            craftable = craftable and Survival.isSheltered(run, run.player.coord)
        end
        table.insert(available, {
            key = recipe.key,
            label = recipe.label,
            craftable = craftable,
            requiresWorkbench = recipe.requiresWorkbench or false,
            inputs = Utils.deepCopy(recipe.inputs),
            outputs = Utils.deepCopy(recipe.outputs),
        })
    end
    return available
end

function Survival.craftRecipe(run, recipeKey)
    local recipe
    for _, entry in ipairs(CRAFT_RECIPES) do
        if entry.key == recipeKey then
            recipe = entry
            break
        end
    end

    if not recipe then
        return false, "Unknown recipe."
    end
    if recipe.requiresWorkbench and not Survival.isWorkbenchNearby(run) then
        return false, "You need a workbench."
    end
    if not recipe.requiresWorkbench and not Survival.isSheltered(run, run.player.coord) then
        return false, "You need shelter to craft that."
    end
    if not hasMaterials(run.player.inventory, recipe.inputs) then
        return false, "Missing materials."
    end

    for kind, quantity in pairs(recipe.inputs) do
        Items.remove(run.player.inventory, kind, quantity)
    end
    applyRecipeOutput(run, recipe)
    return true, "Crafted " .. recipe.label .. "."
end

function Survival.isWorkbenchNearby(run)
    local workbench = findNearby(run.world.workbenches, run.player.coord)
    return workbench ~= nil
end

function Survival.isMapNodeNearby(run)
    local node = findNearby(run.world.mapNodes, run.player.coord)
    return node ~= nil
end

function Survival.mapArea(run)
    if Items.count(run.player.inventory, "charcoal") < 1 then
        return false, "You need charcoal to sketch the area."
    end
    local node = findNearby(run.world.mapNodes, run.player.coord)
    if not node then
        return false, "Find an overlook before mapping."
    end

    Items.remove(run.player.inventory, "charcoal", 1)
    markMappedTiles(run, node.coord, CONFIG.MAP_REVEAL_RADIUS)
    run.player.fatigue = clamp(run.player.fatigue - CONFIG.MAP_REVEAL_FATIGUE_COST, CONFIG.MAX_FATIGUE)
    run.runtime.pendingPulse = {
        kind = "mapping",
        coord = {node.coord[1], node.coord[2]},
    }
    Survival.updateCarryWeight(run.player)
    return true, "You map the nearby terrain."
end

function Survival.useRopeClimb(run)
    local node = findNearby(run.world.climbNodes, run.player.coord)
    if not node then
        return false, "No climb nearby."
    end
    if run.player.fatigue < CONFIG.ROPE_CLIMB_FATIGUE_COST then
        return false, "You are too exhausted to climb."
    end

    run.player.fatigue = clamp(run.player.fatigue - CONFIG.ROPE_CLIMB_FATIGUE_COST, CONFIG.MAX_FATIGUE)
    if run.player.afflictions.sprain then
        run.player.condition = clamp(run.player.condition - CONFIG.ROPE_CLIMB_CONDITION_COST, run.player.maxCondition)
    end
    run.player.coord = {node.targetCoord[1], node.targetCoord[2]}
    run.player.lastSafeCoord = {node.targetCoord[1], node.targetCoord[2]}
    Survival.advanceTime(run, CONFIG.ROPE_CLIMB_HOURS)
    run.runtime.pendingPulse = {
        kind = "climb",
        coord = {node.targetCoord[1], node.targetCoord[2]},
    }
    return true, "You climb the rope."
end

function Survival.startCuring(run)
    local station = findNearby(run.world.curingStations, run.player.coord)
    if not station then
        return false, "You need a sheltered curing spot."
    end

    local moved = false
    local transfer = {
        rabbit_pelt = "cured_rabbit_pelt",
        deer_hide = "cured_deer_hide",
        gut = "cured_gut",
    }

    for inputKind, outputKind in pairs(transfer) do
        local count = Items.count(run.player.inventory, inputKind)
        if count > 0 then
            Items.remove(run.player.inventory, inputKind, count)
            for _ = 1, count do
                table.insert(run.world.curing, {
                    kind = inputKind,
                    outputKind = outputKind,
                    coord = {station.coord[1], station.coord[2]},
                    hoursRemaining = CONFIG.CURING_HOURS[inputKind] or 8,
                })
            end
            moved = true
        end
    end

    if not moved then
        return false, "Nothing fresh to cure."
    end

    Survival.updateCarryWeight(run.player)
    return true, "You hang materials to cure."
end

function Survival.collectCuredItems(run)
    local station = findNearby(run.world.curingStations, run.player.coord)
    if not station then
        return false, "No curing rack here."
    end

    local collected = 0
    for index = #run.world.curing, 1, -1 do
        local curing = run.world.curing[index]
        if curing.hoursRemaining <= 0
            and Utils.distance(station.coord[1], station.coord[2], curing.coord[1], curing.coord[2]) <= CONFIG.TILE_SIZE then
            Items.add(run.player.inventory, curing.outputKind, 1)
            table.remove(run.world.curing, index)
            collected = collected + 1
        end
    end

    if collected <= 0 then
        return false, "Nothing has finished curing."
    end

    Items.sortInventory(run.player.inventory)
    Survival.updateCarryWeight(run.player)
    return true, "Collected cured materials."
end

function Survival.consumeInventoryIndex(run, index)
    local item = run.player.inventory[index]
    if not item then
        return false, "Nothing in that slot."
    end

    local definition = Items.getDefinition(item.kind)
    if not definition then
        return false, "That item cannot be used."
    end

    if definition.equipSlot == "tool" then
        run.player.equippedTool = item.kind
        return true, "Equipped " .. Items.describe(item.kind) .. "."
    elseif definition.equipSlot == "weapon" then
        run.player.equippedWeapon = item.kind
        return true, "Readied " .. Items.describe(item.kind) .. "."
    end

    local used = false
    local message = "That item is used indirectly."

    if definition.calories then
        run.player.calories = clamp(run.player.calories + definition.calories, CONFIG.MAX_CALORIES)
        used = true
    end
    if definition.thirst then
        run.player.thirst = clamp(run.player.thirst + definition.thirst, CONFIG.MAX_THIRST)
        used = true
    end
    if definition.warmth then
        run.player.warmth = clamp(run.player.warmth + definition.warmth, CONFIG.MAX_WARMTH)
        used = true
    end
    if definition.condition then
        run.player.condition = clamp(run.player.condition + definition.condition, run.player.maxCondition)
        used = true
    end
    if definition.lightHours then
        run.player.equippedLight = item.kind
        run.player.equippedLightHours = definition.lightHours
        used = true
    end
    if definition.treatment then
        local treated = false
        if definition.treatment.sprain and run.player.afflictions.sprain then
            run.player.afflictions.sprain = false
            run.player.afflictions.sprainRisk = 0
            run.player.afflictions.sprainRecovery = CONFIG.SPRAIN_RECOVERY_HOURS
            treated = true
        end
        if definition.treatment.infectionRisk and (run.player.afflictions.infectionRiskHours or 0) > 0 then
            run.player.afflictions.infectionRiskHours = 0
            treated = true
        end
        if definition.treatment.infection and run.player.afflictions.infection then
            run.player.afflictions.infection = false
            treated = true
        end
        if treated then
            used = true
        end
    end

    if not used then
        return false, message
    end

    if definition.perishable and item.condition ~= nil then
        local threshold = definition.foodPoisoningThreshold or -1
        if item.condition <= threshold then
            inflictFoodPoisoning(run)
        end
    end

    Items.remove(run.player.inventory, item.kind, 1)
    Items.sortInventory(run.player.inventory)
    Survival.updateCarryWeight(run.player)
    return true, "Used " .. Items.describe(item.kind) .. "."
end

function Survival.craftSnowShelter(run)
    local tile = Survival.currentTile(run)
    if not isWalkableTile(tile) or tile == "ice" or tile == "weak_ice" then
        return false, "You need firm snow underfoot."
    end
    if Items.count(run.player.inventory, "sticks") < CONFIG.SNOW_SHELTER_STICK_COST
        or Items.count(run.player.inventory, "cloth") < CONFIG.SNOW_SHELTER_CLOTH_COST then
        return false, "Need more sticks and cloth."
    end

    Items.remove(run.player.inventory, "sticks", CONFIG.SNOW_SHELTER_STICK_COST)
    Items.remove(run.player.inventory, "cloth", CONFIG.SNOW_SHELTER_CLOTH_COST)
    table.insert(run.world.snowShelters, {
        coord = {run.player.coord[1], run.player.coord[2]},
        integrity = 100,
    })
    Survival.updateCarryWeight(run.player)
    return true, "Built a snow shelter."
end

function Survival.repairSnowShelter(run)
    for _, shelter in ipairs(run.world.snowShelters or {}) do
        if Utils.distance(run.player.coord[1], run.player.coord[2], shelter.coord[1], shelter.coord[2]) < CONFIG.TILE_SIZE then
            if Items.count(run.player.inventory, "sticks") < CONFIG.SNOW_SHELTER_REPAIR_STICKS
                or Items.count(run.player.inventory, "cloth") < CONFIG.SNOW_SHELTER_REPAIR_CLOTH then
                return false, "Need sticks and cloth to repair it."
            end
            Items.remove(run.player.inventory, "sticks", CONFIG.SNOW_SHELTER_REPAIR_STICKS)
            Items.remove(run.player.inventory, "cloth", CONFIG.SNOW_SHELTER_REPAIR_CLOTH)
            shelter.integrity = clamp(shelter.integrity + CONFIG.SNOW_SHELTER_REPAIR_AMOUNT, 100)
            Survival.updateCarryWeight(run.player)
            return true, "Snow shelter repaired."
        end
    end

    return false, "No snow shelter here."
end

function Survival.dismantleSnowShelter(run)
    for index = #run.world.snowShelters, 1, -1 do
        local shelter = run.world.snowShelters[index]
        if Utils.distance(run.player.coord[1], run.player.coord[2], shelter.coord[1], shelter.coord[2]) < CONFIG.TILE_SIZE then
            table.remove(run.world.snowShelters, index)
            Items.add(run.player.inventory, "sticks", 3)
            Items.add(run.player.inventory, "cloth", 1)
            Items.sortInventory(run.player.inventory)
            Survival.updateCarryWeight(run.player)
            return true, "Dismantled the shelter."
        end
    end

    return false, "No snow shelter here."
end

function Survival.repairWorstClothing(run)
    if Items.count(run.player.inventory, "cloth") < 1 or Items.count(run.player.inventory, "sewing_kit") < 1 then
        return false, "Need cloth and sewing kit."
    end

    local worst
    for _, slot in ipairs(CLOTHING_ORDER) do
        local item = run.player.clothing[slot]
        if not worst or item.condition < worst.condition then
            worst = item
        end
    end

    if not worst or worst.condition >= 100 then
        return false, "Clothing is already repaired."
    end

    Items.remove(run.player.inventory, "cloth", 1)
    Items.remove(run.player.inventory, "sewing_kit", 1)
    local repairAmount = CONFIG.CLOTHING_REPAIR_AMOUNT
    if run.feats.Seamster then
        repairAmount = repairAmount + 6
    end
    repairAmount = repairAmount + ((skillBonus(run.player, "Mending") - 1) * 2)
    worst.condition = clamp(worst.condition + repairAmount, 100)
    run.stats.clothingRepairs = run.stats.clothingRepairs + 1
    addSkillXP(run.player, "Mending", 12)
    Survival.updateCarryWeight(run.player)
    return true, "Patched your clothing."
end

function Survival.autoTreat(run)
    local inventory = run.player.inventory
    if run.player.afflictions.infection and Items.count(inventory, "antibiotics") > 0 then
        local index = Items.findIndex(inventory, "antibiotics")
        return Survival.consumeInventoryIndex(run, index)
    end
    if (run.player.afflictions.infectionRiskHours or 0) > 0 then
        local antisepticIndex = Items.findIndex(inventory, "antiseptic")
        if antisepticIndex then
            return Survival.consumeInventoryIndex(run, antisepticIndex)
        end
        local antibioticsIndex = Items.findIndex(inventory, "antibiotics")
        if antibioticsIndex then
            return Survival.consumeInventoryIndex(run, antibioticsIndex)
        end
    end
    if run.player.afflictions.sprain then
        local bandageIndex = Items.findIndex(inventory, "bandage")
        if bandageIndex then
            return Survival.consumeInventoryIndex(run, bandageIndex)
        end
        local painkillersIndex = Items.findIndex(inventory, "painkillers")
        if painkillersIndex then
            return Survival.consumeInventoryIndex(run, painkillersIndex)
        end
    end
    return false, "No treatment needed."
end

function Survival.advanceTime(run, hours)
    run.world.timeOfDay = run.world.timeOfDay + hours
    while run.world.timeOfDay >= 24 do
        run.world.timeOfDay = run.world.timeOfDay - 24
        run.world.dayCount = run.world.dayCount + 1
        run.stats.daysSurvived = run.world.dayCount
    end

    run.world.weather.hoursUntilChange = run.world.weather.hoursUntilChange - hours
    if run.world.weather.hoursUntilChange <= 0 then
        changeWeather(run, true)
    end
end

function Survival.update(run, hours, options)
    options = options or {}
    local player = run.player
    local difficulty = getDifficulty(run)
    local sheltered = Survival.isSheltered(run, player.coord)
    local tile = Survival.currentTile(run)
    local heatFactor = getFireHeatHours(run)
    local clothingWarmth, clothingWindproof, peakWetness = clothingTotals(player)
    local weatherExposure = CONFIG.WEATHER_EXPOSURE_PER_HOUR[run.world.weather.current] or CONFIG.WEATHER_EXPOSURE_PER_HOUR.clear
    weatherExposure = weatherExposure - roomTemperatureModifier(run, player.coord)

    if run.world.timeOfDay < 6 or run.world.timeOfDay >= 18 then
        weatherExposure = weatherExposure + 3
    end
    if sheltered then
        weatherExposure = weatherExposure - clothingWindproof - 9
    else
        weatherExposure = weatherExposure - clothingWarmth - clothingWindproof * 0.6
    end
    weatherExposure = weatherExposure * difficulty.exposureMultiplier
    if player.afflictions.hypothermia then
        weatherExposure = weatherExposure + 4
    end

    local warmthGain = 0
    if sheltered then
        warmthGain = warmthGain + CONFIG.SHELTER_WARMTH_RECOVERY_PER_HOUR
    end
    if tile == "cabin_bed" then
        warmthGain = warmthGain + CONFIG.BED_WARMTH_RECOVERY_PER_HOUR
    end
    if heatFactor > 0 then
        warmthGain = warmthGain + (CONFIG.FIRE_WARMTH_RECOVERY_PER_HOUR * heatFactor)
    end

    if weatherExposure > 0 then
        player.warmth = clamp(player.warmth - (weatherExposure * hours), CONFIG.MAX_WARMTH)
    else
        player.warmth = clamp(player.warmth + ((math.abs(weatherExposure) + warmthGain) * hours), CONFIG.MAX_WARMTH)
    end

    local calorieRate = CONFIG.CALORIE_DRAIN_PER_HOUR * difficulty.calorieMultiplier
    local thirstRate = CONFIG.THIRST_DRAIN_PER_HOUR * difficulty.thirstMultiplier
    local fatigueRate = CONFIG.FATIGUE_DRAIN_PER_HOUR * difficulty.fatigueMultiplier

    if options.sprinting then
        calorieRate = calorieRate + CONFIG.SPRINT_CALORIE_BONUS_PER_HOUR
        fatigueRate = fatigueRate + CONFIG.SPRINT_FATIGUE_BONUS_PER_HOUR
    end

    local overweight = math.max(0, player.carryWeight - player.carryCapacity)
    if overweight > 0 then
        fatigueRate = fatigueRate + (CONFIG.OVERWEIGHT_FATIGUE_BONUS_PER_HOUR * overweight / 5)
    end
    if player.afflictions.sprain then
        fatigueRate = fatigueRate + 1.2
    end

    if options.sleeping then
        player.fatigue = clamp(player.fatigue + (38 * hours), CONFIG.MAX_FATIGUE)
        calorieRate = calorieRate * 0.9
        thirstRate = thirstRate * 1.1
    else
        player.fatigue = clamp(player.fatigue - (fatigueRate * hours), CONFIG.MAX_FATIGUE)
    end

    player.thirst = clamp(player.thirst - (thirstRate * hours), CONFIG.MAX_THIRST)
    player.calories = clamp(player.calories - (calorieRate * hours), CONFIG.MAX_CALORIES)

    if player.equippedLightHours > 0 then
        player.equippedLightHours = math.max(0, player.equippedLightHours - hours)
        if player.equippedLightHours <= 0 then
            player.equippedLight = nil
        end
    end

    if tile == "weak_ice" then
        player.weakIceHours = player.weakIceHours + hours
        if player.weakIceHours >= CONFIG.WEAK_ICE_WARNING_HOURS * 2 then
            player.weakIceHours = 0
            player.warmth = clamp(player.warmth - CONFIG.WEAK_ICE_BREAK_WARMTH_DAMAGE, CONFIG.MAX_WARMTH)
            player.condition = clamp(player.condition - CONFIG.WEAK_ICE_BREAK_CONDITION_DAMAGE, player.maxCondition)
            applyWetness(player, CONFIG.WEAK_ICE_WETNESS_GAIN)
            if player.lastSafeCoord then
                player.coord[1] = player.lastSafeCoord[1]
                player.coord[2] = player.lastSafeCoord[2]
            end
            run.runtime.pendingShake = {
                intensity = CONFIG.SCREEN_SHAKE_INTENSITY * 1.1,
                duration = CONFIG.SCREEN_SHAKE_DURATION * 1.2,
            }
            setDeathCause(run, "weak ice")
        end
    else
        player.weakIceHours = 0
    end

    if not sheltered then
        if run.world.weather.current == "blizzard" then
            applyWetness(player, CONFIG.BLIZZARD_WETNESS_PER_HOUR * hours)
        elseif run.world.weather.current == "snow" then
            applyWetness(player, CONFIG.SNOW_WETNESS_PER_HOUR * hours)
        end
    end
    dryClothing(player, hours, heatFactor, sheltered)

    if peakWetness >= CONFIG.FROSTBITE_WETNESS_THRESHOLD and player.warmth <= CONFIG.FROSTBITE_WARMTH_THRESHOLD then
        player.frostbiteHours = player.frostbiteHours + (CONFIG.FROSTBITE_RISK_PER_HOUR * hours)
        while player.frostbiteHours >= 1 do
            player.frostbiteHours = player.frostbiteHours - 1
            applyFrostbite(player)
        end
    else
        player.frostbiteHours = math.max(0, player.frostbiteHours - hours * 0.5)
    end

    updatePerishables(run, hours, heatFactor)
    updateCuring(run, hours)
    updateAfflictions(run, hours, options, sheltered, peakWetness)

    if player.warmth <= 0 then
        player.condition = clamp(player.condition - (CONFIG.CONDITION_DRAIN_FREEZING_PER_HOUR * hours), player.maxCondition)
        setDeathCause(run, "freezing")
    end
    if player.thirst <= 0 then
        player.condition = clamp(player.condition - (CONFIG.CONDITION_DRAIN_THIRST_PER_HOUR * hours), player.maxCondition)
        setDeathCause(run, "dehydration")
    end
    if player.calories <= 0 then
        player.condition = clamp(player.condition - (CONFIG.CONDITION_DRAIN_STARVING_PER_HOUR * hours), player.maxCondition)
        setDeathCause(run, "starvation")
    end

    if options.sleeping
        and player.warmth > 0
        and player.thirst > 0
        and player.calories > 0
        and not player.afflictions.hypothermia
        and (player.afflictions.foodPoisoningHours or 0) <= 0 then
        local recovery = CONFIG.CONDITION_RECOVERY_SLEEP_PER_HOUR * hours
        if run.feats.Beddown then
            recovery = recovery + (hours * 1.0)
        end
        player.condition = clamp(player.condition + recovery, player.maxCondition)
    end

    for index = #run.world.snowShelters, 1, -1 do
        local shelter = run.world.snowShelters[index]
        shelter.integrity = shelter.integrity - (CONFIG.SNOW_SHELTER_DECAY_PER_HOUR * hours)
        if shelter.integrity <= 0 then
            table.remove(run.world.snowShelters, index)
        end
    end

    if player.condition <= 0 then
        player.alive = false
    end
end

return Survival
