# Tikrit Architecture Documentation

## Overview

Tikrit is a roguelike dungeon crawler built on the LÖVE2D game engine using Lua. The game follows a modular architecture with clear separation of concerns and event-driven communication.

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         main.lua (2622 lines)                   │
│                      Game Loop & Orchestration                  │
├─────────────────────────────────────────────────────────────────┤
│  Love2D Callbacks: load() | update(dt) | draw() | keypressed() │
│  Game Modes: title | game | win | lose | progressionScreen     │
│  Core State: world, player, effects, animations, timers         │
└─────────────────────────────────────────────────────────────────┘
                                    │
                  ┌─────────────────┴─────────────────┐
                  │                                   │
        ┌─────────▼──────────┐           ┌───────────▼──────────┐
        │   config.lua       │           │  modules/ (14 files) │
        │   Configuration    │           │   Game Systems       │
        └────────────────────┘           └──────────────────────┘
                                                      │
        ┌─────────────────────────────────────────────┴──────────────────┐
        │                                                                 │
        ▼                          ▼                          ▼          ▼
┌───────────────┐    ┌──────────────────┐    ┌──────────────┐  ┌─────────┐
│  ai.lua       │    │  combat.lua      │    │  procgen.lua │  │ ui.lua  │
│  Ghost AI     │    │  Combat System   │    │  Map Gen     │  │ Display │
└───────────────┘    └──────────────────┘    └──────────────┘  └─────────┘

┌───────────────┐    ┌──────────────────┐    ┌──────────────┐  ┌─────────┐
│ effects.lua   │    │  animation.lua   │    │  audio.lua   │  │utils.lua│
│ Visual FX     │    │  Sprite Anim     │    │  Sound SFX   │  │ Helpers │
└───────────────┘    └──────────────────┘    └──────────────┘  └─────────┘

┌───────────────┐    ┌──────────────────┐    ┌──────────────┐  ┌─────────┐
│ hazards.lua   │    │  events.lua      │    │statemachine  │  │progres- │
│ Environ Dmg   │    │  Event Bus       │    │.lua States   │  │sion.lua │
└───────────────┘    └──────────────────┘    └──────────────┘  └─────────┘

┌───────────────┐    ┌──────────────────┐
│accessibility  │    │                  │
│.lua A11y      │    │   (Reserved)     │
└───────────────┘    └──────────────────┘
```

## Module Descriptions

### 1. **main.lua** - Core Game Loop
**Lines:** 2622  
**Purpose:** Central orchestrator for all game systems

**Key Responsibilities:**
- Love2D callback implementations (`load`, `update`, `draw`, `keypressed`)
- Game mode management (title, game, win, lose, progressionScreen)
- World state management (entities, player, effects)
- Map file loading and parsing
- Game loop timing and delta time

**Critical Functions:**
- `love.load()` - Initialization (load config, sprites, maps, audio)
- `love.update(dt)` - Game state updates (player, ghosts, effects, timers)
- `love.draw()` - Rendering pipeline (world, entities, UI, effects)
- `deserialize(mapString)` - Parse map files into world structure
- `initGame()` - Reset game state for new run

**State Variables:**
```lua
player = { coord = {x, y}, speed, health, state, inventory }
world = { map, ghosts, keys, items, exits, hazards }
effects = { particles, screen shake, damage indicators }
animations = { sprites, timers, frame counters }
timers = { invincibility, combat, hazards, time attack }
```

### 2. **config.lua** - Configuration Hub
**Lines:** 200+  
**Purpose:** Centralized configuration and constants

**Configuration Categories:**
```lua
-- Core Game
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
GRID_SIZE = 40
INITIAL_MAP_INDEX = 1

-- Player Stats
PLAYER_SPEED = 200
PLAYER_HEALTH = 3
PLAYER_INVENTORY_SIZE = 3
PLAYER_BASE_DAMAGE = 1

-- Ghost AI
GHOST_PATROL_SPEED = 50
GHOST_CHASE_SPEED = 80
GHOST_VISION_RADIUS = 5
GHOST_ATTACK_DAMAGE = 1

-- Hazards & Environmental
HAZARDS_ENABLED = true
SPIKE_DAMAGE = 1
PRESSURE_PLATE_DURATION = 3.0
TIMED_ROOM_DURATION = 10.0
DARK_ZONE_VISION_REDUCTION = 2

-- Time Attack
TIME_ATTACK_MODE = true
PAR_TIMES = { 300, 180, 120, 90 }
SPEED_INCREASE_AMOUNT = 5
SPEED_INCREASE_INTERVAL = 30

-- Combat & Effects
INVINCIBILITY_DURATION = 2.0
SCREEN_SHAKE_INTENSITY = 5
PARTICLE_LIFETIME = 1.0

-- Accessibility
COLORBLIND_MODE = false
REDUCED_MOTION = false
HIGH_CONTRAST = false
```

**Design Philosophy:**
- Single source of truth for all magic numbers
- Easy difficulty tuning without code changes
- Feature toggles for optional systems
- Clear categorization for maintainability

### 3. **ai.lua** - Ghost Artificial Intelligence
**Lines:** ~150  
**Purpose:** Enemy behavior and pathfinding

**AI States:**
- **PATROL:** Random wandering, low speed
- **CHASE:** Follow player when in vision radius
- **ATTACK:** Close-range damage on contact
- **FLEE:** (Optional) Retreat when player has power-up

**Key Functions:**
```lua
AI.update(ghost, playerCoord, dt)
  └─> Check vision radius
      ├─> Player visible? → CHASE state
      └─> Player hidden? → PATROL state

AI.findPath(start, goal, world)
  └─> A* pathfinding on world grid
      └─> Returns array of coordinates

AI.handleCollision(ghost, player)
  └─> Deal damage if player vulnerable
      └─> Trigger invincibility timer
```

**Vision System:**
- Line-of-sight checks using raycasting
- Configurable vision radius (default: 5 tiles)
- Blocked by walls, not affected by dark zones

### 4. **combat.lua** - Combat System
**Lines:** ~120  
**Purpose:** Damage calculation and combat mechanics

**Combat Flow:**
```lua
Combat.attack(attacker, target)
  └─> Calculate damage (base + modifiers)
      ├─> Apply weapon bonuses
      ├─> Apply unlocked perks (Combat Master: 2x)
      └─> Trigger visual effects
          ├─> Screen shake
          ├─> Damage particles
          └─> Audio feedback

Combat.takeDamage(entity, amount)
  └─> Reduce health
      ├─> Check invincibility frames
      ├─> Apply damage reduction
      └─> Trigger death if health <= 0
```

**Invincibility Frames:**
- Default: 2.0 seconds after taking damage
- Visual feedback: Sprite flashing
- Unlockable: 3s invincibility at start (progression)

### 5. **procgen.lua** - Procedural Generation
**Lines:** ~180  
**Purpose:** Dynamic map generation algorithms

**Generation Pipeline:**
```lua
Procgen.generateDungeon(width, height, difficulty)
  └─> 1. Generate rooms (Binary Space Partitioning)
      └─> 2. Connect rooms (corridors)
          └─> 3. Place entities (start, exits, enemies)
              └─> 4. Add items & keys (balanced loot)
                  └─> 5. Add hazards (difficulty scaled)
```

**Room Types:**
- **Start Room:** Always safe, player spawn
- **Key Room:** Locked door, contains golden key
- **Item Room:** Power-ups and equipment
- **Enemy Room:** Ghost patrols, combat challenge
- **Boss Room:** (Planned) End-of-level challenge
- **Exit Room:** Stairs to next level

**Difficulty Scaling:**
- More enemies at higher levels
- Reduced item spawn rates
- Increased hazard density
- Faster ghost speeds

### 6. **ui.lua** - User Interface
**Lines:** 365  
**Purpose:** All screen rendering and menus

**Screen Types:**
```lua
UI.drawTitleScreen()      -- Main menu
UI.drawGameScreen()       -- HUD during gameplay
UI.drawWinScreen()        -- Victory display
UI.drawLoseScreen()       -- Game over
UI.drawProgressionScreen() -- Unlocks & stats
```

**HUD Elements:**
- Health hearts (top-left)
- Key count with icon
- Inventory slots (bottom)
- Timer (time attack mode)
- Minimap (with unlocks)
- Boss health bar (when active)

**Accessibility Features:**
- High contrast mode
- Colorblind palette
- Large text option
- Reduced motion toggle

### 7. **effects.lua** - Visual Effects
**Lines:** ~200  
**Purpose:** Particle systems and screen effects

**Effect Types:**
```lua
Effects.screenShake(intensity, duration)
  └─> Offset camera with decay

Effects.addParticle(x, y, type)
  ├─> BLOOD (red, combat)
  ├─> SPARKLE (yellow, pickup)
  ├─> DUST (gray, movement)
  └─> EXPLOSION (orange, death)

Effects.damageIndicator(x, y, amount)
  └─> Floating text with damage number

Effects.flashSprite(sprite, duration)
  └─> Opacity flicker for invincibility
```

**Performance:**
- Particle pool (max 100 active)
- Automatic cleanup after lifetime
- Configurable particle density

### 8. **animation.lua** - Sprite Animation
**Lines:** ~100  
**Purpose:** Frame-based sprite animations

**Animation System:**
```lua
Animation.create(spritesheet, frames, fps)
  └─> Returns animation table

Animation.update(anim, dt)
  └─> Advance frame counter
      └─> Loop or hold last frame

Animation.draw(anim, x, y, flip)
  └─> Render current frame
```

**Sprite Sheets:**
- Player: 4 directions × 2 frames
- Ghost: 2 frames (float animation)
- Items: Static sprites
- Effects: 8-frame particle loops

### 9. **audio.lua** - Sound Effects & Music
**Lines:** ~80  
**Purpose:** Audio playback and management

**Audio Categories:**
- **SFX:** Damage, pickup, door, footstep
- **Music:** Title, gameplay, boss, victory
- **Ambient:** Wind, drips, echoes

**Volume Controls:**
```lua
Audio.setMasterVolume(0.0 - 1.0)
Audio.setMusicVolume(0.0 - 1.0)
Audio.setSFXVolume(0.0 - 1.0)
```

### 10. **utils.lua** - Helper Functions
**Lines:** ~120  
**Purpose:** Reusable utility functions

**Key Functions:**
```lua
Utils.distance(x1, y1, x2, y2)
  └─> Euclidean distance

Utils.clamp(value, min, max)
  └─> Constrain value to range

Utils.gridToPixel(gridX, gridY)
  └─> Convert tile coords to screen coords

Utils.isWalkable(x, y, world)
  └─> Check if tile is passable

Utils.deepCopy(table)
  └─> Recursive table duplication
```

### 11. **accessibility.lua** - Accessibility Features
**Lines:** ~150  
**Purpose:** Inclusive design options

**Features:**
- **Colorblind Modes:** Deuteranopia, Protanopia, Tritanopia
- **Screen Reader Support:** Text descriptions for visuals
- **Input Remapping:** Custom keybindings
- **Reduced Motion:** Disable particles and shake
- **High Contrast:** Enhanced visibility
- **Font Scaling:** Adjustable text size

### 12. **hazards.lua** - Environmental Hazards
**Lines:** 280  
**Purpose:** Non-combat damage sources

**Hazard Types:**
```lua
SPIKE_TRAP (^)
  └─> Periodic damage (1 HP every 0.5s)
      └─> Cooldown: 2s between triggers

PRESSURE_PLATE (P)
  └─> Activates when stepped on
      └─> Triggers spikes in radius

TIMED_ROOM (T)
  └─> 10-second countdown
      └─> Instant death on timeout

DARK_ZONE (D)
  └─> Reduces vision radius by 2
      └─> No direct damage
```

**Integration:**
- Map symbols deserialized in `main.lua`
- Updated each frame in game loop
- Visual indicators (UI and sprites)

### 13. **events.lua** - Event System
**Lines:** 115  
**Purpose:** Decoupled communication via observer pattern

**Event Bus:**
```lua
Events.on(eventName, callback)
  └─> Register listener

Events.off(eventName, callback)
  └─> Unregister listener

Events.trigger(eventName, data)
  └─> Notify all listeners
```

**Game Events:**
```lua
Events.GAME_EVENTS = {
  KEY_COLLECTED = "key_collected",
  ITEM_PICKED_UP = "item_picked_up",
  MONSTER_KILLED = "monster_killed",
  PLAYER_DAMAGED = "player_damaged",
  PLAYER_DEATH = "player_death",
  LEVEL_COMPLETE = "level_complete",
  ROOM_ENTERED = "room_entered",
  HAZARD_TRIGGERED = "hazard_triggered",
  UNLOCK_EARNED = "unlock_earned",
  -- ... 20+ events total
}
```

**Benefits:**
- Loose coupling between systems
- Easy addition of new features
- Debug/logging capabilities
- Achievement tracking

### 14. **statemachine.lua** - State Management
**Lines:** 135  
**Purpose:** Professional state machine framework

**Base State Class:**
```lua
State = {}
function State:new() end
function State:enter() end
function State:exit() end
function State:update(dt) end
function State:draw() end
```

**State Machine Manager:**
```lua
StateMachine = {}
function StateMachine:new() end
function StateMachine:change(newState) end
function StateMachine:push(newState) end   -- Stack for pause
function StateMachine:pop() end             -- Resume
function StateMachine:update(dt) end
function StateMachine:draw() end
```

**Use Cases:**
- Menu navigation (title → game → win)
- Pause overlay (stack-based)
- Ghost AI states (patrol → chase → attack)

### 15. **progression.lua** - Meta-Progression
**Lines:** 275  
**Purpose:** Persistent unlocks across runs

**Progression Data:**
```lua
Progression.data = {
  totalRuns = 0,
  totalWins = 0,
  totalDeaths = 0,
  totalKeys = 0,
  totalMonsters = 0,
  totalItems = 0,
  fastestTime = math.huge,
  unlocks = {}, -- 8 unlocks
  cosmetics = {} -- Future: skins
}
```

**Unlock Tiers:**
1. **Speed Boost Start** (5 runs): +50 speed
2. **Invincibility Start** (10 runs): 3s protection
3. **Extra Inventory Slot** (15 runs): 4 items
4. **Ghost Slow Start** (20 runs): enemies slower
5. **Map Reveal** (3 wins): +3 vision radius
6. **Combat Master** (5 wins): 2x damage
7. **Speed Runner** (sub-2min): +100 speed
8. **Survivor** (50 deaths): extra life

**Persistence:**
```lua
Progression.save()
  └─> Write progression.txt with custom format
      └─> love.filesystem.write()

Progression.load()
  └─> Read progression.txt
      └─> Parse custom format
          └─> Validate and populate data
```

## Data Flow

### Game Loop Flow
```
love.load()
  └─> Load config, assets, progression
      └─> Initialize game state
          └─> Set mode = "title"

love.update(dt)
  └─> Branch by game mode:
      ├─> title: Check input
      ├─> game:
      │   ├─> Update player input & movement
      │   ├─> Update AI (ghosts)
      │   ├─> Update hazards & timers
      │   ├─> Update effects & animations
      │   ├─> Check win/lose conditions
      │   └─> Trigger events
      ├─> win: Show stats, check unlocks
      ├─> lose: Show stats, record run
      └─> progressionScreen: Display unlocks

love.draw()
  └─> Branch by game mode:
      ├─> title: UI.drawTitleScreen()
      ├─> game:
      │   ├─> Draw world grid
      │   ├─> Draw entities (player, ghosts)
      │   ├─> Draw items & keys
      │   ├─> Draw hazards
      │   ├─> Draw effects & particles
      │   └─> Draw HUD (UI.drawGameScreen())
      ├─> win: UI.drawWinScreen()
      ├─> lose: UI.drawLoseScreen()
      └─> progressionScreen: UI.drawProgressionScreen()
```

### Event Flow Example
```
Player collects key:
  1. main.lua detects collision
  2. Events.trigger("KEY_COLLECTED", keyData)
  3. Listeners respond:
     ├─> UI updates key counter
     ├─> Audio plays pickup sound
     ├─> Effects spawns particle
     ├─> Progression increments totalKeys
     └─> Achievement checks unlock
```

## File Organization

```
tikrit/
├── src/
│   ├── main.lua                 -- Entry point, game loop
│   ├── config.lua               -- Configuration constants
│   ├── modules/
│   │   ├── ai.lua               -- Ghost AI
│   │   ├── combat.lua           -- Combat system
│   │   ├── procgen.lua          -- Map generation
│   │   ├── ui.lua               -- UI rendering
│   │   ├── effects.lua          -- Visual effects
│   │   ├── animation.lua        -- Sprite animation
│   │   ├── audio.lua            -- Sound management
│   │   ├── utils.lua            -- Helper functions
│   │   ├── accessibility.lua    -- A11y features
│   │   ├── hazards.lua          -- Environmental damage
│   │   ├── events.lua           -- Event bus
│   │   ├── statemachine.lua     -- State management
│   │   └── progression.lua      -- Meta-progression
│   ├── sprite/                  -- Image assets
│   ├── sound/                   -- Audio files
│   └── font/                    -- Custom fonts
├── map/
│   ├── 1.txt, 2.txt, ...        -- Level definitions
│   ├── 1-fresh.txt, ...         -- Original backups
│   └── layout.txt               -- Map format guide
├── asset/                       -- Documentation images
├── ARCHITECTURE.md              -- This file
├── LEVEL_DESIGN.md              -- Map creation guide
├── MODDING.md                   -- Extension guide
├── API.md                       -- Function reference
├── README.md                    -- User documentation
├── CHANGELOG.md                 -- Version history
├── DISTRIBUTION.md              -- Build instructions
├── makefile                     -- Build automation
├── build.sh                     -- Interactive build script
└── VERSION                      -- Current version
```

## Design Patterns

### 1. **Module Pattern**
All systems are encapsulated in module tables:
```lua
local ModuleName = {}

function ModuleName.init()
  -- Setup
end

function ModuleName.update(dt)
  -- Per-frame logic
end

return ModuleName
```

### 2. **Observer Pattern**
Event system for decoupled communication:
```lua
Events.on("PLAYER_DAMAGED", function(data)
  Audio.play("damage")
  Effects.screenShake(5, 0.2)
end)
```

### 3. **State Pattern**
State machine for complex behaviors:
```lua
local MenuState = State:new()
function MenuState:enter()
  Audio.play("menu_music")
end
function MenuState:update(dt)
  -- Menu logic
end
```

### 4. **Object Pool**
Reusable particle objects:
```lua
Effects.particlePool = {}
Effects.getParticle()  -- Recycle or create
Effects.releaseParticle(particle)  -- Return to pool
```

### 5. **Configuration Over Code**
Tuning via `config.lua` instead of hardcoded values:
```lua
-- BAD
local speed = 200

-- GOOD
local speed = config.PLAYER_SPEED
```

## Performance Considerations

### Optimization Strategies

1. **Spatial Partitioning:**
   - Grid-based collision detection
   - Only check nearby tiles for walkability
   - Vision radius limits AI calculations

2. **Object Pooling:**
   - Reuse particle objects
   - Avoid frequent table allocations
   - Preallocate animation frames

3. **Lazy Evaluation:**
   - Only pathfind when ghost is chasing
   - Skip AI updates for off-screen ghosts
   - Defer effect cleanup until batch

4. **Delta Time:**
   - All movement uses `dt` for frame independence
   - Timers count down each frame
   - Smooth animations regardless of FPS

### Profiling Targets
- Keep update cycle under 16ms (60 FPS)
- Minimize garbage collection spikes
- Batch draw calls for sprites

## Extension Points

### Adding New Systems

1. **Create Module:**
   ```lua
   -- src/modules/newsystem.lua
   local NewSystem = {}
   function NewSystem.init() end
   function NewSystem.update(dt) end
   return NewSystem
   ```

2. **Require in main.lua:**
   ```lua
   local NewSystem = require("modules.newsystem")
   ```

3. **Initialize in love.load():**
   ```lua
   NewSystem.init()
   ```

4. **Call in love.update(dt):**
   ```lua
   NewSystem.update(dt)
   ```

### Adding New Events

1. **Define in events.lua:**
   ```lua
   Events.GAME_EVENTS.NEW_EVENT = "new_event"
   ```

2. **Trigger in game logic:**
   ```lua
   Events.trigger("new_event", { data = value })
   ```

3. **Listen in modules:**
   ```lua
   Events.on("new_event", function(data)
     -- Handle event
   end)
   ```

## Testing Strategy

### Manual Testing
- Playtest each level for balance
- Verify all unlocks are earnable
- Test edge cases (0 health, full inventory)

### Automated Testing (Planned #24)
- Unit tests for utility functions
- Integration tests for combat
- Pathfinding validation
- Procgen consistency checks

### Debug Mode
Toggle in `config.lua`:
```lua
DEBUG_MODE = true
DEBUG_SHOW_COLLISION = true
DEBUG_SHOW_PATHFINDING = true
DEBUG_GOD_MODE = true
```

## Build Pipeline

See [DISTRIBUTION.md](DISTRIBUTION.md) for full details.

**Quick Build:**
```bash
make release  # Creates .love, .app, .exe
```

**Targets:**
- `make love-file` - Cross-platform .love
- `make macos` - macOS .app bundle
- `make windows` - Windows .exe (requires wine)
- `make linux` - Linux AppImage

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed history.

**Current:** v2.5.0  
**Major Milestones:**
- v1.0.0 - Initial release (basic gameplay)
- v2.0.0 - Procedural generation
- v2.5.0 - Meta-progression, hazards, events

## Contributing

1. Read this architecture doc
2. Check [MODDING.md](MODDING.md) for guidelines
3. Follow existing code style
4. Test thoroughly before submitting
5. Update documentation for new features

## License

See main README.md for license information.

---

**Last Updated:** 2024 (v2.5.0)  
**Maintainer:** [Your Name]  
**Documentation:** Complete system architecture reference
