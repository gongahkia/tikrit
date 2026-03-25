local CONFIG = require("config")
local Accessibility = require("modules/accessibility")

local Effects = {}

Effects.screenShake = {
    active = false,
    duration = 0,
    intensity = 0,
    offsetX = 0,
    offsetY = 0,
}

Effects.pulses = {}
Effects.elapsed = 0

function Effects.init()
    Effects.screenShake = {
        active = false,
        duration = 0,
        intensity = 0,
        offsetX = 0,
        offsetY = 0,
    }
    Effects.pulses = {}
    Effects.elapsed = 0
end

function Effects.startScreenShake(enabled, intensity, duration)
    if not enabled then
        return
    end
    Effects.screenShake.active = true
    Effects.screenShake.intensity = intensity or CONFIG.SCREEN_SHAKE_INTENSITY
    Effects.screenShake.duration = duration or CONFIG.SCREEN_SHAKE_DURATION
end

function Effects.updateScreenShake(dt)
    if not Effects.screenShake.active then
        return
    end
    Effects.screenShake.duration = Effects.screenShake.duration - dt
    if Effects.screenShake.duration <= 0 then
        Effects.screenShake.active = false
        Effects.screenShake.offsetX = 0
        Effects.screenShake.offsetY = 0
        return
    end
    Effects.screenShake.offsetX = (math.random() * 2 - 1) * Effects.screenShake.intensity
    Effects.screenShake.offsetY = (math.random() * 2 - 1) * Effects.screenShake.intensity
end

function Effects.addPulse(kind, coord, duration)
    if not coord then
        return
    end
    table.insert(Effects.pulses, {
        kind = kind or "impact",
        coord = {coord[1], coord[2]},
        duration = duration or 0.6,
        totalDuration = duration or 0.6,
    })
end

function Effects.update(dt)
    Effects.elapsed = Effects.elapsed + dt
    Effects.updateScreenShake(dt)

    for index = #Effects.pulses, 1, -1 do
        local pulse = Effects.pulses[index]
        pulse.duration = pulse.duration - dt
        if pulse.duration <= 0 then
            table.remove(Effects.pulses, index)
        end
    end
end

local function drawWeather(settings, run)
    if not run or not love.graphics.line then
        return
    end

    local weather = run.world.weather.current
    if weather == "clear" then
        return
    end

    local lines = weather == "blizzard" and 20 or (weather == "wind" and 10 or 12)
    local color = weather == "blizzard" and {0.86, 0.94, 1.0, 0.42}
        or weather == "wind" and {0.82, 0.9, 0.98, 0.24}
        or {0.88, 0.94, 1.0, 0.28}

    Accessibility.setColor(settings, color[1], color[2], color[3], color[4])
    for index = 1, lines do
        local x = (index * 43 + math.floor(Effects.elapsed * 110) * 7) % CONFIG.WINDOW_WIDTH
        local y = (index * 27 + math.floor(Effects.elapsed * 70) * 11) % CONFIG.WINDOW_HEIGHT
        local length = weather == "blizzard" and 12 or 8
        love.graphics.line(x, y, x - length, y + length)
    end
end

local function drawColdBreath(settings, run)
    if not run or run.player.warmth > 35 then
        return
    end

    local alpha = 0.18 + (((math.sin(Effects.elapsed * 4) + 1) * 0.5) * 0.18)
    Accessibility.setColor(settings, 0.92, 0.96, 1.0, alpha)
    love.graphics.circle("fill", run.player.coord[1] + 15, run.player.coord[2] + 6, 4)
    love.graphics.circle("fill", run.player.coord[1] + 19, run.player.coord[2] + 5, 3)
end

local function drawFireSparks(settings, run)
    for _, fire in ipairs(run.world.fires or {}) do
        if fire.remainingBurnHours > 0 then
            local phase = Effects.elapsed * 7
            Accessibility.setColor(settings, 1.0, 0.78, 0.2, 0.45)
            love.graphics.circle("fill", fire.coord[1] + 8 + math.sin(phase) * 2, fire.coord[2] + 3, 1.5)
            love.graphics.circle("fill", fire.coord[1] + 12 + math.cos(phase) * 2, fire.coord[2] + 1, 1.2)
        end
    end
end

local function drawPulse(settings, pulse)
    local progress = 1 - (pulse.duration / math.max(0.01, pulse.totalDuration))
    local radius = 6 + (progress * 18)

    if pulse.kind == "mapping" then
        Accessibility.setColor(settings, 0.96, 0.88, 0.46, 0.45 * (1 - progress))
        love.graphics.circle("line", pulse.coord[1] + 10, pulse.coord[2] + 10, radius)
    elseif pulse.kind == "fishing" then
        Accessibility.setColor(settings, 0.3, 0.66, 0.96, 0.45 * (1 - progress))
        love.graphics.circle("line", pulse.coord[1] + 10, pulse.coord[2] + 10, radius * 0.8)
    elseif pulse.kind == "climb" then
        Accessibility.setColor(settings, 0.74, 0.6, 0.36, 0.5 * (1 - progress))
        love.graphics.rectangle("line", pulse.coord[1] + 3, pulse.coord[2] + 3, 14, 14)
    else
        Accessibility.setColor(settings, 0.98, 0.22, 0.18, 0.42 * (1 - progress))
        love.graphics.circle("fill", pulse.coord[1] + 10, pulse.coord[2] + 10, radius * 0.45)
    end
end

function Effects.drawWorldOverlay(settings, run)
    if not run then
        return
    end

    drawWeather(settings, run)
    drawFireSparks(settings, run)
    drawColdBreath(settings, run)

    for _, pulse in ipairs(Effects.pulses) do
        drawPulse(settings, pulse)
    end
end

return Effects
