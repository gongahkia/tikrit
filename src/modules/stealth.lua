-- Stealth Mode Module
-- Implements stealth-based gameplay where detection matters more than collision
-- Ghosts have vision cones and players must avoid being seen

local Stealth = {}

-- Stealth configuration
local CONFIG = {
    VISION_CONE_ANGLE = math.pi / 3,  -- 60 degree cone
    VISION_RANGE = 200,  -- pixels
    DETECTION_TIME = 1.0,  -- seconds to fully detect
    ALERT_DURATION = 5.0,  -- seconds alert lasts
    ALERT_RADIUS = 400,  -- alert all ghosts within this radius
}

-- Stealth state
local enabled = false
local detectionStates = {}  -- {ghostIndex -> {detected: bool, detectionProgress: float, alerted: bool, alertTimer: float}}
local playerDetected = false
local totalAlertsTriggered = 0

-- Initialize stealth mode
function Stealth.init()
    enabled = false
    detectionStates = {}
    playerDetected = false
    totalAlertsTriggered = 0
    print("[Stealth] System initialized")
end

-- Enable stealth mode
function Stealth.enable()
    enabled = true
    detectionStates = {}
    playerDetected = false
    totalAlertsTriggered = 0
    print("[Stealth] Mode enabled")
end

-- Disable stealth mode
function Stealth.disable()
    enabled = false
    detectionStates = {}
    print("[Stealth] Mode disabled")
end

-- Check if stealth mode is enabled
function Stealth.isEnabled()
    return enabled
end

-- Get total alerts triggered (for stats/scoring)
function Stealth.getAlertsTriggered()
    return totalAlertsTriggered
end

-- Update stealth detection for all ghosts
function Stealth.update(dt, playerCoord, ghosts, walls)
    if not enabled then return end
    
    playerDetected = false
    
    for i, ghost in ipairs(ghosts) do
        if not detectionStates[i] then
            detectionStates[i] = {
                detected = false,
                detectionProgress = 0,
                alerted = false,
                alertTimer = 0
            }
        end
        
        local state = detectionStates[i]
        
        -- Update alert timer
        if state.alerted then
            state.alertTimer = state.alertTimer - dt
            if state.alertTimer <= 0 then
                state.alerted = false
            end
        end
        
        -- Check if ghost can see player
        local canSee = canGhostSeePlayer(playerCoord, ghost, ghosts, walls)
        
        if canSee then
            -- Increase detection progress
            state.detectionProgress = math.min(1, state.detectionProgress + dt / CONFIG.DETECTION_TIME)
            
            if state.detectionProgress >= 1 and not state.detected then
                -- Player fully detected!
                state.detected = true
                state.alerted = true
                state.alertTimer = CONFIG.ALERT_DURATION
                playerDetected = true
                totalAlertsTriggered = totalAlertsTriggered + 1
                
                -- Alert all nearby ghosts
                alertNearbyGhosts(ghost, ghosts, i)
                
                print("[Stealth] DETECTED! Ghost", i, "spotted player")
            end
        else
            -- Decrease detection progress when not visible
            state.detectionProgress = math.max(0, state.detectionProgress - dt / (CONFIG.DETECTION_TIME * 2))
            if state.detectionProgress == 0 then
                state.detected = false
            end
        end
    end
end

-- Check if a ghost can see the player (vision cone check)
function canGhostSeePlayer(playerCoord, ghostCoord, allGhosts, walls)
    local px, py = playerCoord[1], playerCoord[2]
    local gx, gy = ghostCoord[1], ghostCoord[2]
    
    -- Calculate distance
    local dx = px - gx
    local dy = py - gy
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if within range
    if distance > CONFIG.VISION_RANGE then
        return false
    end
    
    -- Calculate angle to player
    local angleToPlayer = math.atan2(dy, dx)
    
    -- Ghost facing direction (assuming ghosts face the direction they're moving)
    -- For simplicity, assume ghosts always face toward the player (worst case for stealth)
    -- In a full implementation, this would track ghost facing direction
    local ghostFacing = angleToPlayer
    
    -- Check if player is within vision cone
    local angleDiff = math.abs(normalizeAngle(angleToPlayer - ghostFacing))
    if angleDiff > CONFIG.VISION_CONE_ANGLE / 2 then
        return false
    end
    
    -- Check for wall obstruction (line of sight)
    if isLineObstructed(gx, gy, px, py, walls) then
        return false
    end
    
    return true
end

-- Alert all ghosts within radius
function alertNearbyGhosts(sourceGhost, allGhosts, sourceIndex)
    local sx, sy = sourceGhost[1], sourceGhost[2]
    
    for i, ghost in ipairs(allGhosts) do
        if i ~= sourceIndex then
            local gx, gy = ghost[1], ghost[2]
            local dx = gx - sx
            local dy = gy - sy
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= CONFIG.ALERT_RADIUS then
                if not detectionStates[i] then
                    detectionStates[i] = {
                        detected = false,
                        detectionProgress = 0,
                        alerted = false,
                        alertTimer = 0
                    }
                end
                
                detectionStates[i].alerted = true
                detectionStates[i].alertTimer = CONFIG.ALERT_DURATION
                print("[Stealth] Ghost", i, "alerted by ghost", sourceIndex)
            end
        end
    end
end

-- Check if line of sight is obstructed by walls
function isLineObstructed(x1, y1, x2, y2, walls)
    -- Simple raycast to check wall collision
    local steps = 20
    for i = 0, steps do
        local t = i / steps
        local x = x1 + (x2 - x1) * t
        local y = y1 + (y2 - y1) * t
        
        -- Check if this point is inside a wall
        for _, wall in ipairs(walls) do
            local wx, wy = wall[1], wall[2]
            local wallSize = 32  -- assume 32x32 wall tiles
            if x >= wx and x <= wx + wallSize and y >= wy and y <= wy + wallSize then
                return true
            end
        end
    end
    
    return false
end

-- Normalize angle to -pi to pi range
function normalizeAngle(angle)
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end
    return angle
end

-- Get detection state for a specific ghost
function Stealth.getDetectionState(ghostIndex)
    return detectionStates[ghostIndex]
end

-- Check if player is currently detected
function Stealth.isPlayerDetected()
    return playerDetected
end

-- Check if ghost is alerted
function Stealth.isGhostAlerted(ghostIndex)
    local state = detectionStates[ghostIndex]
    return state and state.alerted or false
end

-- Get detection progress (0 to 1) for UI display
function Stealth.getDetectionProgress(ghostIndex)
    local state = detectionStates[ghostIndex]
    return state and state.detectionProgress or 0
end

-- Draw vision cones (for debug/visualization)
function Stealth.drawVisionCones(ghosts)
    if not enabled then return end
    
    for i, ghost in ipairs(ghosts) do
        local gx, gy = ghost[1], ghost[2]
        local state = detectionStates[i]
        
        -- Draw vision cone
        love.graphics.push()
        love.graphics.translate(gx + 16, gy + 16)  -- center of ghost sprite (assuming 32x32)
        
        -- Color based on detection state
        if state and state.alerted then
            love.graphics.setColor(1, 0, 0, 0.2)  -- Red when alerted
        elseif state and state.detectionProgress > 0 then
            love.graphics.setColor(1, 1, 0, 0.2)  -- Yellow when detecting
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.1)  -- Gray when idle
        end
        
        -- Draw cone arc
        local segments = 20
        local vertices = {0, 0}
        for i = 0, segments do
            local angle = -CONFIG.VISION_CONE_ANGLE / 2 + (CONFIG.VISION_CONE_ANGLE * i / segments)
            local x = math.cos(angle) * CONFIG.VISION_RANGE
            local y = math.sin(angle) * CONFIG.VISION_RANGE
            table.insert(vertices, x)
            table.insert(vertices, y)
        end
        love.graphics.polygon("fill", vertices)
        
        love.graphics.pop()
    end
end

-- Draw detection UI (meters, alerts)
function Stealth.drawDetectionUI()
    if not enabled then return end
    
    -- Draw detection meter if player is being detected
    for i, state in pairs(detectionStates) do
        if state.detectionProgress > 0 then
            local meterWidth = 200
            local meterHeight = 20
            local x = (love.graphics.getWidth() - meterWidth) / 2
            local y = 50
            
            -- Background
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", x, y, meterWidth, meterHeight)
            
            -- Progress bar
            local color = {1, 1 - state.detectionProgress, 0}  -- Yellow to red
            love.graphics.setColor(color[1], color[2], color[3], 0.8)
            love.graphics.rectangle("fill", x, y, meterWidth * state.detectionProgress, meterHeight)
            
            -- Border
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", x, y, meterWidth, meterHeight)
            
            -- Text
            love.graphics.setColor(1, 1, 1, 1)
            local text = "DETECTION: " .. math.floor(state.detectionProgress * 100) .. "%"
            love.graphics.print(text, x + 10, y + 3)
        end
        
        if state.alerted then
            -- Alert indicator
            love.graphics.setColor(1, 0, 0, 0.8)
            local text = "! ALERT !"
            love.graphics.print(text, love.graphics.getWidth() / 2 - 30, 80)
        end
    end
    
    -- Total alerts counter
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Alerts: " .. totalAlertsTriggered, 10, love.graphics.getHeight() - 50)
end

return Stealth
