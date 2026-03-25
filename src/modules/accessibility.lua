local CONFIG = require("config")

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

function Accessibility.drawVisualAlerts(settings, alerts, pulseTime)
    if not settings.accessibility.visualAlerts then
        return
    end

    local pulse = 0.55 + (((math.sin((pulseTime or 0) * 6) + 1) * 0.5) * 0.45)
    local layers = {
        {key = "blizzard", color = {0.76, 0.9, 1.0}, thickness = 5},
        {key = "fireRisk", color = {1.0, 0.58, 0.12}, thickness = 7},
        {key = "weakIce", color = {0.32, 0.66, 0.96}, thickness = 8},
        {key = "wolfThreat", color = {0.98, 0.2, 0.18}, thickness = 6},
    }

    for _, layer in ipairs(layers) do
        local intensity = alerts and alerts[layer.key] or 0
        if intensity and intensity > 0 then
            local alpha = math.min(0.75, intensity * pulse)
            Accessibility.setColor(settings, layer.color[1], layer.color[2], layer.color[3], alpha)
            love.graphics.rectangle("fill", 0, 0, CONFIG.WINDOW_WIDTH, layer.thickness)
            love.graphics.rectangle("fill", 0, CONFIG.WINDOW_HEIGHT - layer.thickness, CONFIG.WINDOW_WIDTH, layer.thickness)
            love.graphics.rectangle("fill", 0, 0, layer.thickness, CONFIG.WINDOW_HEIGHT)
            love.graphics.rectangle("fill", CONFIG.WINDOW_WIDTH - layer.thickness, 0, layer.thickness, CONFIG.WINDOW_HEIGHT)
        end
    end
end

return Accessibility
