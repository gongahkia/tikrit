local CONFIG = require("config")
local Utils = require("modules/utils")

local Sanity = {}

local function clampSanity(value)
    return Utils.clamp(value, 0, CONFIG.SANITY_MAX)
end

function Sanity.initPlayer(player)
    player.maxSanity = CONFIG.SANITY_MAX
    player.sanity = player.maxSanity
    player.panicActive = false
    player.safeRecoveryTimer = 0
    player.falseCueTimer = 0
end

function Sanity.applyShock(player, amount)
    amount = amount or 0
    player.sanity = clampSanity((player.sanity or CONFIG.SANITY_MAX) - amount)
    if player.sanity <= 0 then
        player.panicActive = true
    end
    return player.sanity
end

function Sanity.restore(player, amount)
    amount = amount or 0
    player.sanity = clampSanity((player.sanity or 0) + amount)
    if player.panicActive and player.sanity >= 20 then
        player.panicActive = false
    end
    return player.sanity
end

function Sanity.getTier(player)
    if player.panicActive then
        return "panic"
    elseif player.sanity <= CONFIG.SANITY_BREAK_THRESHOLD then
        return "broken"
    elseif player.sanity <= CONFIG.SANITY_CRITICAL_THRESHOLD then
        return "critical"
    elseif player.sanity <= CONFIG.SANITY_LOW_THRESHOLD then
        return "low"
    end
    return "stable"
end

function Sanity.getEffects(player)
    local tier = Sanity.getTier(player)
    if tier == "panic" then
        return {
            tier = tier,
            visionPenalty = 99,
            minimapDisabled = true,
            monsterSpeedMultiplier = CONFIG.SANITY_PANIC_MONSTER_SPEED_MULTIPLIER,
            playerSpeedMultiplier = CONFIG.SANITY_PANIC_SPEED_MULTIPLIER,
            falseCueIntensity = 1.0,
        }
    elseif tier == "broken" then
        return {
            tier = tier,
            visionPenalty = 2,
            minimapDisabled = true,
            monsterSpeedMultiplier = 1.12,
            playerSpeedMultiplier = 0.92,
            falseCueIntensity = 0.7,
        }
    elseif tier == "critical" then
        return {
            tier = tier,
            visionPenalty = 1,
            minimapDisabled = false,
            monsterSpeedMultiplier = 1.06,
            playerSpeedMultiplier = 1.0,
            falseCueIntensity = 0.35,
        }
    elseif tier == "low" then
        return {
            tier = tier,
            visionPenalty = 0,
            minimapDisabled = false,
            monsterSpeedMultiplier = 1.0,
            playerSpeedMultiplier = 1.0,
            falseCueIntensity = 0.15,
        }
    end

    return {
        tier = tier,
        visionPenalty = 0,
        minimapDisabled = false,
        monsterSpeedMultiplier = 1.0,
        playerSpeedMultiplier = 1.0,
        falseCueIntensity = 0,
    }
end

function Sanity.isInsideZone(coord, zone)
    return coord[1] >= zone.x
        and coord[1] <= zone.x + zone.width
        and coord[2] >= zone.y
        and coord[2] <= zone.y + zone.height
end

local function countThreats(world, playerCoord)
    local threatCount = 0
    local wailerCount = 0
    local stalkerCount = 0

    for _, monster in ipairs(world.monsters or {}) do
        local distance = Utils.distance(playerCoord[1], playerCoord[2], monster.coord[1], monster.coord[2])
        if distance <= (monster.aggroRadius or 120) then
            threatCount = threatCount + 1
        end
        if monster.type == "wailer" and distance <= (monster.auraRadius or 120) then
            wailerCount = wailerCount + 1
        elseif monster.type == "stalker" and distance <= (monster.pressureRadius or 110) then
            stalkerCount = stalkerCount + 1
        end
    end

    return threatCount, wailerCount, stalkerCount
end

function Sanity.update(player, world, runtime, dt)
    local drain = 0
    local recovery = 0
    local inSafeZone = false
    local inDarkZone = false

    for _, zone in ipairs(world.safeZones or {}) do
        if Sanity.isInsideZone(player.coord, zone) then
            inSafeZone = true
            break
        end
    end

    for _, zone in ipairs(world.darkZones or {}) do
        if Sanity.isInsideZone(player.coord, zone) then
            inDarkZone = true
            break
        end
    end

    local threatCount, wailerCount, stalkerCount = countThreats(world, player.coord)

    if runtime.fogEnabled and not inSafeZone then
        drain = drain + CONFIG.SANITY_CREEPING_DRAIN
    end
    if inDarkZone then
        drain = drain + CONFIG.SANITY_DARK_ZONE_DRAIN
    end
    if wailerCount > 0 then
        drain = drain + (CONFIG.SANITY_WAILER_DRAIN * wailerCount)
    end
    if stalkerCount > 0 then
        drain = drain + (CONFIG.SANITY_STALKER_DRAIN * stalkerCount)
    end

    if threatCount == 0 and not inDarkZone then
        player.safeRecoveryTimer = player.safeRecoveryTimer + dt
        if player.safeRecoveryTimer >= CONFIG.SANITY_SAFE_DELAY then
            recovery = recovery + CONFIG.SANITY_PASSIVE_RECOVERY
        end
    else
        player.safeRecoveryTimer = 0
    end

    if inSafeZone then
        recovery = recovery + CONFIG.SANITY_PASSIVE_RECOVERY
    end

    if drain > 0 then
        Sanity.applyShock(player, drain * dt)
    end
    if recovery > 0 then
        Sanity.restore(player, recovery * dt)
    end

    if player.panicActive and player.sanity >= 20 then
        player.panicActive = false
    end

    return {
        inSafeZone = inSafeZone,
        inDarkZone = inDarkZone,
        threatCount = threatCount,
        tier = Sanity.getTier(player),
        effects = Sanity.getEffects(player),
    }
end

return Sanity
