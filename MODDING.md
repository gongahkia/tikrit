# Tikrit Modding Guide

## Introduction

Welcome to Tikrit modding! This guide will help you extend the game with new features, custom content, and gameplay modifications. Tikrit is designed with a modular architecture that makes it easy to add new systems without breaking existing code.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Adding New Modules](#adding-new-modules)
4. [Event System](#event-system)
5. [Creating Custom Entities](#creating-custom-entities)
6. [Custom Hazards](#custom-hazards)
7. [New Items & Power-ups](#new-items--power-ups)
8. [AI Behaviors](#ai-behaviors)
9. [Visual Effects](#visual-effects)
10. [Audio Integration](#audio-integration)
11. [Configuration](#configuration)
12. [Testing Your Mod](#testing-your-mod)
13. [Distribution](#distribution)
14. [Best Practices](#best-practices)
15. [Examples](#examples)

## Getting Started

### Prerequisites

**Required:**
- LÖVE2D 11.4+ ([love2d.org](https://love2d.org))
- Basic Lua knowledge
- Text editor (VS Code, Sublime, etc.)

**Recommended:**
- Git for version control
- Love2D API documentation
- Tikrit source code (read `ARCHITECTURE.md`)

### Setup Development Environment

1. **Clone or download Tikrit:**
   ```bash
   git clone [repository-url] tikrit
   cd tikrit
   ```

2. **Test vanilla game:**
   ```bash
   love src/
   ```

3. **Create a mod workspace:**
   ```bash
   mkdir mods
   mkdir mods/my_mod
   ```

4. **Enable debug mode:**
   ```lua
   -- In src/config.lua
   DEBUG_MODE = true
   DEBUG_SHOW_COLLISION = true
   ```

## Project Structure

```
tikrit/
├── src/
│   ├── main.lua              -- Entry point (edit carefully)
│   ├── config.lua            -- Configuration (mod this!)
│   ├── modules/
│   │   ├── ai.lua
│   │   ├── combat.lua
│   │   ├── procgen.lua
│   │   ├── ui.lua
│   │   ├── effects.lua
│   │   ├── animation.lua
│   │   ├── audio.lua
│   │   ├── utils.lua
│   │   ├── accessibility.lua
│   │   ├── hazards.lua
│   │   ├── events.lua
│   │   ├── statemachine.lua
│   │   └── progression.lua
│   ├── sprite/               -- Add custom sprites here
│   ├── sound/                -- Add custom audio here
│   └── font/                 -- Add custom fonts here
├── map/                      -- Add custom levels here
├── mods/                     -- Your mods go here (NEW)
│   └── my_mod/
│       ├── init.lua          -- Mod entry point
│       ├── config.lua        -- Mod settings
│       └── modules/          -- Mod-specific modules
└── README.md
```

## Adding New Modules

### Step 1: Create Module File

Create `src/modules/mymodule.lua`:

```lua
-- src/modules/mymodule.lua
local MyModule = {}

-- Module state (private)
local state = {
  data = {},
  initialized = false
}

-- Initialize module
function MyModule.init()
  if state.initialized then return end
  
  print("MyModule initialized")
  state.initialized = true
end

-- Update every frame
function MyModule.update(dt)
  if not state.initialized then return end
  
  -- Your logic here
end

-- Draw visuals
function MyModule.draw()
  if not state.initialized then return end
  
  -- Your rendering here
end

-- Public API
function MyModule.doSomething(param)
  -- Your function
  return result
end

return MyModule
```

### Step 2: Register in main.lua

Add to the top of `src/main.lua`:

```lua
local MyModule = require("modules.mymodule")
```

### Step 3: Initialize in love.load()

```lua
function love.load()
  -- ... existing code ...
  
  MyModule.init()
  
  -- ... rest of initialization ...
end
```

### Step 4: Call in Game Loop

```lua
function love.update(dt)
  if mode == "game" then
    -- ... existing updates ...
    
    MyModule.update(dt)
  end
end

function love.draw()
  if mode == "game" then
    -- ... existing rendering ...
    
    MyModule.draw()
  end
end
```

## Event System

Tikrit uses an event bus for decoupled communication. Use this to integrate your mod without editing core files.

### Listening to Events

```lua
-- In your module
local Events = require("modules.events")

function MyModule.init()
  -- Listen for key collection
  Events.on(Events.GAME_EVENTS.KEY_COLLECTED, function(data)
    print("Player collected key at:", data.x, data.y)
    -- Your logic here
  end)
  
  -- Listen for monster kills
  Events.on(Events.GAME_EVENTS.MONSTER_KILLED, function(data)
    print("Monster killed:", data.monsterType)
    -- Award points, drop loot, etc.
  end)
end
```

### Available Events

See `src/modules/events.lua` for full list:

```lua
Events.GAME_EVENTS = {
  -- Player
  PLAYER_DAMAGED = "player_damaged",
  PLAYER_DEATH = "player_death",
  PLAYER_HEALED = "player_healed",
  
  -- Items
  KEY_COLLECTED = "key_collected",
  ITEM_PICKED_UP = "item_picked_up",
  INVENTORY_FULL = "inventory_full",
  
  -- Combat
  MONSTER_KILLED = "monster_killed",
  DAMAGE_DEALT = "damage_dealt",
  
  -- Level
  LEVEL_COMPLETE = "level_complete",
  ROOM_ENTERED = "room_entered",
  
  -- Hazards
  HAZARD_TRIGGERED = "hazard_triggered",
  SPIKE_DAMAGE = "spike_damage",
  
  -- Progression
  UNLOCK_EARNED = "unlock_earned",
  RUN_STARTED = "run_started",
  RUN_ENDED = "run_ended"
}
```

### Triggering Custom Events

```lua
-- Define your event
Events.GAME_EVENTS.MY_CUSTOM_EVENT = "my_custom_event"

-- Trigger it
Events.trigger("my_custom_event", {
  customData = "value",
  timestamp = os.time()
})
```

## Creating Custom Entities

### Example: Treasure Chest

**Step 1: Define Entity Structure**

```lua
-- In your module or main.lua
local chests = {}

function addChest(x, y, loot)
  table.insert(chests, {
    coord = {x = x, y = y},
    opened = false,
    loot = loot,  -- {type = "health", amount = 1}
    sprite = love.graphics.newImage("sprite/chest.png")
  })
end
```

**Step 2: Update Logic**

```lua
function updateChests(playerCoord)
  for i, chest in ipairs(chests) do
    if not chest.opened then
      local dist = math.sqrt(
        (chest.coord.x - playerCoord.x)^2 +
        (chest.coord.y - playerCoord.y)^2
      )
      
      if dist < 1.5 then  -- Close enough
        -- Open chest
        chest.opened = true
        givePlayerLoot(chest.loot)
        Audio.play("chest_open")
        Events.trigger("CHEST_OPENED", chest)
      end
    end
  end
end
```

**Step 3: Rendering**

```lua
function drawChests()
  for _, chest in ipairs(chests) do
    local screenX = chest.coord.x * GRID_SIZE
    local screenY = chest.coord.y * GRID_SIZE
    
    if chest.opened then
      love.graphics.setColor(0.5, 0.5, 0.5)  -- Gray
    else
      love.graphics.setColor(1, 1, 1)  -- White
    end
    
    love.graphics.draw(chest.sprite, screenX, screenY)
  end
  
  love.graphics.setColor(1, 1, 1)  -- Reset
end
```

**Step 4: Level Integration**

Add to map deserializer in `main.lua`:

```lua
function deserialize(mapString)
  -- ... existing code ...
  
  elseif char == "$" then  -- Treasure symbol
    addChest(x, y, {type = "health", amount = 1})
  
  -- ... rest of deserializer ...
end
```

## Custom Hazards

### Example: Fire Trap

**Step 1: Extend Hazards Module**

```lua
-- In src/modules/hazards.lua or your mod

function Hazards.addFireTrap(x, y, damage, tickRate)
  table.insert(hazards.fireTraps, {
    coord = {x = x, y = y},
    damage = damage or 2,
    tickRate = tickRate or 1.0,
    timer = 0,
    active = true,
    particles = {}
  })
end

function Hazards.updateFireTraps(dt, playerCoord)
  for _, trap in ipairs(hazards.fireTraps) do
    trap.timer = trap.timer + dt
    
    if trap.timer >= trap.tickRate then
      trap.timer = 0
      
      -- Check if player is on trap
      if playerCoord.x == trap.coord.x and
         playerCoord.y == trap.coord.y then
        Events.trigger("FIRE_DAMAGE", {damage = trap.damage})
        return trap.damage
      end
    end
    
    -- Update fire particle effect
    updateFireParticles(trap.particles, dt)
  end
  
  return 0
end

function Hazards.drawFireTraps()
  for _, trap in ipairs(hazards.fireTraps) do
    local x = trap.coord.x * GRID_SIZE
    local y = trap.coord.y * GRID_SIZE
    
    -- Draw flame sprite
    love.graphics.setColor(1, 0.5, 0, 0.8)  -- Orange
    love.graphics.rectangle("fill", x, y, GRID_SIZE, GRID_SIZE)
    
    -- Draw particles
    drawFireParticles(trap.particles)
  end
  
  love.graphics.setColor(1, 1, 1)
end
```

**Step 2: Add to Map Format**

```lua
-- In main.lua deserialize()
elseif char == "F" then
  Hazards.addFireTrap(x, y, 2, 1.0)
```

**Step 3: Integrate in Game Loop**

```lua
-- In love.update(dt)
if mode == "game" then
  local fireDamage = Hazards.updateFireTraps(dt, player.coord)
  if fireDamage > 0 then
    takeDamage(fireDamage)
  end
end

-- In love.draw()
if mode == "game" then
  Hazards.drawFireTraps()
end
```

## New Items & Power-ups

### Example: Double Jump Boots

**Step 1: Define Item**

```lua
-- In config.lua
ITEMS = {
  DOUBLE_JUMP_BOOTS = {
    name = "Double Jump Boots",
    description = "Jump over 1-tile walls",
    duration = 30,  -- seconds
    sprite = "sprite/boots.png"
  }
}
```

**Step 2: Item Pickup Logic**

```lua
-- In main.lua or items module
function giveItem(itemType)
  if #player.inventory >= PLAYER_INVENTORY_SIZE then
    Events.trigger("INVENTORY_FULL")
    return false
  end
  
  table.insert(player.inventory, {
    type = itemType,
    timer = ITEMS[itemType].duration
  })
  
  Events.trigger("ITEM_PICKED_UP", {type = itemType})
  Audio.play("pickup")
  return true
end
```

**Step 3: Item Effect**

```lua
-- In love.update(dt)
function updateItems(dt)
  for i = #player.inventory, 1, -1 do
    local item = player.inventory[i]
    item.timer = item.timer - dt
    
    if item.timer <= 0 then
      table.remove(player.inventory, i)
      Events.trigger("ITEM_EXPIRED", {type = item.type})
    end
  end
end

function hasItem(itemType)
  for _, item in ipairs(player.inventory) do
    if item.type == itemType then
      return true
    end
  end
  return false
end

-- In movement code
function canMoveTo(newX, newY)
  local tile = world[newY][newX]
  
  if tile == "#" then
    -- Check for double jump boots
    if hasItem("DOUBLE_JUMP_BOOTS") then
      -- Allow jumping over single walls
      local beyondX = newX + (newX - player.coord.x)
      local beyondY = newY + (newY - player.coord.y)
      
      if world[beyondY] and world[beyondY][beyondX] == "." then
        player.coord.x = beyondX
        player.coord.y = beyondY
        Effects.addParticle(newX, newY, "DUST")
        return true
      end
    end
    return false
  end
  
  return true
end
```

## AI Behaviors

### Example: Patrol Pattern

```lua
-- In src/modules/ai.lua or your mod

AI.PATROL_PATTERNS = {
  CIRCLE = function(ghost, dt)
    ghost.patrolAngle = (ghost.patrolAngle or 0) + dt
    ghost.targetX = ghost.spawnX + math.cos(ghost.patrolAngle) * 3
    ghost.targetY = ghost.spawnY + math.sin(ghost.patrolAngle) * 3
    AI.moveTowards(ghost, ghost.targetX, ghost.targetY, dt)
  end,
  
  ZIGZAG = function(ghost, dt)
    ghost.zigTimer = (ghost.zigTimer or 0) + dt
    if ghost.zigTimer >= 2.0 then
      ghost.zigTimer = 0
      ghost.zigDirection = (ghost.zigDirection or 1) * -1
    end
    ghost.targetX = ghost.coord.x + ghost.zigDirection
    AI.moveTowards(ghost, ghost.targetX, ghost.coord.y, dt)
  end,
  
  GUARD = function(ghost, dt)
    -- Stand still at spawn point
    ghost.targetX = ghost.spawnX
    ghost.targetY = ghost.spawnY
  end
}

function AI.setPatrolPattern(ghost, pattern)
  ghost.patrolPattern = pattern
  ghost.spawnX = ghost.coord.x
  ghost.spawnY = ghost.coord.y
end

function AI.update(ghost, playerCoord, dt)
  if ghost.state == "PATROL" and ghost.patrolPattern then
    AI.PATROL_PATTERNS[ghost.patrolPattern](ghost, dt)
  end
  
  -- Rest of AI logic...
end
```

### Example: Custom Ghost Type

```lua
-- Ranged ghost that shoots projectiles
function createRangedGhost(x, y)
  local ghost = {
    coord = {x = x, y = y},
    health = 2,
    speed = 60,
    visionRadius = 7,
    attackRange = 5,
    state = "PATROL",
    type = "RANGED",
    shootCooldown = 0
  }
  
  table.insert(world.ghosts, ghost)
end

function updateRangedGhost(ghost, playerCoord, dt)
  ghost.shootCooldown = math.max(0, ghost.shootCooldown - dt)
  
  local dist = Utils.distance(
    ghost.coord.x, ghost.coord.y,
    playerCoord.x, playerCoord.y
  )
  
  if dist <= ghost.attackRange and ghost.shootCooldown == 0 then
    -- Shoot projectile
    createProjectile(ghost.coord, playerCoord)
    ghost.shootCooldown = 2.0
    Audio.play("ghost_shoot")
  end
end
```

## Visual Effects

### Example: Custom Particle Effect

```lua
-- In src/modules/effects.lua or your mod

Effects.PARTICLE_TYPES.SPARKLE = {
  color = {1, 1, 0},  -- Yellow
  lifetime = 1.5,
  speed = 100,
  size = 8,
  gravity = -50  -- Float upwards
}

function Effects.spawnSparkles(x, y, count)
  for i = 1, count do
    local angle = math.random() * math.pi * 2
    local particle = {
      x = x,
      y = y,
      vx = math.cos(angle) * Effects.PARTICLE_TYPES.SPARKLE.speed,
      vy = math.sin(angle) * Effects.PARTICLE_TYPES.SPARKLE.speed,
      lifetime = Effects.PARTICLE_TYPES.SPARKLE.lifetime,
      type = "SPARKLE"
    }
    table.insert(Effects.particles, particle)
  end
end

-- Use in your code
Events.on("UNLOCK_EARNED", function(data)
  Effects.spawnSparkles(player.coord.x * GRID_SIZE, player.coord.y * GRID_SIZE, 20)
end)
```

### Example: Screen Overlay

```lua
function drawPoisonOverlay(intensity)
  love.graphics.setColor(0, 1, 0, intensity * 0.3)  -- Green tint
  love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
  love.graphics.setColor(1, 1, 1)
end

-- In love.draw()
if player.poisoned then
  drawPoisonOverlay(player.poisonLevel)
end
```

## Audio Integration

### Adding Custom Sounds

**Step 1: Add Sound Files**

Place audio files in `src/sound/`:
```
src/sound/
├── my_mod_powerup.ogg
├── my_mod_explosion.wav
└── my_mod_music.mp3
```

**Step 2: Load in Audio Module**

```lua
-- In src/modules/audio.lua
function Audio.init()
  -- ... existing sounds ...
  
  Audio.sounds.my_powerup = love.audio.newSource("sound/my_mod_powerup.ogg", "static")
  Audio.sounds.my_explosion = love.audio.newSource("sound/my_mod_explosion.wav", "static")
  Audio.music.my_theme = love.audio.newSource("sound/my_mod_music.mp3", "stream")
end
```

**Step 3: Play Sounds**

```lua
Audio.play("my_powerup")
Audio.playMusic("my_theme")
```

### Dynamic Audio

```lua
-- Pitch shift based on speed
function Audio.play(soundName, pitch)
  pitch = pitch or 1.0
  local sound = Audio.sounds[soundName]
  if sound then
    sound:setPitch(pitch)
    sound:play()
  end
end

-- Use it
Audio.play("footstep", player.speed / 200)  -- Faster = higher pitch
```

## Configuration

### Mod-Specific Config

Create `mods/my_mod/config.lua`:

```lua
return {
  ENABLE_FIRE_TRAPS = true,
  FIRE_DAMAGE = 2,
  FIRE_TICK_RATE = 1.0,
  
  ENABLE_CHESTS = true,
  CHEST_LOOT_TABLE = {
    {item = "health", weight = 50},
    {item = "speed", weight = 30},
    {item = "rare_item", weight = 20}
  }
}
```

### Loading Mod Config

```lua
-- In your mod's init.lua
local modConfig = require("mods.my_mod.config")

function MyMod.init()
  if modConfig.ENABLE_FIRE_TRAPS then
    -- Enable fire traps
  end
end
```

### Overriding Core Config

```lua
-- In src/config.lua (or via mod)
local config = require("config")

-- Save original
local originalPlayerSpeed = config.PLAYER_SPEED

-- Override
config.PLAYER_SPEED = 300  -- Super speed mod!
```

## Testing Your Mod

### Debug Printing

```lua
-- Enable debug mode
DEBUG_MODE = true

-- Print debug info
function love.update(dt)
  if DEBUG_MODE then
    print("Player pos:", player.coord.x, player.coord.y)
    print("FPS:", love.timer.getFPS())
  end
end
```

### On-Screen Debug Info

```lua
function love.draw()
  if DEBUG_MODE then
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Player HP: " .. player.health, 10, 10)
    love.graphics.print("Inventory: " .. #player.inventory, 10, 30)
    love.graphics.print("Ghosts: " .. #world.ghosts, 10, 50)
    love.graphics.setColor(1, 1, 1)
  end
end
```

### Automated Testing (Future)

```lua
-- tests/test_mymod.lua
local MyMod = require("mods.my_mod.init")

function test_fireTrap()
  MyMod.addFireTrap(5, 5, 2, 1.0)
  assert(#MyMod.fireTraps == 1, "Fire trap not added")
  print("✓ Fire trap test passed")
end

test_fireTrap()
```

## Distribution

### Method 1: Standalone Mod Folder

```
my_mod/
├── README.md           -- Installation instructions
├── init.lua            -- Mod entry point
├── config.lua          -- Settings
├── modules/            -- Mod code
│   ├── firetraps.lua
│   └── chests.lua
├── sprite/             -- Mod assets
│   ├── chest.png
│   └── fire.png
└── sound/
    └── explosion.ogg
```

**Installation:** Copy to `tikrit/mods/my_mod/`

### Method 2: Core Integration

For larger mods, integrate directly:
```
tikrit/
├── src/
│   └── modules/
│       └── mymod.lua    -- Add your module
```

**Distribution:** Fork repo, create pull request

### Method 3: Love Package

```bash
# Create .love file
cd my_mod
zip -r ../my_mod.love .

# Users drag-drop onto tikrit.love
```

## Best Practices

### 1. **Use the Event System**
```lua
-- ✅ GOOD: Decoupled
Events.on("PLAYER_DAMAGED", function(data)
  MyMod.onPlayerHurt(data)
end)

-- ❌ BAD: Tight coupling
function takeDamage(amount)
  player.health = player.health - amount
  MyMod.onPlayerHurt(amount)  -- Hardcoded dependency
end
```

### 2. **Don't Modify Core Files Directly**
```lua
-- ✅ GOOD: Extend via events/config
Events.on("MONSTER_KILLED", function(data)
  MyMod.dropLoot(data.x, data.y)
end)

-- ❌ BAD: Edit main.lua
-- Adds maintenance burden
```

### 3. **Use Configuration**
```lua
-- ✅ GOOD: Tweakable
local damage = config.FIRE_DAMAGE

-- ❌ BAD: Magic number
local damage = 2  -- What if balance changes?
```

### 4. **Namespace Your Code**
```lua
-- ✅ GOOD: Clear ownership
MyMod.addFireTrap()

-- ❌ BAD: Pollutes global scope
addFireTrap()  -- Conflicts with other mods?
```

### 5. **Document Your API**
```lua
---Add a fire trap hazard to the world
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@param damage number Damage per tick (default: 2)
---@param tickRate number Seconds between damage (default: 1.0)
---@return table The created fire trap
function MyMod.addFireTrap(x, y, damage, tickRate)
  -- Implementation
end
```

### 6. **Handle Errors Gracefully**
```lua
-- ✅ GOOD: Check before use
function MyMod.getSprite(name)
  if MyMod.sprites[name] then
    return MyMod.sprites[name]
  else
    print("ERROR: Sprite not found:", name)
    return MyMod.sprites.default  -- Fallback
  end
end

-- ❌ BAD: Crash on missing asset
function MyMod.getSprite(name)
  return MyMod.sprites[name]  -- Nil error!
end
```

### 7. **Optimize Performance**
```lua
-- ✅ GOOD: Cache expensive calls
local sqrt = math.sqrt  -- Local reference

function distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return sqrt(dx*dx + dy*dy)
end

-- ❌ BAD: Recalculate every frame
function distance(x1, y1, x2, y2)
  return math.sqrt((x2-x1)^2 + (y2-y1)^2)  -- Slower
end
```

## Examples

### Full Example: Boss Fight Mod

```lua
-- mods/boss_fight/init.lua
local BossMod = {}
local Events = require("modules.events")
local Effects = require("modules.effects")
local Audio = require("modules.audio")

-- Boss state
local boss = nil

function BossMod.init()
  print("Boss Fight Mod loaded!")
  
  -- Listen for level completion to spawn boss
  Events.on("LEVEL_COMPLETE", function(data)
    if data.level == 10 then  -- Boss level
      BossMod.spawnBoss(data.exitX, data.exitY)
    end
  end)
end

function BossMod.spawnBoss(x, y)
  boss = {
    coord = {x = x, y = y},
    health = 50,
    maxHealth = 50,
    speed = 120,
    damage = 2,
    phase = 1,
    attackCooldown = 0,
    sprite = love.graphics.newImage("mods/boss_fight/sprite/boss.png")
  }
  
  Audio.playMusic("boss_theme")
  Events.trigger("BOSS_SPAWNED", boss)
end

function BossMod.update(dt)
  if not boss or boss.health <= 0 then return end
  
  boss.attackCooldown = boss.attackCooldown - dt
  
  -- Phase transitions
  if boss.health < boss.maxHealth * 0.5 and boss.phase == 1 then
    boss.phase = 2
    boss.speed = 180
    Effects.screenShake(10, 1.0)
  end
  
  -- Attack logic
  if boss.attackCooldown <= 0 then
    BossMod.bossAttack()
    boss.attackCooldown = 3.0
  end
  
  -- Movement AI
  BossMod.bossMovement(dt)
end

function BossMod.bossAttack()
  if boss.phase == 1 then
    -- Melee attack
    Events.trigger("BOSS_ATTACK_MELEE", boss)
  else
    -- Ranged attack
    BossMod.spawnProjectiles()
    Events.trigger("BOSS_ATTACK_RANGED", boss)
  end
end

function BossMod.spawnProjectiles()
  for i = 0, 7 do
    local angle = (i / 8) * math.pi * 2
    -- Spawn projectile in direction
  end
end

function BossMod.takeDamage(amount)
  if not boss then return end
  
  boss.health = boss.health - amount
  Effects.spawnParticles(boss.coord.x, boss.coord.y, "BLOOD", 10)
  
  if boss.health <= 0 then
    BossMod.bossDeath()
  end
end

function BossMod.bossDeath()
  Effects.screenShake(20, 2.0)
  Audio.play("boss_death")
  Events.trigger("BOSS_DEFEATED", boss)
  
  -- Drop loot
  for i = 1, 5 do
    -- Spawn items
  end
  
  boss = nil
end

function BossMod.draw()
  if not boss then return end
  
  local x = boss.coord.x * GRID_SIZE
  local y = boss.coord.y * GRID_SIZE
  
  -- Draw boss sprite
  love.graphics.draw(boss.sprite, x, y)
  
  -- Draw health bar
  local barWidth = 200
  local barHeight = 20
  local barX = (WINDOW_WIDTH - barWidth) / 2
  local barY = 50
  
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
  
  love.graphics.setColor(1, 0, 0)
  local healthPercent = boss.health / boss.maxHealth
  love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("BOSS HP: " .. boss.health, barX, barY - 20)
end

return BossMod
```

**Usage:**
```lua
-- In src/main.lua
local BossMod = require("mods.boss_fight.init")

function love.load()
  -- ... existing code ...
  BossMod.init()
end

function love.update(dt)
  if mode == "game" then
    BossMod.update(dt)
  end
end

function love.draw()
  if mode == "game" then
    BossMod.draw()
  end
end
```

## Resources

- **ARCHITECTURE.md:** System design reference
- **LEVEL_DESIGN.md:** Map creation guide
- **API.md:** Function reference (planned)
- **LÖVE2D Wiki:** [love2d.org/wiki](https://love2d.org/wiki)
- **Lua Manual:** [lua.org/manual](https://www.lua.org/manual/5.1/)

## Community

Share your mods:
- GitHub Issues/Discussions
- Itch.io page
- Discord server (if available)

## License

Respect the base game's license. Check README.md for details.

---

**Happy Modding!**  
**Last Updated:** 2024 (v2.5.0)  
**Questions?** Open an issue or contribute to docs!
