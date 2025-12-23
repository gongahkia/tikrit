# Tikrit Level Design Guide

## Overview

This document explains how to create, modify, and balance levels for Tikrit. Whether you're creating new maps or tweaking existing ones, this guide covers the map format, design principles, and best practices.

## Map File Format

### Location
All map files are stored in the `map/` directory:
```
map/
├── 1.txt, 2.txt, 3.txt, ...      -- Active level files
├── 1-fresh.txt, 2-fresh.txt, ... -- Original backups
└── layout.txt                    -- Format reference
```

### File Naming Convention
- **Active maps:** `1.txt`, `2.txt`, `3.txt`, etc.
- **Backups:** `1-fresh.txt`, `2-fresh.txt`, etc. (pristine copies)
- **Level order:** Numbered sequentially from 1 to 15

### Basic Structure

A level file is a plain text grid where each character represents a tile:

```
########################
#          @           #
# ###### ##### ####### #
# #    # #   # #     # #
# # ## # # # # # ### # #
# # #G # # # # # #k# # #
# # ## # # # # # ### # #
# #    # #   # #     # #
# ###### ##### ####### #
#          E           #
########################
```

### Symbol Reference

#### Core Symbols (Required)
| Symbol | Name | Description | Quantity |
|--------|------|-------------|----------|
| `#` | Wall | Impassable barrier | Many |
| `.` | Floor | Walkable empty space | Many |
| `@` | Player Start | Spawn location | Exactly 1 |
| `E` | Exit | Level completion | At least 1 |
| `k` | Golden Key | Required for exit | 1-3 |
| `G` | Ghost Enemy | Patrol/chase AI | 0-10 |

#### Items & Power-ups
| Symbol | Name | Effect | Rarity |
|--------|------|--------|--------|
| `H` | Health Potion | +1 HP | Common |
| `S` | Speed Boost | +50 speed (30s) | Uncommon |
| `I` | Invincibility | Immune (5s) | Rare |
| `M` | Map Reveal | +5 vision radius | Uncommon |
| `W` | Weapon Upgrade | +1 damage | Rare |

#### Environmental Hazards (Optional)
| Symbol | Name | Effect | Damage |
|--------|------|--------|--------|
| `^` | Spike Trap | Periodic damage | 1 HP/0.5s |
| `P` | Pressure Plate | Activates nearby spikes | Trigger |
| `T` | Timed Room | 10s countdown to death | Instant |
| `D` | Dark Zone | Vision radius -2 | 0 HP |

#### Special Tiles (Future)
| Symbol | Name | Effect | Status |
|--------|------|--------|--------|
| `B` | Boss Arena | End-of-level fight | Planned |
| `L` | Locked Door | Requires key | Planned |
| `X` | Breakable Wall | Destructible | Planned |
| `$` | Treasure | Bonus loot | Planned |

### Whitespace Rules
- Spaces (` `) are treated as **floor tiles** (walkable)
- **No tabs** - use spaces only
- Each line must have the same width (rectangular grid)
- Trailing spaces are significant

### Example: Minimal Level
```
##########
#@      k#
#  ####  #
#  #G #  #
#  ####  #
#       E#
##########
```
**Description:**
- 10×7 grid (small, simple)
- Player (`@`) at top-left
- Ghost (`G`) in center room
- Key (`k`) at top-right
- Exit (`E`) at bottom-right
- Walls (`#`) form outer border + inner room

### Example: Hazard-Rich Level
```
###################
#@    ^   ^   ^  k#
# ### # ### # ### #
# #P# # #T# # #P# #
# ### # ### # ### #
#   ^   G   ^     #
# ### ### ### ### #
# # # #D# #D# # # #
# # # ### ### # # #
#   ^   ^   ^    E#
###################
```
**Description:**
- Spike traps (`^`) force careful movement
- Pressure plates (`P`) activate nearby spikes
- Timed room (`T`) creates urgency
- Dark zones (`D`) limit vision
- Ghost (`G`) patrols center

## Design Principles

### 1. **Progressive Difficulty**
Each level should be slightly harder than the previous:

**Early Levels (1-5):**
- Few enemies (1-2 ghosts)
- Ample space for maneuvering
- Obvious key/exit placement
- Minimal hazards

**Mid Levels (6-10):**
- More enemies (3-5 ghosts)
- Tighter corridors
- Hidden keys behind obstacles
- Moderate hazard density

**Late Levels (11-15):**
- Many enemies (6-10 ghosts)
- Complex mazes
- Multiple keys required
- Heavy hazard use
- Environmental challenges

### 2. **Player Agency**
Give players meaningful choices:

**Good:**
- Multiple paths to the key
- Risk/reward shortcuts (hazards for speed)
- Optional item rooms (detours)

**Bad:**
- Linear hallways (boring)
- Forced damage (unavoidable hazards)
- Dead ends with no loot

### 3. **Fair Challenge**
Difficulty should come from skill, not RNG:

**Fair:**
- Visible hazards with tells
- Enemies in predictable patterns
- Health potions near tough sections

**Unfair:**
- Instant death traps without warning
- Impossible enemy density
- No recovery opportunities

### 4. **Visual Clarity**
Players should understand the space:

**Clear:**
- Wide corridors (3+ tiles)
- Distinct rooms with purpose
- Landmarks for orientation

**Confusing:**
- 1-tile-wide mazes
- Identical repeating patterns
- No visual flow

### 5. **Pacing**
Alternate between action and exploration:

**Good Flow:**
1. Safe starting area (plan)
2. Combat encounter (action)
3. Puzzle section (think)
4. Item reward (satisfaction)
5. Boss/exit (climax)

**Bad Flow:**
- Constant combat (exhausting)
- Pure maze (tedious)
- Instant access to exit (trivial)

## Room Archetypes

### 1. **Starting Room**
- **Purpose:** Safe spawn, orient player
- **Size:** Medium (5×5 to 8×8)
- **Enemies:** None
- **Items:** 1 health potion (tutorial)
- **Exits:** 1-2 corridors

**Example:**
```
#########
#H      #
#   @   #
#       #
###   ###
```

### 2. **Combat Room**
- **Purpose:** Enemy encounter
- **Size:** Medium (6×6 to 10×10)
- **Enemies:** 2-4 ghosts
- **Items:** Health after fight
- **Layout:** Cover + open space

**Example:**
```
###########
# G ### G #
#   # #   #
# ### ### #
#    H    #
###     ###
```

### 3. **Key Room**
- **Purpose:** Required objective
- **Size:** Small to Medium (4×4 to 8×8)
- **Enemies:** 1 guardian ghost
- **Items:** Just the key
- **Challenge:** Guarded or trapped

**Example:**
```
#########
# ##### #
# #k#G# #
# ##### #
#       #
###   ###
```

### 4. **Treasure Room**
- **Purpose:** Optional loot
- **Size:** Small (4×4 to 6×6)
- **Enemies:** None or weak
- **Items:** 2-3 power-ups
- **Access:** Hidden or risky path

**Example:**
```
#######
#H S M#
# ### #
# ### #
#######
```

### 5. **Maze Section**
- **Purpose:** Navigation challenge
- **Size:** Large (12×12+)
- **Enemies:** Scattered ghosts
- **Items:** Breadcrumb trail
- **Layout:** Multiple paths, loops

**Example:**
```
###############
# #   #   # G #
# # # # # ### #
#   # # #   # #
### # # ### # #
#k  #       # #
###############
```

### 6. **Boss Arena**
- **Purpose:** Climactic fight
- **Size:** Large (10×10+)
- **Enemies:** Boss + adds
- **Items:** Health at edges
- **Layout:** Open with pillars

**Example (Planned):**
```
###############
#H           H#
#   #  B  #   #
#   #     #   #
#   #######   #
#             #
#   #######   #
#H           H#
###############
```

### 7. **Hazard Gauntlet**
- **Purpose:** Precision challenge
- **Size:** Long corridor (20+ tiles)
- **Enemies:** Few or none
- **Items:** Reward at end
- **Layout:** Spike patterns

**Example:**
```
#####################
#@ ^ ^ ^ ^ ^ ^ ^   H#
#####################
```

### 8. **Exit Room**
- **Purpose:** Level completion
- **Size:** Medium (6×6 to 8×8)
- **Enemies:** Final challenge or safe
- **Items:** None
- **Access:** Requires all keys

**Example:**
```
#########
#       #
#   E   #
#       #
#########
```

## Balancing Guidelines

### Enemy Placement

**Quantity by Level:**
- **Easy (1-5):** 1-3 ghosts
- **Medium (6-10):** 4-6 ghosts
- **Hard (11-15):** 7-10 ghosts

**Placement Rules:**
1. **No spawn camping:** Keep ghosts away from player start
2. **Line of sight:** Players should see enemies before engagement
3. **Escape routes:** Always provide a way to flee
4. **Patrol patterns:** Place in corridors for predictable movement

**Good Placement:**
```
#########
#@      #
#  ####G#  ← Ghost patrols away from spawn
#       #
#########
```

**Bad Placement:**
```
#########
#@G     #  ← Ghost immediately next to spawn
#       #
#########
```

### Item Distribution

**Health Potions:**
- 1 per level minimum
- Near tough encounters
- Before boss rooms

**Power-ups:**
- 0-2 per level
- Hidden or guarded
- Reward exploration

**Keys:**
- 1 key per level (standard)
- 2-3 keys for complex levels
- Hidden but discoverable

### Hazard Density

**Sparse (Easy):**
- 0-3 hazards per level
- Clearly telegraphed
- Easy to avoid

**Moderate (Medium):**
- 4-8 hazards per level
- Some require timing
- Punishment for carelessness

**Dense (Hard):**
- 9+ hazards per level
- Overlapping dangers
- Precision required

**Never:**
- Place hazards in starting room
- Block the only path with unavoidable damage
- Use instant-death hazards without warning

### Space Allocation

**Recommended Proportions:**
- **40% corridors:** Movement/transit
- **30% rooms:** Encounters/challenges
- **20% walls:** Structure/boundaries
- **10% open areas:** Combat arenas

**Minimum Corridor Width:** 3 tiles (allows turning)  
**Maximum Room Size:** 15×15 (prevents getting lost)  
**Wall Thickness:** 1 tile (performance)

## Step-by-Step: Creating a New Level

### Step 1: Plan on Paper
Sketch the layout before typing:
```
[Drawing of level]
- Start: Top-left
- Key: Behind maze
- Exit: Bottom-right
- Ghosts: 3 (patrolling corridors)
- Items: Health in center, speed boost in hidden room
```

### Step 2: Create Grid
Start with a border:
```
####################
#                  #
#                  #
#                  #
#                  #
####################
```

### Step 3: Add Player & Exit
Place required elements:
```
####################
#@                 #
#                  #
#                  #
#                 E#
####################
```

### Step 4: Build Structure
Add walls to create rooms:
```
####################
#@        #        #
#  ####   #   #### #
#  #      #      # #
#  #      #      #E#
####################
```

### Step 5: Add Objectives
Place keys and items:
```
####################
#@   H    #    k   #
#  ####   #   #### #
#  #  S   #      # #
#  #      #      #E#
####################
```

### Step 6: Add Enemies
Strategically place ghosts:
```
####################
#@   H    #    k   #
#  ####   #   #### #
#  #  S  G#  G   # #
#  #      #      #E#
####################
```

### Step 7: Add Hazards (Optional)
Increase difficulty:
```
####################
#@   H    #    k   #
#  ####  ^#^  #### #
#  #  S  G#  G   # #
#  #     ^#^     #E#
####################
```

### Step 8: Playtest
1. Save the file as `map/16.txt` (next number)
2. Update `config.lua` if needed:
   ```lua
   TOTAL_LEVELS = 16  -- Increment
   ```
3. Launch the game and test:
   - Can you beat it?
   - Is it fun?
   - Is the difficulty appropriate?
4. Iterate based on feedback

### Step 9: Polish
- Ensure symmetry or intentional asymmetry
- Add visual interest (patterns in walls)
- Check for unreachable areas
- Verify all symbols are correct

## Common Mistakes

### ❌ **Mistake 1: Unwinnable Levels**
**Problem:** Key behind locked door, no way to proceed
```
#########
#@      #
# ##### #
# #k#L# #  ← Key behind door that needs key
# ##### #
#######E#
```
**Fix:** Always provide a path to all required items

### ❌ **Mistake 2: Instant Death Traps**
**Problem:** Unavoidable damage on spawn
```
#########
#@^^^^^^#  ← Spikes everywhere
#^^^^^^^#
#######E#
```
**Fix:** Hazards should be avoidable with skill

### ❌ **Mistake 3: Boring Hallways**
**Problem:** Long, empty corridors
```
#########
#@      #
#       #
#       #
#       #
#      E#
#########
```
**Fix:** Add encounters, items, or branching paths

### ❌ **Mistake 4: Impossible Enemy Density**
**Problem:** Too many ghosts in small space
```
#########
#@GGGGG #
# GGGGG #
# GGGGkE#
#########
```
**Fix:** Scale enemies to room size and player skill

### ❌ **Mistake 5: No Visual Flow**
**Problem:** Identical repeating rooms
```
###################
# # # # # # # # # #
# # # # # # # # # #
###################
```
**Fix:** Create distinct landmarks and varied spaces

## Advanced Techniques

### 1. **Branching Paths**
Offer player choice:
```
#####################
#@        #         #
#  ####   #   ####  #
#  #H #   #   # S#  #  ← Two paths
#  ####   #   ####  #
#        k#         #
#####################
      #######
      #  E  #
      #######
```

### 2. **Risk/Reward Shortcuts**
Optional dangerous paths:
```
#####################
#@  (safe path)    E#
###################^#
     #k# (shortcut, but spikes)
     ^^^
```

### 3. **Environmental Storytelling**
Suggest narrative through layout:
```
#####################
#@  (prison cells)   #
# ### ### ### ###   #
# #G# #G# #G# #G#   #  ← Escaped prisoners
# ### ### ### ###   #
#       (exit)      E#
#####################
```

### 4. **Dynamic Difficulty**
Use config-driven spawns:
```lua
-- In config.lua
if DIFFICULTY == "hard" then
  GHOST_COUNT = 8
else
  GHOST_COUNT = 3
end
```

### 5. **Secret Areas**
Hidden rooms with rewards:
```
#####################
#@                  #
# ################# #
# #   (hidden)   #  #
# #   H  S  M    #  #
# ################# #
#                  E#
#####################
```

## Testing Checklist

Before finalizing a level, verify:

- [ ] **Completable:** Can be beaten with starting stats
- [ ] **Fair:** No unavoidable damage or soft locks
- [ ] **Balanced:** Difficulty matches level number
- [ ] **Interesting:** Has variety (not just hallways)
- [ ] **Readable:** Symbols are correct, no typos
- [ ] **Performance:** No lag (keep under 20×20 if possible)
- [ ] **Fun:** Playtest confirms enjoyment

## Level Templates

### Template 1: Simple Combat
```
###############
#@           H#
#  #########  #
#  #   G   #  #
#  # ##### #  #
#  # #k# # #  #
#  # ### # #  #
#  #  G  # #  #
#  ####### #  #
#         E   #
###############
```

### Template 2: Maze Challenge
```
#####################
#@# # # # # # # # # #
# # # # # # # # # #k#
#   #   #   #   #   #
# ### ### ### ### # #
#   #   #   #   #   #
# # # # # # # # # # #
#G# # # # # # # # #E#
#####################
```

### Template 3: Hazard Gauntlet
```
#####################
#@^   ^ P ^   ^ P  E#
#####################
```

### Template 4: Arena Boss (Planned)
```
###################
#H               H#
#                 #
#    #########    #
#    #   B   #    #
#    #########    #
#                 #
#H      @        H#
###################
```

## Procedural Generation Integration

For procgen levels (see `src/modules/procgen.lua`):

**Override Procgen:**
To use hand-crafted maps instead of procedural:
```lua
-- In config.lua
USE_PROCEDURAL_GENERATION = false
```

**Hybrid Approach:**
Mix hand-crafted and procgen:
```lua
-- Levels 1-5: Hand-crafted (tutorial)
-- Levels 6+: Procedural (infinite replayability)
```

**Procgen Hints:**
Guide the algorithm with templates:
```lua
Procgen.setTemplate("combat_room", myTemplate)
```

## Modding Support

To add custom symbols:

1. **Define in config.lua:**
   ```lua
   CUSTOM_SYMBOLS = {
     ["*"] = "teleporter",
     ["%"] = "poison_cloud"
   }
   ```

2. **Handle in main.lua deserialize():**
   ```lua
   elseif char == "*" then
     table.insert(world.teleporters, {x=x, y=y})
   ```

3. **Implement logic in modules:**
   ```lua
   -- modules/teleporter.lua
   function Teleporter.update(dt)
     -- Teleportation logic
   end
   ```

## Resources

- **map/layout.txt:** Quick reference for symbols
- **ARCHITECTURE.md:** How systems interact
- **MODDING.md:** Extending the game
- **README.md:** Player-facing features

## Examples Gallery

### Level 1 (Tutorial)
```
####################
#@   H             #
#  ####   #####    #
#  #         #     #
#  #    G    #     #
#  #         #     #
#  #####   ####    #
#     k           E#
####################
```
**Goal:** Teach basic movement and key collection

### Level 5 (First Challenge)
```
########################
#@    #    G    #     H#
# ### # ####### # ### #
# #k# # #     # # # # #
# ### # # ### # # # # #
#     # # #G# # #   # #
##### # # ### # ##### #
#   # # #     # #   # #
# # # # ####### # # # #
# # #           # #   #
# # ############### # #
# #       G         #E#
########################
```
**Goal:** Maze navigation with multiple enemies

### Level 10 (Mid-Game Boss)
```
#########################
#H                     H#
#   ###############     #
#   #             #     #
#   #   #######   #     #
#   #   #  B  #   #     #
#   #   #######   #     #
#   #             #     #
#   ###############     #
#@                     E#
#########################
```
**Goal:** Boss fight with environmental hazards

### Level 15 (Final Challenge)
```
###########################
#@^G^#k#^G^#^G^#^G^#k#^G^E#
# ### # ### # ### # ### # #
#^# #^#^# #^#^# #^#^# #^#^#
# # # # # # # # # # # # # #
#G#^#^#G#^#^#G#^#^#G#^#^#G#
# ### # ### # ### # ### # #
#^# #^#^# #^#^# #^#^# #^#^#
# # # # # # # # # # # # # #
#H#^#^#H#^#^#H#^#^#H#^#^#H#
###########################
```
**Goal:** Ultimate test of skill and speed

---

**Last Updated:** 2024 (v2.5.0)  
**See Also:** ARCHITECTURE.md, MODDING.md, API.md  
**Community Levels:** Share your creations!
