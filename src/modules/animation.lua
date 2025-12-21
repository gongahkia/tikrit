-- Animation module for sprite animations
local CONFIG = require("config")

local Animation = {}

-- Animation state tracking
Animation.ghostBob = {}  -- Bobbing offset for each ghost
Animation.chestAnimations = {}  -- Opening animations for chests
Animation.doorAnimations = {}  -- Opening animations for doors
Animation.playerIdleTime = 0  -- For idle animation

-- Initialize animations
function Animation.init()
    Animation.ghostBob = {}
    Animation.chestAnimations = {}
    Animation.doorAnimations = {}
    Animation.playerIdleTime = 0
end

-- Update all animations
function Animation.update(dt)
    Animation.playerIdleTime = Animation.playerIdleTime + dt
    
    -- Update chest opening animations
    for i = #Animation.chestAnimations, 1, -1 do
        local anim = Animation.chestAnimations[i]
        anim.progress = anim.progress + dt
        
        if anim.progress >= anim.duration then
            table.remove(Animation.chestAnimations, i)
        end
    end
    
    -- Update door opening animations
    for i = #Animation.doorAnimations, 1, -1 do
        local anim = Animation.doorAnimations[i]
        anim.progress = anim.progress + dt
        
        if anim.progress >= anim.duration then
            table.remove(Animation.doorAnimations, i)
        end
    end
end

-- Initialize ghost bobbing for all monsters
function Animation.initGhostBobbing(monsterCount)
    for i = 1, monsterCount do
        Animation.ghostBob[i] = math.random() * math.pi * 2  -- Random phase offset
    end
end

-- Get ghost bobbing offset
function Animation.getGhostBobOffset(index, time)
    if not Animation.ghostBob[index] then
        Animation.ghostBob[index] = 0
    end
    
    local phase = Animation.ghostBob[index]
    local bobSpeed = CONFIG.GHOST_BOB_SPEED or 3
    local bobAmount = CONFIG.GHOST_BOB_AMOUNT or 3
    
    return math.sin(time * bobSpeed + phase) * bobAmount
end

-- Start chest opening animation
function Animation.startChestOpening(x, y)
    table.insert(Animation.chestAnimations, {
        x = x,
        y = y,
        progress = 0,
        duration = CONFIG.CHEST_OPEN_DURATION or 0.3,
    })
end

-- Get chest animation scale (for pop effect)
function Animation.getChestAnimationScale(x, y)
    for _, anim in ipairs(Animation.chestAnimations) do
        if anim.x == x and anim.y == y then
            local t = anim.progress / anim.duration
            -- Elastic pop effect
            if t < 0.5 then
                return 1 + (t * 2) * 0.3  -- Scale up to 1.3
            else
                return 1.3 - ((t - 0.5) * 2) * 0.3  -- Scale back to 1.0
            end
        end
    end
    return 1.0
end

-- Start door opening animation
function Animation.startDoorOpening(x, y)
    table.insert(Animation.doorAnimations, {
        x = x,
        y = y,
        progress = 0,
        duration = CONFIG.DOOR_OPEN_DURATION or 0.4,
    })
end

-- Get door animation alpha (fade out)
function Animation.getDoorAnimationAlpha(x, y)
    for _, anim in ipairs(Animation.doorAnimations) do
        if anim.x == x and anim.y == y then
            local t = anim.progress / anim.duration
            return 1.0 - t  -- Fade from 1.0 to 0.0
        end
    end
    return 1.0
end

-- Check if door is animating
function Animation.isDoorAnimating(x, y)
    for _, anim in ipairs(Animation.doorAnimations) do
        if anim.x == x and anim.y == y then
            return true
        end
    end
    return false
end

-- Get player idle animation scale (subtle pulse)
function Animation.getPlayerIdleScale()
    local pulseSpeed = CONFIG.PLAYER_IDLE_PULSE_SPEED or 2
    local pulseAmount = CONFIG.PLAYER_IDLE_PULSE_AMOUNT or 0.02
    
    return 1.0 + math.sin(Animation.playerIdleTime * pulseSpeed) * pulseAmount
end

return Animation
