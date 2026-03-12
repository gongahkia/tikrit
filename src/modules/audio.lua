local CONFIG = require("config")
local Utils = require("modules/utils")

local Audio = {}

function Audio.updateGhostAudio(settings, ghostScreamSound, playerCoord, monsters, sanityEffects)
    if not ghostScreamSound then
        return
    end

    local closestDistance = math.huge
    for _, monster in ipairs(monsters) do
        local distance = Utils.distance(playerCoord[1], playerCoord[2], monster.coord[1], monster.coord[2])
        if distance < closestDistance then
            closestDistance = distance
        end
    end

    if closestDistance >= CONFIG.GHOST_AUDIO_MAX_DISTANCE then
        if ghostScreamSound:isPlaying() then
            love.audio.stop(ghostScreamSound)
        end
        return
    end

    local minDistance = CONFIG.GHOST_AUDIO_MIN_DISTANCE
    local range = CONFIG.GHOST_AUDIO_MAX_DISTANCE - minDistance
    local volumeFactor = 1
    if closestDistance > minDistance then
        volumeFactor = 1 - ((closestDistance - minDistance) / range)
    end

    volumeFactor = Utils.clamp(volumeFactor, 0.1, 1)
    if sanityEffects and sanityEffects.tier ~= "stable" then
        volumeFactor = Utils.clamp(volumeFactor + sanityEffects.falseCueIntensity * 0.2, 0.1, 1)
    end

    ghostScreamSound:setVolume(volumeFactor * settings.audio.master * settings.audio.sfx)
    if not ghostScreamSound:isPlaying() then
        love.audio.play(ghostScreamSound)
    end
end

function Audio.updateAmbientMusic(settings, ambientSound, playerAlive, sanityEffects)
    if not ambientSound then
        return
    end

    if not ambientSound:isPlaying() then
        ambientSound:setLooping(true)
        love.audio.play(ambientSound)
    end

    local volume = CONFIG.AMBIENT_BASE_VOLUME
    if not playerAlive then
        volume = volume * 0.4
    elseif sanityEffects and sanityEffects.tier ~= "stable" then
        volume = volume + (sanityEffects.falseCueIntensity * 0.12)
    end

    ambientSound:setVolume(volume * settings.audio.master * settings.audio.music)
end

return Audio
