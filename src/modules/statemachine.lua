-- State machine base class and implementations
local CONFIG = require("config")

local State = {}
State.__index = State

-- Base State class
function State:new()
    local instance = setmetatable({}, self)
    return instance
end

function State:enter()
    -- Override in subclasses
end

function State:exit()
    -- Override in subclasses
end

function State:update(dt)
    -- Override in subclasses
end

function State:draw()
    -- Override in subclasses
end

function State:keypressed(key)
    -- Override in subclasses
end

function State:keyreleased(key)
    -- Override in subclasses
end

-- State Machine manager
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new()
    local instance = {
        states = {},
        currentState = nil,
        stateStack = {}  -- For state stacking (e.g., pause on top of game)
    }
    setmetatable(instance, self)
    return instance
end

function StateMachine:add(name, state)
    self.states[name] = state
end

function StateMachine:change(name, ...)
    if self.currentState then
        self.currentState:exit()
    end
    
    self.currentState = self.states[name]
    if not self.currentState then
        error("State '" .. name .. "' not found")
    end
    
    self.currentState:enter(...)
end

function StateMachine:push(name, ...)
    -- Push current state onto stack
    if self.currentState then
        table.insert(self.stateStack, self.currentState)
    end
    
    self.currentState = self.states[name]
    if not self.currentState then
        error("State '" .. name .. "' not found")
    end
    
    self.currentState:enter(...)
end

function StateMachine:pop()
    if self.currentState then
        self.currentState:exit()
    end
    
    -- Pop previous state from stack
    if #self.stateStack > 0 then
        self.currentState = table.remove(self.stateStack)
        if self.currentState then
            self.currentState:enter()  -- Re-enter previous state
        end
    else
        self.currentState = nil
    end
end

function StateMachine:update(dt)
    if self.currentState then
        self.currentState:update(dt)
    end
end

function StateMachine:draw()
    -- Draw stacked states (for pause overlay)
    for i, state in ipairs(self.stateStack) do
        state:draw()
    end
    
    if self.currentState then
        self.currentState:draw()
    end
end

function StateMachine:keypressed(key)
    if self.currentState then
        self.currentState:keypressed(key)
    end
end

function StateMachine:keyreleased(key)
    if self.currentState then
        self.currentState:keyreleased(key)
    end
end

return {
    State = State,
    StateMachine = StateMachine
}
