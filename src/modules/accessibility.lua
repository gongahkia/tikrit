local CONFIG = require("config")
local Utils = require("modules/utils")

local Accessibility = {}

function Accessibility.applyColorblindFilter(settings, r, g, b, a)
    local mode = settings.accessibility.colorblindMode
    if mode == "none" then
        return r, g, b, a
    end

    local nr, ng, nb
    if mode == "protanopia" then
        nr = 0.56667 * r + 0.43333 * g
        ng = 0.55833 * r + 0.44167 * g
        nb = 0.24167 * g + 0.75833 * b
    elseif mode == "deuteranopia" then
        nr = 0.625 * r + 0.375 * g
        ng = 0.7 * r + 0.3 * g
        nb = 0.3 * g + 0.7 * b
    elseif mode == "tritanopia" then
        nr = 0.95 * r + 0.05 * g
        ng = 0.43333 * g + 0.56667 * b
        nb = 0.475 * g + 0.525 * b
    else
        return r, g, b, a
    end

    return nr, ng, nb, a
end

function Accessibility.applyHighContrast(settings, r, g, b, a)
    if not settings.accessibility.highContrast then
        return r, g, b, a
    end

    local threshold = 0.5
    local nr = r > threshold and math.min(1, r * 1.25) or math.max(0, r * 0.65)
    local ng = g > threshold and math.min(1, g * 1.25) or math.max(0, g * 0.65)
    local nb = b > threshold and math.min(1, b * 1.25) or math.max(0, b * 0.65)
    return nr, ng, nb, a
end

function Accessibility.applyFilters(settings, r, g, b, a)
    local nr, ng, nb, na = Accessibility.applyColorblindFilter(settings, r, g, b, a)
    return Accessibility.applyHighContrast(settings, nr, ng, nb, na)
end

function Accessibility.setColor(settings, r, g, b, a)
    love.graphics.setColor(Accessibility.applyFilters(settings, r, g, b, a or 1))
end

function Accessibility.getAdjustedSpeed(settings, baseSpeed)
    if settings.accessibility.slowMode then
        return baseSpeed * 0.5
    end
    return baseSpeed
end

function Accessibility.getAdjustedFontSize(settings, baseSize)
    return math.floor(baseSize * settings.accessibility.fontScale)
end

function Accessibility.drawAudioIndicator(settings, playerCoord, monsters)
    if not settings.accessibility.visualAudioIndicators then
        return
    end

    local closestDistance = math.huge
    for _, monster in ipairs(monsters) do
        local distance = Utils.distance(playerCoord[1], playerCoord[2], monster.coord[1], monster.coord[2])
        if distance < closestDistance then
            closestDistance = distance
        end
    end

    if closestDistance < CONFIG.GHOST_AUDIO_MAX_DISTANCE then
        local intensity = 1 - (closestDistance / CONFIG.GHOST_AUDIO_MAX_DISTANCE)
        Accessibility.setColor(settings, 1, 0.15, 0.15, intensity * 0.45)
        local thickness = 6
        love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, thickness)
        love.graphics.rectangle("fill", 0, CONFIG.WINDOW_HEIGHT - thickness, CONFIG.WINDOW_WIDTH, thickness)
        love.graphics.rectangle("fill", 0, 0, thickness, CONFIG.WINDOW_HEIGHT)
        love.graphics.rectangle("fill", CONFIG.WINDOW_WIDTH - thickness, 0, thickness, CONFIG.WINDOW_HEIGHT)
    end
end

return Accessibility
