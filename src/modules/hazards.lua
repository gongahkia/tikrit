-- Hazards module for spike traps, pressure plates, and environmental dangers
local CONFIG = require("config")

local Hazards = {}

-- Hazard types
Hazards.spikes = {
    coords = {},     -- Spike trap positions {x, y}
    active = {},     -- Whether each spike is currently active
    timers = {}      -- Timers for each spike
}

Hazards.pressurePlates = {
    coords = {},     -- Pressure plate positions {x, y}
    triggered = {},  -- Whether each plate is triggered
    linkedDoors = {} -- Doors controlled by each plate
}

Hazards.timedRooms = {
    active = false,
    remainingTime = 0,
    initialTime = CONFIG.TIMED_ROOM_DURATION
}

Hazards.darkZones = {
    coords = {},     -- Dark zone positions {x, y, width, height}
    active = {}      -- Whether player is in dark zone
}

-- Initialize hazards for a new room
function Hazards.init()
    Hazards.spikes.coords = {}
    Hazards.spikes.active = {}
    Hazards.spikes.timers = {}
    
    Hazards.pressurePlates.coords = {}
    Hazards.pressurePlates.triggered = {}
    Hazards.pressurePlates.linkedDoors = {}
    
    Hazards.timedRooms.active = false
    Hazards.timedRooms.remainingTime = Hazards.timedRooms.initialTime
    
    Hazards.darkZones.coords = {}
    Hazards.darkZones.active = {}
end

-- Add a spike trap at coordinates
function Hazards.addSpike(x, y)
    if not CONFIG.HAZARDS_ENABLED then return end
    
    table.insert(Hazards.spikes.coords, {x, y})
    table.insert(Hazards.spikes.active, false)
    table.insert(Hazards.spikes.timers, 0)
end

-- Add a pressure plate at coordinates
function Hazards.addPressurePlate(x, y, linkedDoor)
    if not CONFIG.HAZARDS_ENABLED then return end
    
    table.insert(Hazards.pressurePlates.coords, {x, y})
    table.insert(Hazards.pressurePlates.triggered, false)
    table.insert(Hazards.pressurePlates.linkedDoors, linkedDoor or nil)
end

-- Add a dark zone
function Hazards.addDarkZone(x, y, width, height)
    if not CONFIG.HAZARDS_ENABLED then return end
    
    table.insert(Hazards.darkZones.coords, {x, y, width, height})
    table.insert(Hazards.darkZones.active, false)
end

-- Activate a timed room
function Hazards.activateTimedRoom(duration)
    if not CONFIG.HAZARDS_ENABLED then return end
    
    Hazards.timedRooms.active = true
    Hazards.timedRooms.remainingTime = duration or CONFIG.TIMED_ROOM_DURATION
    Hazards.timedRooms.initialTime = Hazards.timedRooms.remainingTime
end

-- Update hazards (called each frame)
function Hazards.update(dt, playerCoord)
    if not CONFIG.HAZARDS_ENABLED then return 0 end
    
    local damage = 0
    
    -- Update spike traps
    for i, coord in ipairs(Hazards.spikes.coords) do
        Hazards.spikes.timers[i] = Hazards.spikes.timers[i] + dt
        
        local cycleTime = CONFIG.SPIKE_ACTIVE_TIME + CONFIG.SPIKE_INACTIVE_TIME
        local timeInCycle = Hazards.spikes.timers[i] % cycleTime
        
        -- Spikes are active for first part of cycle
        Hazards.spikes.active[i] = (timeInCycle < CONFIG.SPIKE_ACTIVE_TIME)
        
        -- Check collision with active spikes
        if Hazards.spikes.active[i] then
            local dx = math.abs(playerCoord[1] - coord[1])
            local dy = math.abs(playerCoord[2] - coord[2])
            if dx < CONFIG.TILE_SIZE and dy < CONFIG.TILE_SIZE then
                -- Only damage once per spike activation cycle
                if timeInCycle < dt then
                    damage = damage + CONFIG.SPIKE_DAMAGE
                end
            end
        end
    end
    
    -- Update pressure plates
    for i, coord in ipairs(Hazards.pressurePlates.coords) do
        local dx = math.abs(playerCoord[1] - coord[1])
        local dy = math.abs(playerCoord[2] - coord[2])
        local wasTriggered = Hazards.pressurePlates.triggered[i]
        
        Hazards.pressurePlates.triggered[i] = (dx < CONFIG.PRESSURE_PLATE_RADIUS and dy < CONFIG.PRESSURE_PLATE_RADIUS)
        
        -- Trigger event when plate state changes
        if not wasTriggered and Hazards.pressurePlates.triggered[i] then
            -- Plate was just activated
            Hazards.onPressurePlateActivated(i)
        elseif wasTriggered and not Hazards.pressurePlates.triggered[i] then
            -- Plate was just deactivated
            Hazards.onPressurePlateDeactivated(i)
        end
    end
    
    -- Update timed rooms
    if Hazards.timedRooms.active then
        Hazards.timedRooms.remainingTime = Hazards.timedRooms.remainingTime - dt
        
        if Hazards.timedRooms.remainingTime <= 0 then
            -- Time's up! Return failure signal
            return -1
        end
    end
    
    -- Update dark zones
    for i, zone in ipairs(Hazards.darkZones.coords) do
        local x, y, width, height = zone[1], zone[2], zone[3], zone[4]
        Hazards.darkZones.active[i] = (
            playerCoord[1] >= x and playerCoord[1] <= x + width and
            playerCoord[2] >= y and playerCoord[2] <= y + height
        )
    end
    
    return damage
end

-- Callback when pressure plate is activated
function Hazards.onPressurePlateActivated(index)
    -- Override this function to handle plate activation
    -- For example, open doors, spawn enemies, etc.
end

-- Callback when pressure plate is deactivated
function Hazards.onPressurePlateDeactivated(index)
    -- Override this function to handle plate deactivation
end

-- Check if player is in a dark zone
function Hazards.isPlayerInDarkZone()
    if not CONFIG.HAZARDS_ENABLED then return false end
    
    for i, active in ipairs(Hazards.darkZones.active) do
        if active then return true end
    end
    return false
end

-- Get modified vision radius based on dark zones
function Hazards.getVisionRadius()
    if Hazards.isPlayerInDarkZone() then
        return CONFIG.VISION_RADIUS * CONFIG.DARK_ZONE_VISION_MULTIPLIER
    end
    return CONFIG.VISION_RADIUS
end

-- Draw hazards
function Hazards.draw(wallSprite)
    if not CONFIG.HAZARDS_ENABLED then return end
    
    -- Draw spike traps
    for i, coord in ipairs(Hazards.spikes.coords) do
        if Hazards.spikes.active[i] then
            -- Active spikes - red tint
            love.graphics.setColor(1, 0.2, 0.2, 1)
        else
            -- Inactive spikes - gray
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        end
        
        -- Draw spike using wall sprite (or a modified version)
        love.graphics.draw(wallSprite, coord[1], coord[2])
    end
    
    -- Draw pressure plates
    for i, coord in ipairs(Hazards.pressurePlates.coords) do
        if Hazards.pressurePlates.triggered[i] then
            -- Triggered - green
            love.graphics.setColor(0.2, 1, 0.2, 1)
        else
            -- Not triggered - yellow
            love.graphics.setColor(1, 1, 0.2, 1)
        end
        
        -- Draw as filled circle
        love.graphics.circle("fill", coord[1] + CONFIG.TILE_SIZE / 2, coord[2] + CONFIG.TILE_SIZE / 2, CONFIG.TILE_SIZE / 3)
    end
    
    -- Draw dark zone overlays
    for i, zone in ipairs(Hazards.darkZones.coords) do
        if Hazards.darkZones.active[i] then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", zone[1], zone[2], zone[3], zone[4])
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw timed room warning
function Hazards.drawTimedRoomUI()
    if not CONFIG.HAZARDS_ENABLED or not Hazards.timedRooms.active then return end
    
    local remaining = math.ceil(Hazards.timedRooms.remainingTime)
    local warning = remaining <= CONFIG.TIMED_ROOM_WARNING_TIME
    
    -- Draw timer at top center
    local text = "Time: " .. remaining .. "s"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    
    if warning then
        -- Flashing red when warning
        local flash = math.sin(love.timer.getTime() * 10) * 0.5 + 0.5
        love.graphics.setColor(1, flash * 0.5, flash * 0.5, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    love.graphics.print(text, CONFIG.WINDOW_WIDTH / 2 - textWidth / 2, 10)
    
    -- Draw progress bar
    local barWidth = 200
    local barHeight = 10
    local barX = CONFIG.WINDOW_WIDTH / 2 - barWidth / 2
    local barY = 35
    
    -- Background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Progress
    local progress = Hazards.timedRooms.remainingTime / Hazards.timedRooms.initialTime
    if warning then
        love.graphics.setColor(1, 0, 0, 0.8)
    else
        love.graphics.setColor(0, 1, 0, 0.8)
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Hazards
