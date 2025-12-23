-- Accessibility module for colorblind modes and other accessibility features
local CONFIG = require("config")

local Accessibility = {}

-- Colorblind filter matrices (from scientific research)
-- Source: https://www.color-blindness.com/coblis-color-blindness-simulator/

-- Apply colorblind filter to color values
function Accessibility.applyColorblindFilter(r, g, b, a)
    if not CONFIG.ACCESSIBILITY_ENABLED or CONFIG.COLORBLIND_MODE == "none" then
        return r, g, b, a
    end
    
    local nr, ng, nb
    
    if CONFIG.COLORBLIND_MODE == "protanopia" then
        -- Red-blind (missing L cones)
        nr = 0.56667 * r + 0.43333 * g + 0.00000 * b
        ng = 0.55833 * r + 0.44167 * g + 0.00000 * b
        nb = 0.00000 * r + 0.24167 * g + 0.75833 * b
    elseif CONFIG.COLORBLIND_MODE == "deuteranopia" then
        -- Green-blind (missing M cones)
        nr = 0.625 * r + 0.375 * g + 0.0 * b
        ng = 0.7 * r + 0.3 * g + 0.0 * b
        nb = 0.0 * r + 0.3 * g + 0.7 * b
    elseif CONFIG.COLORBLIND_MODE == "tritanopia" then
        -- Blue-blind (missing S cones)
        nr = 0.95 * r + 0.05 * g + 0.0 * b
        ng = 0.0 * r + 0.43333 * g + 0.56667 * b
        nb = 0.0 * r + 0.475 * g + 0.525 * b
    else
        return r, g, b, a
    end
    
    return nr, ng, nb, a
end

-- Apply high contrast mode
function Accessibility.applyHighContrast(r, g, b, a)
    if not CONFIG.HIGH_CONTRAST_MODE then
        return r, g, b, a
    end
    
    -- Increase contrast by pushing values toward extremes
    local threshold = 0.5
    local nr = r > threshold and math.min(1, r * 1.3) or math.max(0, r * 0.7)
    local ng = g > threshold and math.min(1, g * 1.3) or math.max(0, g * 0.7)
    local nb = b > threshold and math.min(1, b * 1.3) or math.max(0, b * 0.7)
    
    return nr, ng, nb, a
end

-- Apply all accessibility filters
function Accessibility.applyFilters(r, g, b, a)
    local nr, ng, nb, na = Accessibility.applyColorblindFilter(r, g, b, a)
    nr, ng, nb, na = Accessibility.applyHighContrast(nr, ng, nb, na)
    return nr, ng, nb, na
end

-- Get adjusted speed based on slow mode
function Accessibility.getAdjustedSpeed(baseSpeed)
    if CONFIG.SLOW_MODE then
        return baseSpeed * CONFIG.SLOW_MODE_MULTIPLIER
    end
    return baseSpeed
end

-- Draw visual audio indicator (for ghost proximity)
function Accessibility.drawAudioIndicator(playerCoord, monstersCoord)
    if not CONFIG.VISUAL_AUDIO_INDICATORS then
        return
    end
    
    -- Find closest ghost
    local closestDist = math.huge
    for _, monsterCoord in ipairs(monstersCoord) do
        local dx = monsterCoord[1] - playerCoord[1]
        local dy = monsterCoord[2] - playerCoord[2]
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < closestDist then
            closestDist = dist
        end
    end
    
    -- Draw indicator based on proximity
    if closestDist < CONFIG.GHOST_PROXIMITY_THRESHOLD then
        local intensity = 1 - (closestDist / CONFIG.GHOST_PROXIMITY_THRESHOLD)
        love.graphics.setColor(1, 0, 0, intensity * 0.5)
        
        -- Draw border flash
        local thickness = 5
        love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, thickness)  -- Top
        love.graphics.rectangle("fill", 0, CONFIG.WINDOW_HEIGHT - thickness, CONFIG.WINDOW_WIDTH, thickness)  -- Bottom
        love.graphics.rectangle("fill", 0, 0, thickness, CONFIG.WINDOW_HEIGHT)  -- Left
        love.graphics.rectangle("fill", CONFIG.WINDOW_WIDTH - thickness, 0, thickness, CONFIG.WINDOW_HEIGHT)  -- Right
        
        -- Draw danger text
        love.graphics.setColor(1, 0, 0, intensity)
        love.graphics.print("!", CONFIG.WINDOW_WIDTH / 2 - 10, 50)
    end
end

-- Get adjusted font size
function Accessibility.getAdjustedFontSize(baseSize)
    return math.floor(baseSize * CONFIG.FONT_SIZE_MULTIPLIER)
end

-- Toggle colorblind mode (cycle through modes)
function Accessibility.cycleColorblindMode()
    local modes = {"none", "protanopia", "deuteranopia", "tritanopia"}
    local currentIndex = 1
    
    for i, mode in ipairs(modes) do
        if mode == CONFIG.COLORBLIND_MODE then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #modes) + 1
    CONFIG.COLORBLIND_MODE = modes[nextIndex]
    
    return CONFIG.COLORBLIND_MODE
end

return Accessibility
