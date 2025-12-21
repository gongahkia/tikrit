-- Audio module for positional audio and dynamic music
local CONFIG = require("config")

local Audio = {}

-- Initialize audio system
function Audio.init()
    -- Set up audio source properties if needed
end

-- Update positional audio based on ghost proximity
function Audio.updateGhostAudio(ghostScreamSound, playerCoord, monstersCoord)
    if not ghostScreamSound then
        return
    end
    
    local closestDistance = math.huge
    
    -- Find closest ghost
    for _, monsterCoord in ipairs(monstersCoord) do
        local dx = monsterCoord[1] - playerCoord[1]
        local dy = monsterCoord[2] - playerCoord[2]
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance < closestDistance then
            closestDistance = distance
        end
    end
    
    -- Calculate volume based on distance
    local maxDistance = CONFIG.GHOST_AUDIO_MAX_DISTANCE or 300
    local minDistance = CONFIG.GHOST_AUDIO_MIN_DISTANCE or 50
    
    if closestDistance < maxDistance then
        local volume = 1.0
        
        if closestDistance > minDistance then
            -- Linear falloff from min to max distance
            volume = 1.0 - ((closestDistance - minDistance) / (maxDistance - minDistance))
        end
        
        -- Clamp volume
        volume = math.max(0.1, math.min(1.0, volume))
        
        -- Set volume and ensure sound is playing
        ghostScreamSound:setVolume(volume * CONFIG.MASTER_VOLUME)
        
        if not ghostScreamSound:isPlaying() then
            love.audio.play(ghostScreamSound)
        end
    else
        -- Too far away, stop the sound
        if ghostScreamSound:isPlaying() then
            love.audio.stop(ghostScreamSound)
        end
    end
end

-- Calculate distance between two points
function Audio.calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Update ambient background music based on game state
function Audio.updateAmbientMusic(ambientSound, isPlayerAlive, ghostProximity)
    if not ambientSound then
        return
    end
    
    -- Ensure ambient music is playing
    if not ambientSound:isPlaying() then
        ambientSound:setLooping(true)
        love.audio.play(ambientSound)
    end
    
    -- Adjust volume based on proximity to danger
    local baseVolume = CONFIG.AMBIENT_BASE_VOLUME or 0.3
    local volume = baseVolume
    
    if not isPlayerAlive then
        -- Fade out when dead
        volume = 0.1
    elseif ghostProximity < 150 then
        -- Increase volume when ghosts are close (creates tension)
        volume = baseVolume + (1.0 - ghostProximity / 150) * 0.3
    end
    
    ambientSound:setVolume(volume * CONFIG.MASTER_VOLUME)
end

-- Duck audio (lower volume temporarily)
function Audio.duckAudio(sound, duckAmount, duration)
    if not sound or not sound:isPlaying() then
        return
    end
    
    local originalVolume = sound:getVolume()
    sound:setVolume(originalVolume * duckAmount)
    
    -- Could implement a timer to restore volume after duration
    -- For now, it will restore on next update cycle
end

return Audio
