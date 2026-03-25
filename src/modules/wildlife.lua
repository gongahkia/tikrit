local CONFIG = require("config")
local Items = require("modules/items")
local Survival = require("modules/survival")
local Utils = require("modules/utils")

local Wildlife = {}

local function isWalkable(tile)
    return tile ~= "tree"
        and tile ~= "rock"
        and tile ~= "lake"
        and tile ~= "cabin_wall"
        and tile ~= "cave_wall"
end

local function tileAt(grid, coord)
    local gx, gy = Utils.pixelToGrid(coord[1], coord[2])
    local row = grid[gy + 1]
    return row and row[gx + 1]
end

local function setTargetInZone(entity, zone)
    entity.target = {
        math.random(zone.x, zone.x + zone.width) * CONFIG.TILE_SIZE,
        math.random(zone.y, zone.y + zone.height) * CONFIG.TILE_SIZE,
    }
end

local function moveEntity(entity, speed, hours, grid)
    if not entity.target then
        return
    end

    local distance = Utils.distance(entity.coord[1], entity.coord[2], entity.target[1], entity.target[2])
    if distance < 2 then
        entity.target = nil
        return
    end

    local dx = (entity.target[1] - entity.coord[1]) / distance
    local dy = (entity.target[2] - entity.coord[2]) / distance
    local step = speed * hours * (CONFIG.DAY_DURATION_SECONDS / 24)
    local nextCoord = {
        entity.coord[1] + (dx * step),
        entity.coord[2] + (dy * step),
    }

    if isWalkable(tileAt(grid, nextCoord)) then
        entity.coord = nextCoord
    else
        entity.target = nil
    end
end

local function playerDeterrenceRadius(player)
    if player.equippedLight == "flare" then
        return CONFIG.WOLF_LIGHT_DETERRENCE_TILES * CONFIG.TILE_SIZE
    elseif player.equippedLight == "torch" then
        return (CONFIG.WOLF_LIGHT_DETERRENCE_TILES - 1) * CONFIG.TILE_SIZE
    end
    return 0
end

local function fireDetersWolf(run, wolf)
    for _, fire in ipairs(run.world.fires or {}) do
        if fire.remainingBurnHours > 0 then
            local distance = Utils.distance(wolf.coord[1], wolf.coord[2], fire.coord[1], fire.coord[2])
            if distance <= CONFIG.WOLF_FIRE_DETERRENCE_TILES * CONFIG.TILE_SIZE then
                return true
            end
        end
    end
    return false
end

local function carcassDrops(kind)
    if kind == "deer" then
        return {
            raw_meat = 3,
            deer_hide = 1,
            gut = 2,
            feather = 2,
        }
    elseif kind == "rabbit" then
        return {
            raw_meat = 1,
            rabbit_pelt = 1,
            gut = 1,
        }
    elseif kind == "fish" then
        return {
            raw_fish = 1,
        }
    end
    return {}
end

function Wildlife.spawnCarcass(run, kind, coord)
    run.world.carcasses = run.world.carcasses or {}
    table.insert(run.world.carcasses, {
        kind = kind,
        coord = {coord[1], coord[2]},
        drops = carcassDrops(kind),
        harvestHours = CONFIG.HARVEST_HOURS[kind] or 0.5,
    })
end

local function resolveStruggle(run, wolf)
    local damage = CONFIG.WOLF_STRUGGLE_BASE_DAMAGE
    if run.player.equippedTool == "knife" then
        damage = damage - 4
    elseif run.player.equippedTool == "hatchet" then
        damage = damage - 2
    end
    if run.player.fatigue < 30 then
        damage = damage + 4
    end
    if run.player.condition < 40 then
        damage = damage + 4
    end

    run.player.condition = Utils.clamp(run.player.condition - damage, 0, run.player.maxCondition)
    run.player.warmth = Utils.clamp(run.player.warmth - 12, 0, CONFIG.MAX_WARMTH)
    run.runtime.causeOfDeath = "wolf attack"
    Survival.applyInfectionRisk(run.player, CONFIG.INFECTION_RISK_HOURS)

    local torso = run.player.clothing.torso
    if torso then
        torso.condition = Utils.clamp(torso.condition - 12, 0, 100)
    end

    run.runtime.pendingShake = {
        intensity = CONFIG.SCREEN_SHAKE_INTENSITY,
        duration = CONFIG.SCREEN_SHAKE_DURATION,
    }
    run.runtime.pendingPulse = {
        kind = "impact",
        coord = {run.player.coord[1], run.player.coord[2]},
    }
    wolf.state = "retreat"
    wolf.fearHours = 0.75
    run.stats.wolvesRepelled = run.stats.wolvesRepelled + 1
end

local function updateWolf(run, wolf, hours)
    local player = run.player
    local distance = Utils.distance(player.coord[1], player.coord[2], wolf.coord[1], wolf.coord[2])
    local lightRadius = playerDeterrenceRadius(player)
    local lightDeterrent = lightRadius > 0 and distance <= lightRadius
    local fireDeterrent = fireDetersWolf(run, wolf)

    if wolf.state == "retreat" then
        wolf.fearHours = math.max(0, (wolf.fearHours or 0) - hours)
        if not wolf.target then
            wolf.target = {
                wolf.territoryCenter[1] + math.random(-3, 3) * CONFIG.TILE_SIZE,
                wolf.territoryCenter[2] + math.random(-3, 3) * CONFIG.TILE_SIZE,
            }
        end
        moveEntity(wolf, CONFIG.WOLF_RETREAT_SPEED, hours, run.world.grid)
        if wolf.fearHours <= 0 and distance > CONFIG.WOLF_DETECTION_RADIUS_TILES * CONFIG.TILE_SIZE then
            wolf.state = "roam"
            wolf.target = nil
        end
        return
    end

    if fireDeterrent or lightDeterrent then
        wolf.state = "retreat"
        wolf.fearHours = 0.8
        run.stats.wolvesRepelled = run.stats.wolvesRepelled + 1
        return
    end

    if distance <= CONFIG.WOLF_CONTACT_RADIUS_TILES * CONFIG.TILE_SIZE then
        resolveStruggle(run, wolf)
        return
    end

    if distance <= CONFIG.WOLF_CHARGE_RADIUS_TILES * CONFIG.TILE_SIZE then
        wolf.state = "charge"
        wolf.target = {player.coord[1], player.coord[2]}
        moveEntity(wolf, CONFIG.WOLF_CHARGE_SPEED, hours, run.world.grid)
        return
    end

    if distance <= CONFIG.WOLF_DETECTION_RADIUS_TILES * CONFIG.TILE_SIZE then
        wolf.state = "stalk"
        wolf.target = {player.coord[1], player.coord[2]}
        moveEntity(wolf, CONFIG.WOLF_STALK_SPEED, hours, run.world.grid)
        return
    end

    wolf.state = "roam"
    if not wolf.target or math.random() < 0.03 then
        wolf.target = {
            wolf.territoryCenter[1] + math.random(-4, 4) * CONFIG.TILE_SIZE,
            wolf.territoryCenter[2] + math.random(-4, 4) * CONFIG.TILE_SIZE,
        }
    end
    moveEntity(wolf, CONFIG.WOLF_ROAM_SPEED, hours, run.world.grid)
end

local function setFleeTarget(entity, playerCoord)
    local dx = entity.coord[1] - playerCoord[1]
    local dy = entity.coord[2] - playerCoord[2]
    local distance = math.max(1, math.sqrt((dx * dx) + (dy * dy)))
    entity.target = {
        entity.coord[1] + (dx / distance) * CONFIG.TILE_SIZE * 3,
        entity.coord[2] + (dy / distance) * CONFIG.TILE_SIZE * 3,
    }
end

local function updatePassive(entity, hours, grid, playerCoord)
    if Utils.distance(entity.coord[1], entity.coord[2], playerCoord[1], playerCoord[2]) <= CONFIG.PASSIVE_FLEE_RADIUS_TILES * CONFIG.TILE_SIZE then
        setFleeTarget(entity, playerCoord)
    elseif not entity.target or math.random() < 0.04 then
        setTargetInZone(entity, entity.zone)
    end
    moveEntity(entity, entity.speed, hours, grid)
end

function Wildlife.findNearbyTrap(run)
    for index, trap in ipairs(run.world.traps or {}) do
        local distance = Utils.distance(run.player.coord[1], run.player.coord[2], trap.coord[1], trap.coord[2])
        if distance <= CONFIG.TILE_SIZE * 1.2 then
            return trap, index
        end
    end
    return nil
end

function Wildlife.findNearbyCarcass(run)
    for index, carcass in ipairs(run.world.carcasses or {}) do
        local distance = Utils.distance(run.player.coord[1], run.player.coord[2], carcass.coord[1], carcass.coord[2])
        if distance <= CONFIG.TILE_SIZE * 1.2 then
            return carcass, index
        end
    end
    return nil
end

local function pointInZone(coord, zone)
    local gx, gy = Utils.pixelToGrid(coord[1], coord[2])
    local tileX = gx + 1
    local tileY = gy + 1
    return tileX >= zone.x
        and tileX <= zone.x + zone.width
        and tileY >= zone.y
        and tileY <= zone.y + zone.height
end

function Wildlife.placeSnare(run)
    if Items.count(run.player.inventory, "snare") < 1 then
        return false, "You need a snare."
    end

    local validZone
    for _, zone in ipairs(run.world.rabbitZones or {}) do
        if pointInZone(run.player.coord, zone) then
            validZone = zone
            break
        end
    end
    if not validZone then
        return false, "Set snares on rabbit trails."
    end

    Items.remove(run.player.inventory, "snare", 1)
    table.insert(run.world.traps, {
        coord = {run.player.coord[1], run.player.coord[2]},
        zone = validZone,
        state = "set",
        hoursUntilCatch = math.random(CONFIG.SNARE_CATCH_MIN_HOURS, CONFIG.SNARE_CATCH_MAX_HOURS),
    })
    Survival.updateCarryWeight(run.player)
    return true, "You set a snare."
end

function Wildlife.collectTrap(run)
    local trap, index = Wildlife.findNearbyTrap(run)
    if not trap or trap.state ~= "caught" then
        return false, "No caught snare here."
    end

    Wildlife.spawnCarcass(run, "rabbit", trap.coord)
    table.remove(run.world.traps, index)
    return true, "A rabbit is caught in the snare."
end

function Wildlife.harvestNearbyCarcass(run)
    local carcass, index = Wildlife.findNearbyCarcass(run)
    if not carcass then
        return false, "No carcass nearby."
    end

    for kind, quantity in pairs(carcass.drops or carcassDrops(carcass.kind)) do
        if quantity > 0 then
            Items.add(run.player.inventory, kind, quantity)
        end
    end
    Items.sortInventory(run.player.inventory)
    Survival.updateCarryWeight(run.player)
    Survival.advanceTime(run, carcass.harvestHours or (CONFIG.HARVEST_HOURS[carcass.kind] or 0.5))
    run.player.fatigue = Utils.clamp(run.player.fatigue - 4, 0, CONFIG.MAX_FATIGUE)
    Survival.gainSkillXP(run.player, "Harvesting", 14)
    if run.player.equippedTool ~= "knife" and run.player.equippedTool ~= "hatchet" then
        Survival.applyInfectionRisk(run.player, CONFIG.INFECTION_RISK_HOURS)
    end
    table.remove(run.world.carcasses, index)
    return true, "You harvest the carcass."
end

function Wildlife.fireBow(run)
    if run.player.equippedWeapon ~= "bow" then
        return false, "You need a bow ready."
    end
    if Items.count(run.player.inventory, "arrow") < 1 then
        return false, "You have no arrows."
    end

    local aimX = run.player.lastMoveX ~= 0 and run.player.lastMoveX or 1
    local aimY = run.player.lastMoveY
    local bestTarget
    local bestDistance = math.huge

    local function consider(list, kind)
        for index, animal in ipairs(list or {}) do
            local dx = animal.coord[1] - run.player.coord[1]
            local dy = animal.coord[2] - run.player.coord[2]
            local distance = math.sqrt((dx * dx) + (dy * dy))
            if distance <= CONFIG.ARROW_RANGE_TILES * CONFIG.TILE_SIZE then
                local dot = ((dx / math.max(1, distance)) * aimX) + ((dy / math.max(1, distance)) * aimY)
                if dot >= 0.82 and distance < bestDistance then
                    bestTarget = {
                        list = list,
                        index = index,
                        kind = kind,
                        coord = {animal.coord[1], animal.coord[2]},
                    }
                    bestDistance = distance
                end
            end
        end
    end

    consider(run.world.wildlife.rabbits, "rabbit")
    consider(run.world.wildlife.deer, "deer")

    Items.remove(run.player.inventory, "arrow", 1)
    Survival.updateCarryWeight(run.player)
    Survival.gainSkillXP(run.player, "Archery", 12)

    if not bestTarget then
        run.runtime.pendingPulse = {
            kind = "impact",
            coord = {
                run.player.coord[1] + aimX * CONFIG.ARROW_RANGE_TILES * CONFIG.TILE_SIZE,
                run.player.coord[2] + aimY * CONFIG.ARROW_RANGE_TILES * CONFIG.TILE_SIZE,
            },
        }
        return false, "The arrow vanishes into the snow."
    end

    table.remove(bestTarget.list, bestTarget.index)
    Wildlife.spawnCarcass(run, bestTarget.kind, bestTarget.coord)
    run.runtime.pendingPulse = {
        kind = "impact",
        coord = {bestTarget.coord[1], bestTarget.coord[2]},
    }
    return true, "Your arrow drops the " .. bestTarget.kind .. "."
end

function Wildlife.fish(run)
    local nearby
    for _, spot in ipairs(run.world.fishingSpots or {}) do
        local distance = Utils.distance(run.player.coord[1], run.player.coord[2], spot.coord[1], spot.coord[2])
        if distance <= CONFIG.TILE_SIZE * 1.2 then
            nearby = spot
            break
        end
    end
    if not nearby then
        return false, "Find a fishing hole."
    end
    if Items.count(run.player.inventory, "fishing_tackle") < 1 then
        return false, "You need fishing tackle."
    end

    Survival.advanceTime(run, CONFIG.FISHING_ACTION_HOURS)
    run.player.fatigue = Utils.clamp(run.player.fatigue - 6, 0, CONFIG.MAX_FATIGUE)
    local chance = CONFIG.FISHING_BASE_CHANCE + ((Survival.getSkillLevel(run.player, "Fishing") - 1) * 0.05)
    Survival.gainSkillXP(run.player, "Fishing", 12)
    if math.random() <= math.min(0.95, chance) then
        Wildlife.spawnCarcass(run, "fish", nearby.coord)
        run.runtime.pendingPulse = {
            kind = "fishing",
            coord = {nearby.coord[1], nearby.coord[2]},
        }
        return true, "You pull a fish from the ice."
    end
    return false, "Nothing bites."
end

function Wildlife.update(run, hours)
    for _, wolf in ipairs(run.world.wildlife.wolves or {}) do
        updateWolf(run, wolf, hours)
    end
    for _, rabbit in ipairs(run.world.wildlife.rabbits or {}) do
        updatePassive(rabbit, hours, run.world.grid, run.player.coord)
    end
    for _, deer in ipairs(run.world.wildlife.deer or {}) do
        updatePassive(deer, hours, run.world.grid, run.player.coord)
    end

    for _, trap in ipairs(run.world.traps or {}) do
        if trap.state == "set" then
            trap.hoursUntilCatch = trap.hoursUntilCatch - hours
            if trap.hoursUntilCatch <= 0 then
                trap.state = "caught"
            end
        end
    end
end

return Wildlife
