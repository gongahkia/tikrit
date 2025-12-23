-- src/modules/editor.lua
-- In-game level editor for rapid level design iteration

local Editor = {}

-- Editor state
local state = {
  active = false,
  gridSize = 40,
  currentTool = "#",  -- Default to wall
  mouseGridX = 0,
  mouseGridY = 0,
  camera = {x = 0, y = 0},
  map = {},
  mapWidth = 30,
  mapHeight = 20,
  filename = "custom.txt",
  showGrid = true,
  showHelp = false,
  clipboard = nil,
  history = {},
  historyIndex = 0,
  maxHistory = 50
}

-- Available tools
Editor.TOOLS = {
  ["#"] = {name = "Wall", color = {0.5, 0.5, 0.5}},
  ["."] = {name = "Floor", color = {0.2, 0.2, 0.2}},
  [" "] = {name = "Empty", color = {0.1, 0.1, 0.1}},
  ["@"] = {name = "Player Start", color = {0.2, 0.8, 0.2}},
  ["E"] = {name = "Exit", color = {0.8, 0.2, 0.2}},
  ["k"] = {name = "Key", color = {1, 0.84, 0}},
  ["G"] = {name = "Ghost", color = {0.7, 0.3, 0.7}},
  ["H"] = {name = "Health Potion", color = {1, 0.3, 0.3}},
  ["S"] = {name = "Speed Boost", color = {0.3, 0.8, 1}},
  ["I"] = {name = "Invincibility", color = {1, 1, 0.3}},
  ["M"] = {name = "Map Reveal", color = {0.5, 0.5, 1}},
  ["W"] = {name = "Weapon", color = {0.8, 0.6, 0.2}},
  ["^"] = {name = "Spike Trap", color = {0.9, 0.1, 0.1}},
  ["P"] = {name = "Pressure Plate", color = {0.6, 0.4, 0.2}},
  ["T"] = {name = "Timed Room", color = {1, 0.5, 0}},
  ["D"] = {name = "Dark Zone", color = {0.1, 0.1, 0.3}}
}

-- Tool order for cycling
Editor.TOOL_ORDER = {"#", ".", " ", "@", "E", "k", "G", "H", "S", "I", "M", "W", "^", "P", "T", "D"}

-- Initialize editor
function Editor.init()
  Editor.createEmptyMap()
  state.history = {}
  state.historyIndex = 0
end

-- Create empty map
function Editor.createEmptyMap()
  state.map = {}
  for y = 0, state.mapHeight - 1 do
    state.map[y] = {}
    for x = 0, state.mapWidth - 1 do
      -- Border walls
      if y == 0 or y == state.mapHeight - 1 or x == 0 or x == state.mapWidth - 1 then
        state.map[y][x] = "#"
      else
        state.map[y][x] = " "
      end
    end
  end
  Editor.saveToHistory()
end

-- Toggle editor
function Editor.toggle()
  state.active = not state.active
  if state.active then
    -- Entering editor
    state.showHelp = true
  end
end

-- Check if editor is active
function Editor.isActive()
  return state.active
end

-- Save current state to history
function Editor.saveToHistory()
  -- Remove any states after current index
  while #state.history > state.historyIndex do
    table.remove(state.history)
  end
  
  -- Deep copy current map
  local mapCopy = {}
  for y, row in pairs(state.map) do
    mapCopy[y] = {}
    for x, tile in pairs(row) do
      mapCopy[y][x] = tile
    end
  end
  
  table.insert(state.history, mapCopy)
  state.historyIndex = #state.history
  
  -- Limit history size
  while #state.history > state.maxHistory do
    table.remove(state.history, 1)
    state.historyIndex = state.historyIndex - 1
  end
end

-- Undo
function Editor.undo()
  if state.historyIndex > 1 then
    state.historyIndex = state.historyIndex - 1
    state.map = {}
    for y, row in pairs(state.history[state.historyIndex]) do
      state.map[y] = {}
      for x, tile in pairs(row) do
        state.map[y][x] = tile
      end
    end
  end
end

-- Redo
function Editor.redo()
  if state.historyIndex < #state.history then
    state.historyIndex = state.historyIndex + 1
    state.map = {}
    for y, row in pairs(state.history[state.historyIndex]) do
      state.map[y] = {}
      for x, tile in pairs(row) do
        state.map[y][x] = tile
      end
    end
  end
end

-- Update editor
function Editor.update(dt)
  if not state.active then return end
  
  -- Get mouse position
  local mouseX, mouseY = love.mouse.getPosition()
  state.mouseGridX = math.floor((mouseX - state.camera.x) / state.gridSize)
  state.mouseGridY = math.floor((mouseY - state.camera.y) / state.gridSize)
  
  -- Handle mouse painting
  if love.mouse.isDown(1) then  -- Left click
    Editor.placeTile(state.mouseGridX, state.mouseGridY, state.currentTool)
  elseif love.mouse.isDown(2) then  -- Right click (erase)
    Editor.placeTile(state.mouseGridX, state.mouseGridY, " ")
  end
  
  -- Camera movement with WASD
  local moveSpeed = 300 * dt
  if love.keyboard.isDown("a") then
    state.camera.x = state.camera.x + moveSpeed
  end
  if love.keyboard.isDown("d") then
    state.camera.x = state.camera.x - moveSpeed
  end
  if love.keyboard.isDown("w") then
    state.camera.y = state.camera.y + moveSpeed
  end
  if love.keyboard.isDown("s") then
    state.camera.y = state.camera.y - moveSpeed
  end
end

-- Place tile
function Editor.placeTile(x, y, tool)
  if state.map[y] and state.map[y][x] then
    if state.map[y][x] ~= tool then
      state.map[y][x] = tool
      -- Don't save to history on every tile (too spammy)
      -- History saved on mouse release
    end
  end
end

-- Handle key presses
function Editor.keypressed(key)
  if not state.active then return end
  
  -- Toggle help
  if key == "h" then
    state.showHelp = not state.showHelp
  end
  
  -- Toggle grid
  if key == "g" then
    state.showGrid = not state.showGrid
  end
  
  -- Cycle tools
  if key == "tab" then
    local currentIndex = 1
    for i, tool in ipairs(Editor.TOOL_ORDER) do
      if tool == state.currentTool then
        currentIndex = i
        break
      end
    end
    
    currentIndex = currentIndex + 1
    if currentIndex > #Editor.TOOL_ORDER then
      currentIndex = 1
    end
    state.currentTool = Editor.TOOL_ORDER[currentIndex]
  end
  
  -- Number keys for quick tool selection
  local toolKeys = {
    ["1"] = "#",
    ["2"] = ".",
    ["3"] = "@",
    ["4"] = "E",
    ["5"] = "k",
    ["6"] = "G",
    ["7"] = "H",
    ["8"] = "^",
    ["9"] = "P"
  }
  
  if toolKeys[key] then
    state.currentTool = toolKeys[key]
  end
  
  -- Save map
  if key == "f2" then
    Editor.saveMap()
  end
  
  -- Load map
  if key == "f3" then
    Editor.loadMap()
  end
  
  -- New map
  if key == "f4" then
    Editor.createEmptyMap()
  end
  
  -- Undo/Redo
  if key == "z" and love.keyboard.isDown("lctrl", "rctrl") then
    Editor.undo()
  end
  if key == "y" and love.keyboard.isDown("lctrl", "rctrl") then
    Editor.redo()
  end
  
  -- Fill tool
  if key == "f" then
    Editor.floodFill(state.mouseGridX, state.mouseGridY, state.currentTool)
  end
  
  -- Exit editor
  if key == "escape" or key == "f5" then
    state.active = false
  end
end

-- Handle mouse release
function Editor.mousereleased(x, y, button)
  if not state.active then return end
  
  if button == 1 or button == 2 then
    Editor.saveToHistory()
  end
end

-- Flood fill algorithm
function Editor.floodFill(startX, startY, newTool)
  if not state.map[startY] or not state.map[startY][startX] then return end
  
  local oldTool = state.map[startY][startX]
  if oldTool == newTool then return end
  
  local stack = {{x = startX, y = startY}}
  local visited = {}
  
  while #stack > 0 do
    local pos = table.remove(stack)
    local key = pos.y .. "," .. pos.x
    
    if not visited[key] and state.map[pos.y] and state.map[pos.y][pos.x] == oldTool then
      visited[key] = true
      state.map[pos.y][pos.x] = newTool
      
      table.insert(stack, {x = pos.x + 1, y = pos.y})
      table.insert(stack, {x = pos.x - 1, y = pos.y})
      table.insert(stack, {x = pos.x, y = pos.y + 1})
      table.insert(stack, {x = pos.x, y = pos.y - 1})
    end
  end
  
  Editor.saveToHistory()
end

-- Save map to file
function Editor.saveMap()
  local lines = {}
  for y = 0, state.mapHeight - 1 do
    local line = ""
    for x = 0, state.mapWidth - 1 do
      line = line .. (state.map[y][x] or " ")
    end
    table.insert(lines, line)
  end
  
  local content = table.concat(lines, "\n")
  local success = love.filesystem.write("map/" .. state.filename, content)
  
  if success then
    print("Map saved to map/" .. state.filename)
  else
    print("Failed to save map")
  end
end

-- Load map from file
function Editor.loadMap()
  local content, err = love.filesystem.read("map/" .. state.filename)
  if not content then
    print("Failed to load map: " .. (err or "unknown error"))
    return
  end
  
  state.map = {}
  local y = 0
  for line in content:gmatch("[^\n]+") do
    state.map[y] = {}
    for x = 0, #line - 1 do
      state.map[y][x] = line:sub(x + 1, x + 1)
    end
    y = y + 1
  end
  
  state.mapHeight = y
  if state.map[0] then
    state.mapWidth = #state.map[0]
  end
  
  Editor.saveToHistory()
  print("Map loaded from map/" .. state.filename)
end

-- Draw editor
function Editor.draw()
  if not state.active then return end
  
  love.graphics.push()
  love.graphics.translate(state.camera.x, state.camera.y)
  
  -- Draw map tiles
  for y = 0, state.mapHeight - 1 do
    for x = 0, state.mapWidth - 1 do
      local tile = state.map[y] and state.map[y][x] or " "
      local tool = Editor.TOOLS[tile] or Editor.TOOLS[" "]
      
      love.graphics.setColor(tool.color)
      love.graphics.rectangle("fill", 
        x * state.gridSize, 
        y * state.gridSize, 
        state.gridSize - 1, 
        state.gridSize - 1
      )
      
      -- Draw symbol
      if tile ~= " " and tile ~= "." then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tile, 
          x * state.gridSize + state.gridSize / 3, 
          y * state.gridSize + state.gridSize / 4
        )
      end
    end
  end
  
  -- Draw grid
  if state.showGrid then
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    for x = 0, state.mapWidth do
      love.graphics.line(
        x * state.gridSize, 0,
        x * state.gridSize, state.mapHeight * state.gridSize
      )
    end
    for y = 0, state.mapHeight do
      love.graphics.line(
        0, y * state.gridSize,
        state.mapWidth * state.gridSize, y * state.gridSize
      )
    end
  end
  
  -- Highlight cursor
  if state.mouseGridX >= 0 and state.mouseGridX < state.mapWidth and
     state.mouseGridY >= 0 and state.mouseGridY < state.mapHeight then
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.rectangle("line",
      state.mouseGridX * state.gridSize,
      state.mouseGridY * state.gridSize,
      state.gridSize,
      state.gridSize
    )
  end
  
  love.graphics.pop()
  
  -- Draw UI
  Editor.drawUI()
end

-- Draw UI overlay
function Editor.drawUI()
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, 300, 100)
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("LEVEL EDITOR", 10, 10)
  love.graphics.print("Current Tool: " .. state.currentTool .. " (" .. Editor.TOOLS[state.currentTool].name .. ")", 10, 30)
  love.graphics.print("Grid: " .. state.mouseGridX .. ", " .. state.mouseGridY, 10, 50)
  love.graphics.print("Press H for help", 10, 70)
  
  -- Tool palette
  local paletteX = 10
  local paletteY = 110
  for i, tool in ipairs(Editor.TOOL_ORDER) do
    local toolData = Editor.TOOLS[tool]
    
    if tool == state.currentTool then
      love.graphics.setColor(1, 1, 0)
      love.graphics.rectangle("fill", paletteX - 2, paletteY - 2, 34, 34)
    end
    
    love.graphics.setColor(toolData.color)
    love.graphics.rectangle("fill", paletteX, paletteY, 30, 30)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tool, paletteX + 8, paletteY + 8)
    
    paletteX = paletteX + 35
    if paletteX > 260 then
      paletteX = 10
      paletteY = paletteY + 35
    end
  end
  
  -- Help screen
  if state.showHelp then
    local helpText = [[
LEVEL EDITOR CONTROLS

Mouse:
  Left Click: Place current tool
  Right Click: Erase (place empty)
  Scroll: Zoom (not implemented)

Movement:
  WASD: Pan camera

Tools:
  TAB: Cycle tools
  1-9: Quick select tool
  F: Flood fill

File:
  F2: Save map
  F3: Load map
  F4: New map

Editing:
  Ctrl+Z: Undo
  Ctrl+Y: Redo

Display:
  G: Toggle grid
  H: Toggle this help

Exit:
  F5/ESC: Exit editor
]]
    
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 50, 50, 600, 500)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(helpText, 70, 70)
  end
end

-- Get current map for export
function Editor.getMap()
  return state.map
end

-- Set filename
function Editor.setFilename(filename)
  state.filename = filename
end

return Editor
