# Tikrit API Reference

## Overview

This document provides a comprehensive reference for all public functions, modules, and interfaces in Tikrit. Use this as a quick lookup when developing mods or extending the game.

## Table of Contents

1. [Module: AI](#module-ai)
2. [Module: Combat](#module-combat)
3. [Module: Procgen](#module-procgen)
4. [Module: UI](#module-ui)
5. [Module: Effects](#module-effects)
6. [Module: Animation](#module-animation)
7. [Module: Audio](#module-audio)
8. [Module: Utils](#module-utils)
9. [Module: Accessibility](#module-accessibility)
10. [Module: Hazards](#module-hazards)
11. [Module: Events](#module-events)
12. [Module: StateMachine](#module-statemachine)
13. [Module: Progression](#module-progression)
14. [Config Constants](#config-constants)
15. [Main Game Functions](#main-game-functions)

---

## Module: AI

**File:** `src/modules/ai.lua`  
**Purpose:** Ghost enemy artificial intelligence and pathfinding

### AI.init()
Initialize the AI module.

**Returns:** `nil`

**Example:**
```lua
AI.init()
```

---

### AI.update(ghost, playerCoord, dt)
Update ghost AI behavior for one frame.

**Parameters:**
- `ghost` (table): Ghost entity with `coord`, `state`, `speed` properties
- `playerCoord` (table): Player position `{x, y}`
- `dt` (number): Delta time in seconds

**Returns:** `nil`

**Side Effects:** Modifies `ghost.coord` and `ghost.state`

**Example:**
```lua
for _, ghost in ipairs(world.ghosts) do
  AI.update(ghost, player.coord, dt)
end
```

---

### AI.findPath(start, goal, world)
Calculate A* pathfinding from start to goal.

**Parameters:**
- `start` (table): Starting coordinate `{x, y}`
- `goal` (table): Target coordinate `{x, y}`
- `world` (table): 2D grid array (map)

**Returns:** `table` - Array of coordinates from start to goal, or empty table if no path

**Example:**
```lua
local path = AI.findPath({x = 1, y = 1}, {x = 10, y = 10}, world)
for _, coord in ipairs(path) do
  print("Step:", coord.x, coord.y)
end
```

---

### AI.canSeePlayer(ghost, playerCoord, world)
Check if ghost has line-of-sight to player.

**Parameters:**
- `ghost` (table): Ghost entity
- `playerCoord` (table): Player position `{x, y}`
- `world` (table): 2D grid array

**Returns:** `boolean` - `true` if player is visible

**Example:**
```lua
if AI.canSeePlayer(ghost, player.coord, world) then
  ghost.state = "CHASE"
end
```

---

## Module: Combat

**File:** `src/modules/combat.lua`  
**Purpose:** Damage calculation and combat mechanics

### Combat.attack(attacker, target)
Execute an attack from attacker to target.

**Parameters:**
- `attacker` (table): Attacking entity with `damage` property
- `target` (table): Target entity with `health` property

**Returns:** `number` - Actual damage dealt

**Side Effects:** Modifies `target.health`, triggers events

**Example:**
```lua
local damage = Combat.attack(player, ghost)
print("Dealt", damage, "damage!")
```

---

### Combat.takeDamage(entity, amount)
Apply damage to an entity.

**Parameters:**
- `entity` (table): Entity with `health` and `invincibilityTimer` properties
- `amount` (number): Damage amount

**Returns:** `boolean` - `true` if damage was applied, `false` if invincible

**Side Effects:** Decrements health, triggers death events

**Example:**
```lua
if Combat.takeDamage(player, 1) then
  Effects.screenShake(5, 0.3)
end
```

---

### Combat.calculateDamage(base, modifiers)
Calculate final damage with modifiers.

**Parameters:**
- `base` (number): Base damage value
- `modifiers` (table): Optional modifiers `{multiplier, bonus}`

**Returns:** `number` - Final damage amount

**Example:**
```lua
local damage = Combat.calculateDamage(1, {multiplier = 2, bonus = 5})
-- Returns: (1 * 2) + 5 = 7
```

---

## Module: Procgen

**File:** `src/modules/procgen.lua`  
**Purpose:** Procedural map generation

### Procgen.generateDungeon(width, height, difficulty)
Generate a random dungeon layout.

**Parameters:**
- `width` (number): Grid width (default: 40)
- `height` (number): Grid height (default: 25)
- `difficulty` (number): Difficulty level 1-10 (default: 1)

**Returns:** `table` - Generated world structure with map, ghosts, items, keys

**Example:**
```lua
local world = Procgen.generateDungeon(50, 30, 5)
-- world.map = 2D array
-- world.ghosts = array of ghosts
-- world.keys = array of keys
```

---

### Procgen.generateRoom(x, y, width, height)
Create a rectangular room in the dungeon.

**Parameters:**
- `x` (number): Top-left X coordinate
- `y` (number): Top-left Y coordinate
- `width` (number): Room width
- `height` (number): Room height

**Returns:** `table` - Room structure `{x, y, width, height, center}`

**Example:**
```lua
local room = Procgen.generateRoom(5, 5, 10, 8)
print("Room center:", room.center.x, room.center.y)
```

---

### Procgen.connectRooms(room1, room2)
Create a corridor connecting two rooms.

**Parameters:**
- `room1` (table): First room
- `room2` (table): Second room

**Returns:** `nil`

**Side Effects:** Modifies world map to carve corridor

**Example:**
```lua
Procgen.connectRooms(startRoom, keyRoom)
```

---

## Module: UI

**File:** `src/modules/ui.lua`  
**Purpose:** User interface rendering

### UI.drawTitleScreen()
Render the main menu screen.

**Parameters:** None

**Returns:** `nil`

**Example:**
```lua
function love.draw()
  if mode == "title" then
    UI.drawTitleScreen()
  end
end
```

---

### UI.drawGameScreen(player, world, timer)
Render the in-game HUD.

**Parameters:**
- `player` (table): Player entity with `health`, `inventory`
- `world` (table): World state
- `timer` (number): Optional game timer for time attack mode

**Returns:** `nil`

**Example:**
```lua
UI.drawGameScreen(player, world, gameTimer)
```

---

### UI.drawWinScreen(stats)
Render victory screen with stats.

**Parameters:**
- `stats` (table): Game statistics `{time, keys, monsters, deaths}`

**Returns:** `nil`

**Example:**
```lua
UI.drawWinScreen({
  time = 120.5,
  keys = 5,
  monsters = 12,
  deaths = 3
})
```

---

### UI.drawLoseScreen(stats)
Render game over screen.

**Parameters:**
- `stats` (table): Game statistics

**Returns:** `nil`

**Example:**
```lua
UI.drawLoseScreen(runStats)
```

---

### UI.drawProgressionScreen()
Render progression/unlocks screen.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
UI.drawProgressionScreen()
```

---

### UI.drawHealthBar(x, y, current, max)
Draw a health bar at position.

**Parameters:**
- `x` (number): Screen X coordinate
- `y` (number): Screen Y coordinate
- `current` (number): Current health
- `max` (number): Maximum health

**Returns:** `nil`

**Example:**
```lua
UI.drawHealthBar(50, 50, player.health, PLAYER_MAX_HEALTH)
```

---

## Module: Effects

**File:** `src/modules/effects.lua`  
**Purpose:** Visual effects and particles

### Effects.screenShake(intensity, duration)
Trigger screen shake effect.

**Parameters:**
- `intensity` (number): Shake magnitude in pixels (default: 5)
- `duration` (number): Duration in seconds (default: 0.3)

**Returns:** `nil`

**Example:**
```lua
Effects.screenShake(10, 0.5)  -- Strong shake for 0.5s
```

---

### Effects.addParticle(x, y, type)
Spawn a particle effect.

**Parameters:**
- `x` (number): World X coordinate
- `y` (number): World Y coordinate
- `type` (string): Particle type: `"BLOOD"`, `"SPARKLE"`, `"DUST"`, `"EXPLOSION"`

**Returns:** `table` - Created particle

**Example:**
```lua
Effects.addParticle(player.coord.x, player.coord.y, "SPARKLE")
```

---

### Effects.damageIndicator(x, y, amount)
Display floating damage number.

**Parameters:**
- `x` (number): Screen X coordinate
- `y` (number): Screen Y coordinate
- `amount` (number): Damage value to display

**Returns:** `nil`

**Example:**
```lua
Effects.damageIndicator(enemy.x, enemy.y, 5)
```

---

### Effects.flashSprite(sprite, duration)
Flash sprite for invincibility visual.

**Parameters:**
- `sprite` (Image): Love2D image object
- `duration` (number): Flash duration in seconds

**Returns:** `nil`

**Example:**
```lua
Effects.flashSprite(playerSprite, 2.0)
```

---

### Effects.update(dt)
Update all active effects.

**Parameters:**
- `dt` (number): Delta time in seconds

**Returns:** `nil`

**Example:**
```lua
function love.update(dt)
  Effects.update(dt)
end
```

---

### Effects.draw()
Render all active effects.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
function love.draw()
  Effects.draw()
end
```

---

## Module: Animation

**File:** `src/modules/animation.lua`  
**Purpose:** Sprite animation system

### Animation.create(spritesheet, frames, fps)
Create a new animation.

**Parameters:**
- `spritesheet` (Image): Love2D image object
- `frames` (table): Array of frame quads
- `fps` (number): Frames per second (default: 10)

**Returns:** `table` - Animation object

**Example:**
```lua
local anim = Animation.create(
  playerSheet,
  {quad1, quad2, quad3, quad4},
  15  -- 15 FPS
)
```

---

### Animation.update(anim, dt)
Advance animation by delta time.

**Parameters:**
- `anim` (table): Animation object
- `dt` (number): Delta time in seconds

**Returns:** `nil`

**Side Effects:** Updates `anim.currentFrame`

**Example:**
```lua
Animation.update(playerAnim, dt)
```

---

### Animation.draw(anim, x, y, flipH, flipV)
Draw current animation frame.

**Parameters:**
- `anim` (table): Animation object
- `x` (number): Screen X coordinate
- `y` (number): Screen Y coordinate
- `flipH` (boolean): Flip horizontally (optional)
- `flipV` (boolean): Flip vertically (optional)

**Returns:** `nil`

**Example:**
```lua
Animation.draw(playerAnim, 100, 100, true, false)
```

---

### Animation.reset(anim)
Reset animation to first frame.

**Parameters:**
- `anim` (table): Animation object

**Returns:** `nil`

**Example:**
```lua
Animation.reset(explosionAnim)
```

---

## Module: Audio

**File:** `src/modules/audio.lua`  
**Purpose:** Sound effects and music

### Audio.init()
Initialize audio module and load all sounds.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
function love.load()
  Audio.init()
end
```

---

### Audio.play(soundName, volume)
Play a sound effect.

**Parameters:**
- `soundName` (string): Name of sound (e.g., `"damage"`, `"pickup"`)
- `volume` (number): Volume 0.0-1.0 (optional, default: 1.0)

**Returns:** `nil`

**Example:**
```lua
Audio.play("damage", 0.8)
```

---

### Audio.playMusic(musicName, loop)
Play background music.

**Parameters:**
- `musicName` (string): Name of music track
- `loop` (boolean): Whether to loop (default: true)

**Returns:** `nil`

**Example:**
```lua
Audio.playMusic("boss_theme", true)
```

---

### Audio.stopMusic()
Stop currently playing music.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
Audio.stopMusic()
```

---

### Audio.setMasterVolume(volume)
Set master volume level.

**Parameters:**
- `volume` (number): Volume 0.0-1.0

**Returns:** `nil`

**Example:**
```lua
Audio.setMasterVolume(0.5)  -- 50% volume
```

---

### Audio.setMusicVolume(volume)
Set music volume level.

**Parameters:**
- `volume` (number): Volume 0.0-1.0

**Returns:** `nil`

**Example:**
```lua
Audio.setMusicVolume(0.3)  -- Quiet music
```

---

### Audio.setSFXVolume(volume)
Set sound effects volume level.

**Parameters:**
- `volume` (number): Volume 0.0-1.0

**Returns:** `nil`

**Example:**
```lua
Audio.setSFXVolume(0.8)
```

---

## Module: Utils

**File:** `src/modules/utils.lua`  
**Purpose:** Helper utility functions

### Utils.distance(x1, y1, x2, y2)
Calculate Euclidean distance between two points.

**Parameters:**
- `x1` (number): First point X
- `y1` (number): First point Y
- `x2` (number): Second point X
- `y2` (number): Second point Y

**Returns:** `number` - Distance

**Example:**
```lua
local dist = Utils.distance(0, 0, 3, 4)  -- Returns 5
```

---

### Utils.clamp(value, min, max)
Constrain value to range.

**Parameters:**
- `value` (number): Value to clamp
- `min` (number): Minimum value
- `max` (number): Maximum value

**Returns:** `number` - Clamped value

**Example:**
```lua
local speed = Utils.clamp(playerSpeed, 0, 300)
```

---

### Utils.gridToPixel(gridX, gridY)
Convert grid coordinates to screen pixels.

**Parameters:**
- `gridX` (number): Grid X coordinate
- `gridY` (number): Grid Y coordinate

**Returns:** `number, number` - Screen X, Y coordinates

**Example:**
```lua
local screenX, screenY = Utils.gridToPixel(5, 10)
love.graphics.circle("fill", screenX, screenY, 10)
```

---

### Utils.pixelToGrid(pixelX, pixelY)
Convert screen pixels to grid coordinates.

**Parameters:**
- `pixelX` (number): Screen X coordinate
- `pixelY` (number): Screen Y coordinate

**Returns:** `number, number` - Grid X, Y coordinates

**Example:**
```lua
local gridX, gridY = Utils.pixelToGrid(mouseX, mouseY)
```

---

### Utils.isWalkable(x, y, world)
Check if grid tile is walkable.

**Parameters:**
- `x` (number): Grid X coordinate
- `y` (number): Grid Y coordinate
- `world` (table): World 2D array

**Returns:** `boolean` - `true` if walkable

**Example:**
```lua
if Utils.isWalkable(newX, newY, world) then
  player.coord.x = newX
  player.coord.y = newY
end
```

---

### Utils.deepCopy(table)
Recursively copy a table.

**Parameters:**
- `table` (table): Table to copy

**Returns:** `table` - Deep copy

**Example:**
```lua
local playerCopy = Utils.deepCopy(player)
playerCopy.health = 999  -- Doesn't affect original
```

---

### Utils.shuffle(array)
Randomly shuffle array in-place.

**Parameters:**
- `array` (table): Array to shuffle

**Returns:** `table` - Shuffled array (same reference)

**Example:**
```lua
local deck = {1, 2, 3, 4, 5}
Utils.shuffle(deck)
```

---

## Module: Accessibility

**File:** `src/modules/accessibility.lua`  
**Purpose:** Accessibility features

### Accessibility.setColorblindMode(mode)
Enable colorblind-friendly palette.

**Parameters:**
- `mode` (string): `"deuteranopia"`, `"protanopia"`, `"tritanopia"`, or `"none"`

**Returns:** `nil`

**Example:**
```lua
Accessibility.setColorblindMode("deuteranopia")
```

---

### Accessibility.setReducedMotion(enabled)
Toggle reduced motion mode.

**Parameters:**
- `enabled` (boolean): Enable/disable

**Returns:** `nil`

**Side Effects:** Disables particles and screen shake when enabled

**Example:**
```lua
Accessibility.setReducedMotion(true)
```

---

### Accessibility.setHighContrast(enabled)
Toggle high contrast mode.

**Parameters:**
- `enabled` (boolean): Enable/disable

**Returns:** `nil`

**Example:**
```lua
Accessibility.setHighContrast(true)
```

---

### Accessibility.setFontSize(size)
Set UI font size.

**Parameters:**
- `size` (number): Font size in points (12-32)

**Returns:** `nil`

**Example:**
```lua
Accessibility.setFontSize(24)  -- Large text
```

---

## Module: Hazards

**File:** `src/modules/hazards.lua`  
**Purpose:** Environmental hazards and traps

### Hazards.init()
Initialize hazards module.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
Hazards.init()
```

---

### Hazards.addSpike(x, y, damage, cooldown)
Add spike trap to world.

**Parameters:**
- `x` (number): Grid X coordinate
- `y` (number): Grid Y coordinate
- `damage` (number): Damage per tick (default: 1)
- `cooldown` (number): Seconds between triggers (default: 0.5)

**Returns:** `table` - Created spike trap

**Example:**
```lua
Hazards.addSpike(10, 10, 2, 1.0)
```

---

### Hazards.addPressurePlate(x, y, duration)
Add pressure plate that activates nearby spikes.

**Parameters:**
- `x` (number): Grid X coordinate
- `y` (number): Grid Y coordinate
- `duration` (number): Activation duration (default: 3.0)

**Returns:** `table` - Created pressure plate

**Example:**
```lua
Hazards.addPressurePlate(5, 5, 5.0)
```

---

### Hazards.addTimedRoom(timerDuration)
Add timed room countdown.

**Parameters:**
- `timerDuration` (number): Seconds until instant death (default: 10.0)

**Returns:** `table` - Created timer

**Example:**
```lua
Hazards.addTimedRoom(15.0)  -- 15 seconds
```

---

### Hazards.addDarkZone(x, y, radius)
Add dark zone that reduces vision.

**Parameters:**
- `x` (number): Grid X coordinate
- `y` (number): Grid Y coordinate
- `radius` (number): Affected radius (default: 5)

**Returns:** `table` - Created dark zone

**Example:**
```lua
Hazards.addDarkZone(15, 15, 8)
```

---

### Hazards.update(dt, playerCoord)
Update all hazards for one frame.

**Parameters:**
- `dt` (number): Delta time in seconds
- `playerCoord` (table): Player position `{x, y}`

**Returns:** `number` - Damage dealt this frame, or -1 for timeout death

**Example:**
```lua
local damage = Hazards.update(dt, player.coord)
if damage > 0 then
  Combat.takeDamage(player, damage)
elseif damage == -1 then
  player.health = 0  -- Instant death
end
```

---

### Hazards.draw(wallSprite)
Render all hazards.

**Parameters:**
- `wallSprite` (Image): Wall sprite for dark zones

**Returns:** `nil`

**Example:**
```lua
Hazards.draw(sprites.wall)
```

---

### Hazards.drawTimedRoomUI()
Render timed room countdown UI.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
if hasTimedRoom then
  Hazards.drawTimedRoomUI()
end
```

---

## Module: Events

**File:** `src/modules/events.lua`  
**Purpose:** Event system / observer pattern

### Events.on(eventName, callback)
Register event listener.

**Parameters:**
- `eventName` (string): Event name (see `Events.GAME_EVENTS`)
- `callback` (function): Function to call when event triggers

**Returns:** `nil`

**Example:**
```lua
Events.on("KEY_COLLECTED", function(data)
  print("Collected key at", data.x, data.y)
end)
```

---

### Events.off(eventName, callback)
Unregister event listener.

**Parameters:**
- `eventName` (string): Event name
- `callback` (function): Previously registered callback

**Returns:** `boolean` - `true` if removed, `false` if not found

**Example:**
```lua
local myCallback = function(data) end
Events.on("DAMAGE", myCallback)
Events.off("DAMAGE", myCallback)
```

---

### Events.trigger(eventName, data)
Trigger event and notify all listeners.

**Parameters:**
- `eventName` (string): Event name
- `data` (table): Optional event data

**Returns:** `nil`

**Example:**
```lua
Events.trigger("PLAYER_DAMAGED", {
  damage = 2,
  source = "spike_trap"
})
```

---

### Events.GAME_EVENTS
Table of predefined event constants.

**Properties:**
```lua
Events.GAME_EVENTS = {
  -- Player events
  PLAYER_DAMAGED = "player_damaged",
  PLAYER_DEATH = "player_death",
  PLAYER_HEALED = "player_healed",
  
  -- Item events
  KEY_COLLECTED = "key_collected",
  ITEM_PICKED_UP = "item_picked_up",
  INVENTORY_FULL = "inventory_full",
  
  -- Combat events
  MONSTER_KILLED = "monster_killed",
  DAMAGE_DEALT = "damage_dealt",
  
  -- Level events
  LEVEL_COMPLETE = "level_complete",
  ROOM_ENTERED = "room_entered",
  
  -- Hazard events
  HAZARD_TRIGGERED = "hazard_triggered",
  SPIKE_DAMAGE = "spike_damage",
  
  -- Progression events
  UNLOCK_EARNED = "unlock_earned",
  RUN_STARTED = "run_started",
  RUN_ENDED = "run_ended"
}
```

---

## Module: StateMachine

**File:** `src/modules/statemachine.lua`  
**Purpose:** State management pattern

### State (Base Class)

#### State:new()
Create new state instance.

**Returns:** `table` - State object

**Example:**
```lua
local MenuState = State:new()
```

---

#### State:enter()
Called when state becomes active.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
function MenuState:enter()
  Audio.playMusic("menu_theme")
end
```

---

#### State:exit()
Called when leaving state.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
function MenuState:exit()
  Audio.stopMusic()
end
```

---

#### State:update(dt)
Update state logic.

**Parameters:**
- `dt` (number): Delta time

**Returns:** `nil`

**Example:**
```lua
function MenuState:update(dt)
  -- Handle input, update animations
end
```

---

#### State:draw()
Render state visuals.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
function MenuState:draw()
  love.graphics.print("Main Menu", 100, 100)
end
```

---

### StateMachine (Manager)

#### StateMachine:new()
Create state machine instance.

**Returns:** `table` - StateMachine object

**Example:**
```lua
local sm = StateMachine:new()
```

---

#### StateMachine:change(newState)
Switch to new state (replaces current).

**Parameters:**
- `newState` (State): State to switch to

**Returns:** `nil`

**Side Effects:** Calls `exit()` on old state, `enter()` on new state

**Example:**
```lua
sm:change(GameState)
```

---

#### StateMachine:push(newState)
Push state onto stack (for overlays like pause).

**Parameters:**
- `newState` (State): State to push

**Returns:** `nil`

**Example:**
```lua
sm:push(PauseState)  -- Game still in background
```

---

#### StateMachine:pop()
Remove top state from stack.

**Returns:** `State` - Popped state

**Example:**
```lua
sm:pop()  -- Resume game from pause
```

---

#### StateMachine:update(dt)
Update current/top state.

**Parameters:**
- `dt` (number): Delta time

**Returns:** `nil`

**Example:**
```lua
sm:update(dt)
```

---

#### StateMachine:draw()
Render current/all states in stack.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
sm:draw()
```

---

## Module: Progression

**File:** `src/modules/progression.lua`  
**Purpose:** Meta-progression and unlocks

### Progression.init()
Initialize progression module and load saved data.

**Parameters:** None  
**Returns:** `nil`

**Example:**
```lua
Progression.init()
```

---

### Progression.save()
Save progression data to disk.

**Parameters:** None  
**Returns:** `boolean` - `true` if successful

**Example:**
```lua
Progression.save()
```

---

### Progression.load()
Load progression data from disk.

**Parameters:** None  
**Returns:** `boolean` - `true` if data loaded, `false` if new save

**Example:**
```lua
if Progression.load() then
  print("Progress loaded!")
else
  print("Starting fresh")
end
```

---

### Progression.recordRun(won, deaths, keys, monsters, items, time)
Record completed run statistics.

**Parameters:**
- `won` (boolean): Whether player won
- `deaths` (number): Number of deaths in run
- `keys` (number): Keys collected
- `monsters` (number): Monsters killed
- `items` (number): Items picked up
- `time` (number): Run duration in seconds

**Returns:** `nil`

**Side Effects:** Updates stats, checks unlocks, saves data

**Example:**
```lua
Progression.recordRun(true, 2, 5, 10, 3, 125.5)
```

---

### Progression.checkUnlocks()
Check if any new unlocks have been earned.

**Parameters:** None  
**Returns:** `table` - Array of newly earned unlock names

**Example:**
```lua
local newUnlocks = Progression.checkUnlocks()
for _, unlock in ipairs(newUnlocks) do
  print("NEW UNLOCK:", unlock)
end
```

---

### Progression.hasUnlock(unlockName)
Check if specific unlock is earned.

**Parameters:**
- `unlockName` (string): Name of unlock (e.g., `"speed_boost_start"`)

**Returns:** `boolean` - `true` if unlocked

**Example:**
```lua
if Progression.hasUnlock("combat_master") then
  player.damage = player.damage * 2
end
```

---

### Progression.applyStartingUnlocks(world, effects)
Apply all unlocked starting bonuses to new run.

**Parameters:**
- `world` (table): World state to modify
- `effects` (table): Effects module reference

**Returns:** `nil`

**Side Effects:** Modifies player stats based on unlocks

**Example:**
```lua
function initGame()
  -- ... create world ...
  Progression.applyStartingUnlocks(world, Effects)
end
```

---

### Progression.getStats()
Get current progression statistics.

**Parameters:** None  
**Returns:** `table` - Stats object with `totalRuns`, `totalWins`, `totalDeaths`, etc.

**Example:**
```lua
local stats = Progression.getStats()
print("Total runs:", stats.totalRuns)
print("Win rate:", stats.totalWins / stats.totalRuns)
```

---

### Progression.data (Table)
Direct access to progression data (read-only recommended).

**Properties:**
```lua
Progression.data = {
  totalRuns = 0,
  totalWins = 0,
  totalDeaths = 0,
  totalKeys = 0,
  totalMonsters = 0,
  totalItems = 0,
  fastestTime = math.huge,
  unlocks = {
    speed_boost_start = false,
    invincibility_start = false,
    extra_inventory_slot = false,
    ghost_slow_start = false,
    map_reveal = false,
    combat_master = false,
    speed_runner = false,
    survivor = false
  },
  cosmetics = {}
}
```

---

## Config Constants

**File:** `src/config.lua`

### Window & Display
```lua
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
GRID_SIZE = 40
FULLSCREEN = false
VSYNC = true
```

### Player
```lua
PLAYER_SPEED = 200
PLAYER_HEALTH = 3
PLAYER_INVENTORY_SIZE = 3
PLAYER_BASE_DAMAGE = 1
PLAYER_VISION_RADIUS = 8
```

### Ghosts & AI
```lua
GHOST_PATROL_SPEED = 50
GHOST_CHASE_SPEED = 80
GHOST_VISION_RADIUS = 5
GHOST_ATTACK_DAMAGE = 1
GHOST_HEALTH = 1
```

### Hazards
```lua
HAZARDS_ENABLED = true
SPIKE_DAMAGE = 1
SPIKE_COOLDOWN = 0.5
PRESSURE_PLATE_DURATION = 3.0
TIMED_ROOM_DURATION = 10.0
DARK_ZONE_VISION_REDUCTION = 2
```

### Time Attack
```lua
TIME_ATTACK_MODE = true
PAR_TIMES = {300, 180, 120, 90}  -- Gold, Silver, Bronze, speedrun
SPEED_INCREASE_AMOUNT = 5
SPEED_INCREASE_INTERVAL = 30
TIME_BONUS_PER_ITEM = 5
```

### Combat & Effects
```lua
INVINCIBILITY_DURATION = 2.0
SCREEN_SHAKE_INTENSITY = 5
SCREEN_SHAKE_DECAY = 0.9
PARTICLE_LIFETIME = 1.0
MAX_PARTICLES = 100
```

### Accessibility
```lua
COLORBLIND_MODE = false
REDUCED_MOTION = false
HIGH_CONTRAST = false
FONT_SIZE = 16
SCREEN_READER = false
```

### Debug
```lua
DEBUG_MODE = false
DEBUG_SHOW_COLLISION = false
DEBUG_SHOW_PATHFINDING = false
DEBUG_GOD_MODE = false
DEBUG_INFINITE_INVENTORY = false
```

---

## Main Game Functions

**File:** `src/main.lua`

### love.load()
Initialize game (called once on startup).

**Parameters:** None  
**Returns:** `nil`

---

### love.update(dt)
Update game logic (called every frame).

**Parameters:**
- `dt` (number): Delta time in seconds

**Returns:** `nil`

---

### love.draw()
Render game (called every frame).

**Parameters:** None  
**Returns:** `nil`

---

### love.keypressed(key)
Handle key press events.

**Parameters:**
- `key` (string): Key name (e.g., `"space"`, `"w"`)

**Returns:** `nil`

---

### deserialize(mapString)
Parse map file string into world structure.

**Parameters:**
- `mapString` (string): Map file contents

**Returns:** `table` - World structure with `map`, `ghosts`, `keys`, `items`, `exits`, `hazards`

**Example:**
```lua
local mapData = love.filesystem.read("map/1.txt")
world = deserialize(mapData)
```

---

### initGame()
Reset game state for new run.

**Parameters:** None  
**Returns:** `nil`

**Side Effects:** Resets player, loads first map, initializes timers

---

### takeDamage(amount)
Apply damage to player.

**Parameters:**
- `amount` (number): Damage value

**Returns:** `nil`

**Side Effects:** Decrements health, triggers effects/events

---

### healPlayer(amount)
Restore player health.

**Parameters:**
- `amount` (number): Healing value

**Returns:** `nil`

**Example:**
```lua
healPlayer(1)
```

---

### giveItem(itemType)
Add item to player inventory.

**Parameters:**
- `itemType` (string): Item identifier

**Returns:** `boolean` - `true` if added, `false` if inventory full

**Example:**
```lua
if giveItem("speed_boost") then
  print("Got speed boost!")
end
```

---

### loadNextMap()
Load next level in sequence.

**Parameters:** None  
**Returns:** `boolean` - `true` if loaded, `false` if no more levels

**Example:**
```lua
if loadNextMap() then
  print("Level", currentLevel, "loaded")
else
  mode = "win"  -- Beat all levels
end
```

---

## Data Structures

### Player Entity
```lua
player = {
  coord = {x = number, y = number},
  speed = number,
  health = number,
  maxHealth = number,
  damage = number,
  state = string,  -- "idle", "moving", "attacking"
  invincibilityTimer = number,
  inventory = {
    {type = string, timer = number},
    -- ... up to PLAYER_INVENTORY_SIZE
  },
  sprite = Image
}
```

### Ghost Entity
```lua
ghost = {
  coord = {x = number, y = number},
  speed = number,
  health = number,
  visionRadius = number,
  attackDamage = number,
  state = string,  -- "PATROL", "CHASE", "ATTACK"
  sprite = Image
}
```

### World Structure
```lua
world = {
  map = {},  -- 2D array of strings
  ghosts = {},  -- Array of ghost entities
  keys = {},  -- Array of key positions {x, y}
  items = {},  -- Array of items {x, y, type}
  exits = {},  -- Array of exit positions {x, y}
  hazards = {
    spikes = {},
    pressurePlates = {},
    timedRooms = {},
    darkZones = {}
  }
}
```

---

## Examples

### Example: Custom Event Handler
```lua
local Events = require("modules.events")

Events.on("MONSTER_KILLED", function(data)
  print("Killed monster at", data.x, data.y)
  -- Award points
  player.score = player.score + 100
  -- Spawn loot
  spawnLoot(data.x, data.y)
end)
```

### Example: Pathfinding
```lua
local AI = require("modules.ai")

local path = AI.findPath(
  {x = ghost.coord.x, y = ghost.coord.y},
  {x = player.coord.x, y = player.coord.y},
  world
)

for i, step in ipairs(path) do
  print(string.format("Step %d: (%d, %d)", i, step.x, step.y))
end
```

### Example: Custom Particle
```lua
local Effects = require("modules.effects")

Effects.PARTICLE_TYPES.CUSTOM = {
  color = {0, 1, 1},  -- Cyan
  lifetime = 2.0,
  speed = 150,
  size = 12,
  gravity = 0
}

Effects.addParticle(x, y, "CUSTOM")
```

### Example: State Machine Usage
```lua
local StateMachine = require("modules.statemachine")
local State = require("modules.statemachine").State

local TitleState = State:new()
function TitleState:enter()
  print("Entered title screen")
end
function TitleState:update(dt)
  if love.keyboard.isDown("space") then
    sm:change(GameState)
  end
end

local sm = StateMachine:new()
sm:change(TitleState)

-- In love callbacks
function love.update(dt)
  sm:update(dt)
end

function love.draw()
  sm:draw()
end
```

---

## Version

**API Version:** 2.5.0  
**Last Updated:** 2024

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [LEVEL_DESIGN.md](LEVEL_DESIGN.md) - Map creation
- [MODDING.md](MODDING.md) - Extension guide
- [README.md](README.md) - User documentation

---

**Questions or missing documentation?** Please open an issue or contribute!
