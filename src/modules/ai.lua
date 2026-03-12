local CONFIG = require("config")
local Utils = require("modules/utils")

local AI = {}

local function collides(coord, walls)
    for _, wall in ipairs(walls) do
        if coord[1] + CONFIG.TILE_SIZE > wall[1]
            and coord[1] < wall[1] + CONFIG.TILE_SIZE
            and coord[2] + CONFIG.TILE_SIZE > wall[2]
            and coord[2] < wall[2] + CONFIG.TILE_SIZE then
            return true
        end
    end
    return false
end

local function moveWithCollision(monster, dx, dy, walls)
    local target = {monster.coord[1] + dx, monster.coord[2] + dy}
    if not collides(target, walls) then
        monster.coord = target
        return
    end

    local xOnly = {monster.coord[1] + dx, monster.coord[2]}
    if not collides(xOnly, walls) then
        monster.coord = xOnly
        return
    end

    local yOnly = {monster.coord[1], monster.coord[2] + dy}
    if not collides(yOnly, walls) then
        monster.coord = yOnly
    end
end

local function moveTowards(monster, targetCoord, dt, speed, walls)
    local distance = Utils.distance(monster.coord[1], monster.coord[2], targetCoord[1], targetCoord[2])
    if distance <= 0.01 then
        return
    end

    local dx = (targetCoord[1] - monster.coord[1]) / distance
    local dy = (targetCoord[2] - monster.coord[2]) / distance
    monster.facing = {dx, dy}
    moveWithCollision(monster, dx * speed * dt, dy * speed * dt, walls)
end

local function moveAway(monster, targetCoord, dt, speed, walls)
    local distance = Utils.distance(monster.coord[1], monster.coord[2], targetCoord[1], targetCoord[2])
    if distance <= 0.01 then
        return
    end

    local dx = (monster.coord[1] - targetCoord[1]) / distance
    local dy = (monster.coord[2] - targetCoord[2]) / distance
    monster.facing = {dx, dy}
    moveWithCollision(monster, dx * speed * dt, dy * speed * dt, walls)
end

local function getPatrolTarget(monster)
    if not monster.patrolPoints or #monster.patrolPoints == 0 then
        return monster.coord
    end

    monster.patrolIndex = monster.patrolIndex or 1
    local target = monster.patrolPoints[monster.patrolIndex]
    local distance = Utils.distance(monster.coord[1], monster.coord[2], target[1], target[2])
    if distance < CONFIG.TILE_SIZE * 0.6 then
        monster.patrolIndex = (monster.patrolIndex % #monster.patrolPoints) + 1
        target = monster.patrolPoints[monster.patrolIndex]
    end
    return target
end

function AI.createMonster(spawn, baseSpeed)
    local archetypes = {
        chaser = {
            health = CONFIG.MONSTER_MAX_HEALTH,
            speedMultiplier = 1.0,
            aggroRadius = 220,
            lootBias = "key",
        },
        patrol_warden = {
            health = CONFIG.MONSTER_MAX_HEALTH + 1,
            speedMultiplier = 0.9,
            aggroRadius = 190,
            lootBias = "item",
        },
        lurker = {
            health = CONFIG.MONSTER_MAX_HEALTH,
            speedMultiplier = 1.15,
            aggroRadius = 110,
            lootBias = "item",
        },
        wailer = {
            health = CONFIG.MONSTER_MAX_HEALTH - 1,
            speedMultiplier = 0.8,
            aggroRadius = 170,
            auraRadius = 120,
            lootBias = "sanity",
        },
        stalker = {
            health = CONFIG.MONSTER_MAX_HEALTH,
            speedMultiplier = 1.0,
            aggroRadius = 230,
            pressureRadius = 110,
            lootBias = "ward",
        }
    }

    local tuning = archetypes[spawn.type] or archetypes.chaser

    return {
        type = spawn.type,
        coord = {spawn.coord[1], spawn.coord[2]},
        health = tuning.health,
        speed = baseSpeed * tuning.speedMultiplier,
        state = "idle",
        aggroRadius = tuning.aggroRadius,
        auraRadius = tuning.auraRadius,
        pressureRadius = tuning.pressureRadius,
        patrolPoints = Utils.deepCopy(spawn.patrolPoints or {}),
        patrolIndex = 1,
        cooldowns = {
            burst = 0,
            hesitate = 0,
        },
        lootBias = tuning.lootBias,
        detectedPlayer = false,
        facing = {0, 1},
        bobScale = 1.0,
    }
end

function AI.canSeePlayer(monster, playerCoord, walls)
    local distance = Utils.distance(monster.coord[1], monster.coord[2], playerCoord[1], playerCoord[2])
    if distance > (monster.aggroRadius or 150) then
        return false
    end

    local steps = math.max(4, math.floor(distance / CONFIG.TILE_SIZE))
    for step = 1, steps do
        local t = step / steps
        local sample = {
            monster.coord[1] + (playerCoord[1] - monster.coord[1]) * t,
            monster.coord[2] + (playerCoord[2] - monster.coord[2]) * t,
        }
        if collides(sample, walls) then
            return false
        end
    end
    return true
end

local function updateChaser(monster, player, dt, walls)
    monster.state = "hunt"
    moveTowards(monster, player.coord, dt, monster.speed, walls)
end

local function updatePatrolWarden(monster, player, dt, walls, canSeePlayer)
    if canSeePlayer then
        monster.state = "guard"
        moveTowards(monster, player.coord, dt, monster.speed, walls)
    else
        monster.state = "patrol"
        moveTowards(monster, getPatrolTarget(monster), dt, monster.speed * 0.8, walls)
    end
end

local function updateLurker(monster, player, dt, walls)
    local distance = Utils.distance(monster.coord[1], monster.coord[2], player.coord[1], player.coord[2])
    if monster.cooldowns.burst > 0 then
        monster.cooldowns.burst = math.max(0, monster.cooldowns.burst - dt)
        monster.state = "rest"
        return
    end

    if distance <= monster.aggroRadius then
        monster.state = "burst"
        moveTowards(monster, player.coord, dt, monster.speed * 1.8, walls)
        if distance <= CONFIG.TILE_SIZE * 2.5 then
            monster.cooldowns.burst = 1.4
        end
    else
        monster.state = "lurking"
    end
end

local function updateWailer(monster, player, dt, walls)
    local distance = Utils.distance(monster.coord[1], monster.coord[2], player.coord[1], player.coord[2])
    monster.state = "wailing"

    if distance > 110 then
        moveTowards(monster, player.coord, dt, monster.speed, walls)
    elseif distance < 70 then
        moveAway(monster, player.coord, dt, monster.speed * 0.75, walls)
    else
        local patrolTarget = getPatrolTarget(monster)
        moveTowards(monster, patrolTarget, dt, monster.speed * 0.4, walls)
    end
end

local function updateStalker(monster, player, dt, walls, sanityEffects)
    local offsetX = player.coord[1] + (player.lastMoveX or 0) * 40 - (player.lastMoveY or 0) * 30
    local offsetY = player.coord[2] + (player.lastMoveY or 0) * 40 + (player.lastMoveX or 0) * 30
    local target = {offsetX, offsetY}
    local speed = monster.speed

    if sanityEffects.tier == "broken" or sanityEffects.tier == "panic" then
        speed = speed * 1.18
        monster.state = "pressing"
    else
        monster.state = "stalking"
    end

    moveTowards(monster, target, dt, speed, walls)
end

function AI.updateMonsters(monsters, player, world, runtime, dt)
    local sanityEffects = runtime.sanityEffects or {
        tier = "stable",
        monsterSpeedMultiplier = 1.0,
    }
    local summary = {
        newDetections = 0,
    }

    for _, monster in ipairs(monsters) do
        local effectiveSpeed = monster.speed * sanityEffects.monsterSpeedMultiplier
        monster.speed = effectiveSpeed
        local canSeePlayer = AI.canSeePlayer(monster, player.coord, world.walls)

        if canSeePlayer and not monster.detectedPlayer then
            summary.newDetections = summary.newDetections + 1
        end
        monster.detectedPlayer = canSeePlayer

        if monster.type == "chaser" then
            updateChaser(monster, player, dt, world.walls)
        elseif monster.type == "patrol_warden" then
            updatePatrolWarden(monster, player, dt, world.walls, canSeePlayer)
        elseif monster.type == "lurker" then
            updateLurker(monster, player, dt, world.walls)
        elseif monster.type == "wailer" then
            updateWailer(monster, player, dt, world.walls)
        elseif monster.type == "stalker" then
            updateStalker(monster, player, dt, world.walls, sanityEffects)
        else
            updateChaser(monster, player, dt, world.walls)
        end

        monster.speed = effectiveSpeed / sanityEffects.monsterSpeedMultiplier
    end

    return summary
end

function AI.getDrawStyle(monster)
    local styles = {
        chaser = {color = {1, 1, 1, 1}, bob = 1.0},
        patrol_warden = {color = {0.75, 0.95, 1, 1}, bob = 0.8},
        lurker = {color = {1, 0.9, 0.75, 1}, bob = 0.5},
        wailer = {color = {1, 0.45, 0.45, 1}, bob = 1.2},
        stalker = {color = {0.7, 1, 0.8, 1}, bob = 1.1},
    }
    return styles[monster.type] or styles.chaser
end

return AI
