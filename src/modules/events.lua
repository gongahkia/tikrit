-- Event system for decoupled communication (Observer pattern)
local Events = {}

-- Event listeners registry
Events.listeners = {}

-- Subscribe to an event
function Events.on(eventName, callback)
    if not Events.listeners[eventName] then
        Events.listeners[eventName] = {}
    end
    table.insert(Events.listeners[eventName], callback)
end

-- Unsubscribe from an event
function Events.off(eventName, callback)
    if not Events.listeners[eventName] then
        return
    end
    
    for i, listener in ipairs(Events.listeners[eventName]) do
        if listener == callback then
            table.remove(Events.listeners[eventName], i)
            return
        end
    end
end

-- Trigger an event
function Events.trigger(eventName, ...)
    if not Events.listeners[eventName] then
        return
    end
    
    for _, callback in ipairs(Events.listeners[eventName]) do
        callback(...)
    end
end

-- Clear all listeners (useful for cleanup)
function Events.clear()
    Events.listeners = {}
end

-- Clear listeners for a specific event
function Events.clearEvent(eventName)
    Events.listeners[eventName] = nil
end

-- Get listener count for debugging
function Events.getListenerCount(eventName)
    if not Events.listeners[eventName] then
        return 0
    end
    return #Events.listeners[eventName]
end

-- Common game events (for reference/documentation)
Events.GAME_EVENTS = {
    -- Player events
    PLAYER_MOVE = "player:move",
    PLAYER_DEATH = "player:death",
    PLAYER_SPAWN = "player:spawn",
    
    -- Item events
    ITEM_COLLECTED = "item:collected",
    ITEM_USED = "item:used",
    
    -- Key events
    KEY_COLLECTED = "key:collected",
    
    -- Monster events
    MONSTER_KILLED = "monster:killed",
    MONSTER_SPAWN = "monster:spawn",
    
    -- Room events
    ROOM_ENTERED = "room:entered",
    ROOM_CLEARED = "room:cleared",
    
    -- Door events
    DOOR_OPENED = "door:opened",
    DOOR_CLOSED = "door:closed",
    
    -- Game state events
    GAME_START = "game:start",
    GAME_PAUSE = "game:pause",
    GAME_RESUME = "game:resume",
    GAME_WIN = "game:win",
    GAME_LOSE = "game:lose",
    
    -- Combat events
    ATTACK_PERFORMED = "combat:attack",
    DAMAGE_TAKEN = "combat:damage",
    
    -- Hazard events
    SPIKE_TRIGGERED = "hazard:spike",
    PLATE_ACTIVATED = "hazard:plate",
    TIMER_WARNING = "hazard:timer_warning",
    
    -- Effect events
    EFFECT_APPLIED = "effect:applied",
    EFFECT_EXPIRED = "effect:expired",
}

return Events
