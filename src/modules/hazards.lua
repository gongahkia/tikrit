local CONFIG = require("config")
local Accessibility = require("modules/accessibility")

local Hazards = {}

local function overlaps(coordA, coordB)
    return coordA[1] + CONFIG.TILE_SIZE > coordB[1]
        and coordA[1] < coordB[1] + CONFIG.TILE_SIZE
        and coordA[2] + CONFIG.TILE_SIZE > coordB[2]
        and coordA[2] < coordB[2] + CONFIG.TILE_SIZE
end

local function isInsideZone(coord, zone)
    return coord[1] >= zone.x
        and coord[1] <= zone.x + zone.width
        and coord[2] >= zone.y
        and coord[2] <= zone.y + zone.height
end

local function gridFromCoord(coord)
    return math.floor(coord[1] / CONFIG.TILE_SIZE) + 1, math.floor(coord[2] / CONFIG.TILE_SIZE) + 1
end

function Hazards.update(hazards, player, dt)
    local result = {
        playerKilled = false,
        spikeTriggered = false,
        cursedTriggered = false,
        sanityShock = 0,
    }

    if not hazards then
        return result
    end

    local cycleDuration = CONFIG.SPIKE_ACTIVE_TIME + CONFIG.SPIKE_INACTIVE_TIME

    for _, spike in ipairs(hazards.spikes or {}) do
        spike.timer = ((spike.timer or 0) + dt) % cycleDuration
        spike.active = spike.timer < CONFIG.SPIKE_ACTIVE_TIME
        spike.hitCooldown = math.max(0, (spike.hitCooldown or 0) - dt)

        if spike.active and spike.hitCooldown <= 0 and overlaps(player.coord, spike.coord) then
            spike.hitCooldown = cycleDuration
            result.playerKilled = true
            result.spikeTriggered = true
        end
    end

    for _, zone in ipairs(hazards.cursedZones or {}) do
        if not zone.triggered and isInsideZone(player.coord, zone) then
            zone.triggered = true
            result.cursedTriggered = true
            result.sanityShock = result.sanityShock + CONFIG.SANITY_CURSED_ROOM_SHOCK
        end
    end

    return result
end

function Hazards.draw(hazards, settings, tileVisibleFn)
    if not hazards then
        return
    end

    for _, zone in ipairs(hazards.cursedZones or {}) do
        Accessibility.setColor(settings, 0.42, 0.08, 0.08, zone.triggered and 0.28 or 0.16)
        love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
    end

    for _, spike in ipairs(hazards.spikes or {}) do
        local gridX, gridY = gridFromCoord(spike.coord)
        if not tileVisibleFn or tileVisibleFn(gridX, gridY) then
            local color = spike.active and {0.95, 0.22, 0.22, 0.95} or {0.45, 0.45, 0.45, 0.85}
            Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
            love.graphics.rectangle("fill", spike.coord[1] + 3, spike.coord[2] + 3, CONFIG.TILE_SIZE - 6, CONFIG.TILE_SIZE - 6)
        end
    end
end

return Hazards
