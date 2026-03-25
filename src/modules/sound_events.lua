local CONFIG = require("config")

local SoundEvents = {}

local WEATHER_LOOP_BASE_VOLUME = 0.16

local DEFINITIONS = {
    ambient = {path = "sound/ambient-background.mp3", kind = "stream", loop = true, group = "music", baseVolume = CONFIG.AMBIENT_BASE_VOLUME},
    walking = {path = "sound/player-walking.mp3", kind = "static", loop = true, group = "sfx"},
    item_pickup = {path = "sound/player-collect-item.mp3", kind = "static", group = "sfx"},
    player_death = {path = "sound/player-death.mp3", kind = "static", group = "sfx"},
    door_open = {path = "sound/door-open.mp3", kind = "static", group = "sfx"},
    bow_ready = {path = "sound/bow-ready.mp3", kind = "static", group = "sfx"},
    bow_fire = {path = "sound/bow-fire.mp3", kind = "static", group = "sfx"},
    arrow_hit = {path = "sound/arrow-hit.mp3", kind = "static", group = "sfx"},
    snare_set = {path = "sound/snare-set.mp3", kind = "static", group = "sfx"},
    snare_catch = {path = "sound/snare-catch.mp3", kind = "static", group = "sfx"},
    fish_catch = {path = "sound/fish-catch.mp3", kind = "static", group = "sfx"},
    harvest = {path = "sound/harvest.mp3", kind = "static", group = "sfx"},
    rope_climb = {path = "sound/rope-climb.mp3", kind = "static", group = "sfx"},
    map_reveal = {path = "sound/map-reveal.mp3", kind = "static", group = "sfx"},
    craft = {path = "sound/craft.mp3", kind = "static", group = "sfx"},
    treat = {path = "sound/treat.mp3", kind = "static", group = "sfx"},
    poi_discovery = {path = "sound/poi-discovery.mp3", kind = "static", group = "sfx"},
    weather_wind_loop = {path = "sound/weather-wind-loop.mp3", kind = "stream", loop = true, group = "weather", baseVolume = WEATHER_LOOP_BASE_VOLUME},
    weather_blizzard_loop = {path = "sound/weather-blizzard-loop.mp3", kind = "stream", loop = true, group = "weather", baseVolume = WEATHER_LOOP_BASE_VOLUME},
}

local state = {
    sources = {},
    eventLog = {},
    activeWeatherEvent = nil,
}

local function safeNewSource(path, kind)
    if not love or not love.audio or not love.audio.newSource then
        return nil
    end
    local ok, source = pcall(love.audio.newSource, path, kind)
    if ok then
        return source
    end
    return nil
end

local function logEvent(eventId)
    table.insert(state.eventLog, eventId)
    if #state.eventLog > 64 then
        table.remove(state.eventLog, 1)
    end
end

local function eventVolume(settings, definition)
    local master = ((settings or {}).audio or {}).master or 1
    local music = ((settings or {}).audio or {}).music or 1
    local sfx = ((settings or {}).audio or {}).sfx or 1
    local base = definition.baseVolume or 1

    if definition.group == "music" then
        return master * music * base
    elseif definition.group == "weather" then
        return master * music * base
    end
    return master * sfx * base
end

function SoundEvents.init()
    state.sources = {}
    state.eventLog = {}
    state.activeWeatherEvent = nil
end

function SoundEvents.load()
    state.sources = {}
    for eventId, definition in pairs(DEFINITIONS) do
        local source = safeNewSource(definition.path, definition.kind)
        if source and definition.loop and source.setLooping then
            source:setLooping(true)
        end
        state.sources[eventId] = source
    end
end

function SoundEvents.applySettings(settings)
    for eventId, source in pairs(state.sources) do
        local definition = DEFINITIONS[eventId]
        if source and source.setVolume and definition then
            source:setVolume(eventVolume(settings, definition))
        end
    end
end

function SoundEvents.play(eventId)
    logEvent(eventId)
    local source = state.sources[eventId]
    local definition = DEFINITIONS[eventId]
    if not source or not definition or not love or not love.audio then
        return false
    end

    if definition.loop then
        if not source.isPlaying or not source:isPlaying() then
            love.audio.play(source)
        end
        return true
    end

    if love.audio.stop then
        love.audio.stop(source)
    end
    love.audio.play(source)
    return true
end

function SoundEvents.stop(eventId)
    local source = state.sources[eventId]
    if source and love and love.audio and love.audio.stop then
        love.audio.stop(source)
    end
end

function SoundEvents.isPlaying(eventId)
    local source = state.sources[eventId]
    if source and source.isPlaying then
        return source:isPlaying()
    end
    return false
end

function SoundEvents.updateWeather(weatherState)
    local targetEvent
    if weatherState == "wind" then
        targetEvent = "weather_wind_loop"
    elseif weatherState == "blizzard" then
        targetEvent = "weather_blizzard_loop"
    end

    if state.activeWeatherEvent == targetEvent then
        return
    end

    if state.activeWeatherEvent then
        SoundEvents.stop(state.activeWeatherEvent)
    end

    state.activeWeatherEvent = targetEvent
    if targetEvent then
        SoundEvents.play(targetEvent)
    end
end

function SoundEvents.getEventLog()
    local copy = {}
    for index, eventId in ipairs(state.eventLog) do
        copy[index] = eventId
    end
    return copy
end

function SoundEvents.clearEventLog()
    state.eventLog = {}
end

function SoundEvents.getDefinitions()
    return DEFINITIONS
end

return SoundEvents
