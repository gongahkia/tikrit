# Changelog

All notable changes to Tikrit based on the recommendations from claude_tasks.txt.

## [2.0.0] - 2024-12-21

### Major Features Added

#### 1. Configuration-Driven Design (Recommendation #9)
- Created `src/config.lua` with all game constants
- Replaced hardcoded values throughout codebase
- Enables easy balancing and customization
- All settings centralized for maintainability

**Files Modified**: `src/main.lua`, `src/config.lua` (new)

#### 2. Debug Visualization Mode (Recommendation #10)
- Toggle debug mode with F3 key
- Shows FPS counter and performance metrics
- Displays collision boxes (wireframe rectangles)
- Shows AI pathfinding vectors
- Real-time statistics overlay
- God mode toggle (F4) for testing without collision

**Files Modified**: `src/main.lua`, `src/config.lua`

#### 3. Difficulty Selection System (Recommendation #5)
- Four difficulty levels: Easy, Normal, Hard, Nightmare
- Title screen menu with arrow key navigation
- Each difficulty adjusts:
  - Monster speed
  - Player speed
  - Item spawn rates
  - Required key percentage
- Nightmare mode enables fog of war automatically

**Files Modified**: `src/main.lua`, `src/config.lua`

#### 4. Statistics Tracking & Grade System (Recommendation #4)
- Tracks gameplay statistics:
  - Completion time
  - Rooms visited
  - Keys collected
  - Deaths
  - Items used
- Enhanced win/lose screens with detailed stats
- Grade system (S/A/B/C/D) based on:
  - Death count
  - Completion time
  - Overall performance
- Displays current difficulty on results

**Files Modified**: `src/main.lua`

#### 5. Fog of War System (Recommendation #1) ⭐ HIGH PRIORITY
- Limited vision radius (configurable, default 7 tiles)
- Progressive map revelation as player explores
- Memory mode showing previously visited areas in reduced alpha
- Dramatically increases tension and horror atmosphere
- Toggle with F5 during gameplay
- Resets when entering new rooms
- Applies to all entities: walls, doors, monsters, items, keys
- Configurable vision radius and visited tile transparency

**Files Modified**: `src/main.lua`, `src/config.lua`

**Impact**: Makes existing 15 room layouts feel fresh and replayable, essential for roguelike design

#### 6. Ghost AI Behavior Variants (Recommendation #2) ⭐ HIGH PRIORITY
- Two distinct AI patterns:
  1. **Chase AI** (ghost-1.png): Aggressively pursues player
  2. **Patrol AI** (ghost-2.png): Guards territory along waypoints
- Ghosts alternate between AI types (even indices patrol, odd chase)
- Patrol ghosts move slower (50% speed) along square patrol patterns
- Different sprites for visual distinction
- Debug mode shows:
  - Purple lines for chase AI tracking
  - Cyan patrol paths for patrol AI
- AI reinitializes when entering new rooms

**Files Modified**: `src/main.lua`

**Impact**: Adds strategic depth, teaches multiple AI patterns, demonstrates state machines

#### 7. Dynamic Random Item Effects (Recommendation #3)
- Potions trigger random effects from pool of 6:
  1. **Speed Boost**: Original behavior, increases player speed
  2. **Speed Reduction**: Risk/reward, slows player down
  3. **Ghost Slow**: Temporarily slows all ghosts by 50%
  4. **Invincibility**: 5 seconds of immunity to death
  5. **Map Reveal**: Shows full room briefly (3 seconds)
  6. **MEGA Speed Boost**: Double the normal buff
- Visual feedback:
  - Invincibility: Yellow/white flashing player sprite
  - Active effects shown in HUD and debug mode
- Configurable effect durations
- Risk/reward decision-making

**Files Modified**: `src/main.lua`, `src/config.lua`

**Impact**: Demonstrates item system architecture and probabilistic game design

#### 8. HUD Overlay & Pause Menu (Recommendation #22)
- Always-visible HUD showing:
  - Key collection progress (X/Y format)
  - Current room number
  - Active effect indicator
- Pause menu (P or ESC):
  - Resume game
  - Restart from title screen
  - Quit game
- Menu navigation with arrow keys
- Semi-transparent overlay for readability
- Proper audio pausing

**Files Modified**: `src/main.lua`

**Impact**: Better UX, essential UI design, critical for commercial games

### Code Quality Improvements

#### Architecture
- Modular configuration system
- Separation of game state and display logic
- Event-driven effect management
- Clean AI behavior abstraction

#### Maintainability
- All magic numbers moved to config
- Consistent naming conventions
- Comprehensive inline comments
- Debug tools for development

### Documentation

#### README.md Updates
- Added comprehensive features section
- Documented all controls including debug keys
- Listed gameplay features
- Highlighted developer features

#### New Files
- `src/config.lua`: Central configuration
- `CHANGELOG.md`: This file

### Testing & Validation

All features tested and validated:
- ✅ No errors in main.lua or config.lua
- ✅ All game modes functional
- ✅ AI behaviors working correctly
- ✅ Fog of war rendering properly
- ✅ Item effects applying correctly
- ✅ Menu navigation smooth
- ✅ Statistics tracking accurate

### Performance

- Fog of war uses efficient tile-based visibility
- AI calculations optimized
- No performance degradation observed
- Debug mode useful for profiling

## Implementation Priority Achieved

### Quick Wins ✅
1. ✅ Difficulty Selection System (#5)
2. ✅ Configuration-Driven Design (#9)
3. ✅ Debug Visualization Mode (#10)
4. ✅ Score & Statistics Tracking (#4)
5. ✅ Improved UI/UX (#22)

### High Impact ✅
1. ✅ Fog of War System (#1)
2. ✅ Dynamic Item Effects (#3)

### Educational Value ✅
1. ✅ Ghost AI Behavior Variants (#2)
2. ✅ Configuration patterns
3. ✅ State management
4. ✅ Effect systems

### Replayability Boosters ✅
1. ✅ Fog of War (#1)
2. ✅ Difficulty Selection (#5)
3. ✅ Random Item Effects (#3)

### Game Feel Improvements ✅
1. ✅ HUD overlay
2. ✅ Visual effect feedback
3. ✅ Pause menu

## Summary Statistics

- **Total Commits**: 8
- **Files Modified**: 3 (main.lua, config.lua, README.md)
- **Files Created**: 2 (config.lua, CHANGELOG.md)
- **Recommendations Implemented**: 8 out of 34 from claude_tasks.txt
- **Lines Added**: ~500+
- **Features Added**: 8 major features

## Industry Relevance

All implemented features demonstrate industry-standard practices:

1. **Configuration-driven design**: Standard in professional game development
2. **Debug visualization**: Essential development tool
3. **Difficulty scaling**: Required for accessibility and game design
4. **Statistics tracking**: Foundation for achievement/leaderboard systems
5. **Fog of war**: Common in stealth/horror games, teaches visibility systems
6. **AI variants**: Demonstrates state machines, pattern in commercial games
7. **Item effects**: Shows probabilistic design and effect management
8. **HUD/Pause**: Critical UX features in all commercial games

## Next Steps (Future Recommendations)

Based on claude_tasks.txt, future improvements could include:

### High Priority
- Modular code refactoring into separate files (#8)
- Procedural room generation (#13)
- In-game level editor (#23)

### Medium Priority
- Particle effects system (#18)
- Animation system (#20)
- Meta-progression system (#14)
- Inventory system (#15)

### Low Priority
- Audio improvements (#21)
- Screen shake effects (#19)
- Daily challenge mode (#17)
- Accessibility options (#33)

## Credits

Original game by @gongahkia
Improvements implemented following recommendations from claude_tasks.txt
Built with Love2D framework
Assets from Kenney's Tiny Dungeon pack and OpenGameArt

## License

Same as original Tikrit project
