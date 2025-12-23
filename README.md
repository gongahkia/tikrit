[![](https://img.shields.io/badge/tikrit_1.0-passing-light_green)](https://github.com/gongahkia/tikrit/releases/tag/1.0)
[![](https://img.shields.io/badge/tikrit_2.0-passing-green)](https://github.com/gongahkia/tikrit/releases/tag/2.0)

# Tikrit

![](asset/tikrit-origin.png)

Tiny horror-ish [roguelike](https://en.wikipedia.org/wiki/Roguelike) written in [Lua](https://www.lua.org/) using Love2D over 5 days.

## Features

### Gameplay
- **Four Difficulty Levels**: Easy, Normal, Hard, and Nightmare modes
- **Daily Challenge Mode**: Fixed seed based on current date - everyone plays the same map each day (toggle with D on title screen)
- **Inventory System**: Hold up to 3 items and use them strategically with number keys (1-3)
- **Fog of War System**: Limited vision radius with memory of previously visited areas
- **Smart Ghost AI**: Two distinct AI behaviors (aggressive chase and territorial patrol)
- **Dynamic Item Effects**: Random effects from potions (speed boost, invincibility, ghost slow, map reveal, etc.)
- **Statistics Tracking**: Track completion time, rooms visited, items used, and deaths
- **Grade System**: S/A/B/C/D ranking based on performance

### Controls
- **Movement**: WASD or Arrow Keys
- **Use Inventory Items**: 1, 2, 3 (use items in inventory slots)
- **Pause**: P or ESC
- **Daily Challenge Toggle**: D (on title screen)
- **Debug Mode**: F3 (shows FPS, collision boxes, AI vectors, stats)
- **God Mode**: F4 (disable collision for testing)
- **Fog of War Toggle**: F5 (enable/disable during gameplay)
- **Performance Profiler**: F6 (shows FPS graph, frame times, memory usage)
- **Colorblind Mode**: F7 (cycle through colorblind filters)
- **High Contrast Mode**: F8 (toggle high contrast for better visibility)
- **Slow Mode**: F9 (reduce all game speeds by 50% for accessibility)
- **Minimap Toggle**: M (show/hide minimap overlay)
- **Menu Navigation**: Up/Down arrows
- **Menu Selection**: Enter
- **Menu Selection**: Enter

### HUD
- Key collection progress
- Current room number  
- Inventory display (3 item slots - use with 1, 2, 3 keys)
- Active effect indicators (Invincible, Ghosts Slowed, Map Revealed)
- Minimap overlay (toggle with M) showing current room layout, player position, ghosts, keys, and items

### Developer Features
- Configuration-driven design via `config.lua`
- Debug visualization mode for development (F3)
- Performance profiler with frame timing and memory tracking (F6)
- Accessibility features: colorblind modes (F7), high contrast (F8), slow mode (F9), visual audio indicators
- Comprehensive statistics tracking
- Modular AI system for easy expansion

## Installation

### CLI

```console
$ git clone https://github.com/gongahkia/tikrit
$ chmod +x install.sh
$ ./install.sh
$ make # builds executable
$ make reset # rebuild randomised level
```

### GUI

1. Install [Love2D](https://love2d.org/).
2. Open `tikrit` in VSCode.
3. Install the [Love2D Support](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d) VSCode extension.
4. Open `src/main.lua` file.
5. Press `alt + L` key

## Screenshots

![](asset/tikrit-gameplay-1.png)

Collect the keys to escape.

![](asset/tikrit-gameplay-2.png)

https://github.com/gongahkia/tikrit/assets/117062305/ef34901c-4873-4069-bbba-dda911497777

## Assets

* Sprites from Kenney's [tiny dungeon](https://kenney.nl/assets/tiny-dungeon) asset pack
* Audio from [OpenGameArt](https://opengameart.org/)
