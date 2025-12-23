-- Puzzle Mode Module
-- Transforms the game into a logic-puzzle experience
-- Removes combat/ghosts, adds push-blocks and pressure plates

local Puzzle = {}

-- Puzzle state
local enabled = false
local pushableBlocks = {}  -- {x, y, type}
local pressurePlates = {}  -- {x, y, activated, linkedDoor}
local puzzleDoors = {}  -- {x, y, open, requiredPlates}
local movingBlock = nil  -- Currently being pushed
local puzzlesSolved = 0

-- Puzzle configuration
local BLOCK_SIZE = 32
local PUSH_SPEED = 100  -- pixels per second

-- Initialize puzzle mode
function Puzzle.init()
    enabled = false
    pushableBlocks = {}
    pressurePlates = {}
    puzzleDoors = {}
    movingBlock = nil
    puzzlesSolved = 0
    print("[Puzzle] System initialized")
end

-- Enable puzzle mode
function Puzzle.enable()
    enabled = true
    pushableBlocks = {}
    pressurePlates = {}
    puzzleDoors = {}
    puzzlesSolved = 0
    print("[Puzzle] Mode enabled - No ghosts, logic puzzles only")
end

-- Disable puzzle mode
function Puzzle.disable()
    enabled = false
    print("[Puzzle] Mode disabled")
end

-- Check if puzzle mode is enabled
function Puzzle.isEnabled()
    return enabled
end

-- Generate puzzle elements for current room
function Puzzle.generatePuzzleRoom(roomWidth, roomHeight, roomNumber)
    if not enabled then return end
    
    pushableBlocks = {}
    pressurePlates = {}
    puzzleDoors = {}
    
    -- Generate puzzle based on room number (difficulty increases)
    if roomNumber <= 3 then
        -- Simple push-block puzzle
        generateSimplePushPuzzle(roomWidth, roomHeight)
    elseif roomNumber <= 7 then
        -- Pressure plate sequence
        generatePressurePlatePuzzle(roomWidth, roomHeight)
    else
        -- Complex combination puzzle
        generateComplexPuzzle(roomWidth, roomHeight)
    end
end

-- Simple push puzzle: Move blocks to designated spots
function generateSimplePushPuzzle(w, h)
    local centerX = w * BLOCK_SIZE / 2
    local centerY = h * BLOCK_SIZE / 2
    
    -- Add 2-3 pushable blocks
    local numBlocks = math.random(2, 3)
    for i = 1, numBlocks do
        table.insert(pushableBlocks, {
            x = centerX + (i - numBlocks/2) * 64,
            y = centerY - 64,
            type = "crate"
        })
    end
    
    -- Add target pressure plates
    for i = 1, numBlocks do
        table.insert(pressurePlates, {
            x = centerX + (i - numBlocks/2) * 64,
            y = centerY + 64,
            activated = false,
            linkedDoor = 1
        })
    end
    
    -- Add locked door
    table.insert(puzzleDoors, {
        x = centerX,
        y = 32,
        open = false,
        requiredPlates = numBlocks
    })
end

-- Pressure plate sequence puzzle
function generatePressurePlatePuzzle(w, h)
    local centerX = w * BLOCK_SIZE / 2
    local centerY = h * BLOCK_SIZE / 2
    
    -- Add 4 pressure plates in corners
    local positions = {
        {centerX - 96, centerY - 96},
        {centerX + 96, centerY - 96},
        {centerX - 96, centerY + 96},
        {centerX + 96, centerY + 96}
    }
    
    for i, pos in ipairs(positions) do
        table.insert(pressurePlates, {
            x = pos[1],
            y = pos[2],
            activated = false,
            linkedDoor = 1,
            sequence = i
        })
    end
    
    -- Add door
    table.insert(puzzleDoors, {
        x = centerX,
        y = 32,
        open = false,
        requiredPlates = 4,
        requiresSequence = true
    })
end

-- Complex puzzle with multiple blocks and plates
function generateComplexPuzzle(w, h)
    local centerX = w * BLOCK_SIZE / 2
    local centerY = h * BLOCK_SIZE / 2
    
    -- Add 4 pushable blocks
    for i = 1, 4 do
        local angle = (i - 1) * math.pi / 2
        table.insert(pushableBlocks, {
            x = centerX + math.cos(angle) * 100,
            y = centerY + math.sin(angle) * 100,
            type = "crate"
        })
    end
    
    -- Add 4 pressure plates
    for i = 1, 4 do
        local angle = (i - 1) * math.pi / 2 + math.pi / 4
        table.insert(pressurePlates, {
            x = centerX + math.cos(angle) * 120,
            y = centerY + math.sin(angle) * 120,
            activated = false,
            linkedDoor = 1
        })
    end
    
    -- Add door
    table.insert(puzzleDoors, {
        x = centerX,
        y = 32,
        open = false,
        requiredPlates = 4
    })
end

-- Update puzzle logic
function Puzzle.update(dt, playerCoord, playerMoving, moveDir)
    if not enabled then return end
    
    -- Check pressure plate activation
    for _, plate in ipairs(pressurePlates) do
        local wasActivated = plate.activated
        plate.activated = false
        
        -- Check if player is on plate
        if checkOverlap(playerCoord[1], playerCoord[2], plate.x, plate.y) then
            plate.activated = true
        end
        
        -- Check if any block is on plate
        for _, block in ipairs(pushableBlocks) do
            if checkOverlap(block.x, block.y, plate.x, plate.y) then
                plate.activated = true
                break
            end
        end
        
        -- Play sound when plate activates
        if plate.activated and not wasActivated then
            print("[Puzzle] Pressure plate activated")
        end
    end
    
    -- Try to push blocks
    if playerMoving and moveDir then
        for _, block in ipairs(pushableBlocks) do
            local dx = playerCoord[1] - block.x
            local dy = playerCoord[2] - block.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- If player is adjacent to block and moving toward it
            if dist < BLOCK_SIZE + 10 then
                local pushX = block.x + moveDir[1] * dt * PUSH_SPEED
                local pushY = block.y + moveDir[2] * dt * PUSH_SPEED
                
                -- Check if new position is valid (not in wall, not in another block)
                if canPushBlock(pushX, pushY, block) then
                    block.x = pushX
                    block.y = pushY
                end
            end
        end
    end
    
    -- Update door states
    for _, door in ipairs(puzzleDoors) do
        local activatedCount = 0
        for _, plate in ipairs(pressurePlates) do
            if plate.activated and plate.linkedDoor == door.linkedDoor then
                activatedCount = activatedCount + 1
            end
        end
        
        local wasOpen = door.open
        door.open = (activatedCount >= door.requiredPlates)
        
        if door.open and not wasOpen then
            print("[Puzzle] Door opened! Puzzle solved!")
            puzzlesSolved = puzzlesSolved + 1
        end
    end
end

-- Check if two objects overlap
function checkOverlap(x1, y1, x2, y2)
    local threshold = BLOCK_SIZE / 2
    return math.abs(x1 - x2) < threshold and math.abs(y1 - y2) < threshold
end

-- Check if block can be pushed to this position
function canPushBlock(x, y, block)
    -- Check against walls (simplified - assumes walls are stored elsewhere)
    -- For now, just check against room bounds
    if x < BLOCK_SIZE or y < BLOCK_SIZE then
        return false
    end
    
    -- Check against other blocks
    for _, otherBlock in ipairs(pushableBlocks) do
        if otherBlock ~= block then
            if checkOverlap(x, y, otherBlock.x, otherBlock.y) then
                return false
            end
        end
    end
    
    return true
end

-- Draw puzzle elements
function Puzzle.draw()
    if not enabled then return end
    
    -- Draw pushable blocks
    love.graphics.setColor(0.6, 0.4, 0.2, 1)  -- Brown for crates
    for _, block in ipairs(pushableBlocks) do
        love.graphics.rectangle("fill", block.x - BLOCK_SIZE/2, block.y - BLOCK_SIZE/2, BLOCK_SIZE, BLOCK_SIZE)
        love.graphics.setColor(0.4, 0.3, 0.15, 1)
        love.graphics.rectangle("line", block.x - BLOCK_SIZE/2, block.y - BLOCK_SIZE/2, BLOCK_SIZE, BLOCK_SIZE)
        love.graphics.setColor(0.6, 0.4, 0.2, 1)
    end
    
    -- Draw pressure plates
    for _, plate in ipairs(pressurePlates) do
        if plate.activated then
            love.graphics.setColor(0, 1, 0, 0.8)  -- Green when activated
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.6)  -- Gray when inactive
        end
        love.graphics.rectangle("fill", plate.x - 16, plate.y - 16, 32, 32)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", plate.x - 16, plate.y - 16, 32, 32)
    end
    
    -- Draw puzzle doors
    for _, door in ipairs(puzzleDoors) do
        if door.open then
            love.graphics.setColor(0, 1, 0, 0.3)  -- Transparent green when open
        else
            love.graphics.setColor(1, 0, 0, 0.8)  -- Red when locked
        end
        love.graphics.rectangle("fill", door.x - BLOCK_SIZE, door.y, BLOCK_SIZE * 2, BLOCK_SIZE)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", door.x - BLOCK_SIZE, door.y, BLOCK_SIZE * 2, BLOCK_SIZE)
    end
end

-- Draw puzzle UI
function Puzzle.drawUI()
    if not enabled then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("PUZZLE MODE", 10, 10)
    love.graphics.print("Puzzles Solved: " .. puzzlesSolved, 10, 30)
    
    -- Show active pressure plates
    local activatedCount = 0
    for _, plate in ipairs(pressurePlates) do
        if plate.activated then
            activatedCount = activatedCount + 1
        end
    end
    love.graphics.print(string.format("Plates: %d/%d", activatedCount, #pressurePlates), 10, 50)
end

-- Get puzzles solved count
function Puzzle.getPuzzlesSolved()
    return puzzlesSolved
end

-- Get pushable blocks (for collision detection)
function Puzzle.getPushableBlocks()
    return pushableBlocks
end

-- Get pressure plates (for visualization)
function Puzzle.getPressurePlates()
    return pressurePlates
end

-- Check if puzzle door blocks path
function Puzzle.isDoorBlocking(x, y)
    for _, door in ipairs(puzzleDoors) do
        if not door.open then
            if x >= door.x - BLOCK_SIZE and x <= door.x + BLOCK_SIZE and
               y >= door.y and y <= door.y + BLOCK_SIZE then
                return true
            end
        end
    end
    return false
end

return Puzzle
