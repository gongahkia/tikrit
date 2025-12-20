![](https://img.shields.io/badge/tikrit_1.0-passing-green)

# Tikrit

![](asset/tikrit-origin.png)

Tiny horror-ish [roguelike](https://en.wikipedia.org/wiki/Roguelike) written in [Lua](https://www.lua.org/) using Love2D over 5 days.

## Features

### Gameplay
- **Four Difficulty Levels**: Easy, Normal, Hard, and Nightmare modes
- **Fog of War System**: Limited vision radius with memory of previously visited areas
- **Smart Ghost AI**: Two distinct AI behaviors (aggressive chase and territorial patrol)
- **Dynamic Item Effects**: Random effects from potions (speed boost, invincibility, ghost slow, map reveal, etc.)
- **Statistics Tracking**: Track completion time, rooms visited, items used, and deaths
- **Grade System**: S/A/B/C/D ranking based on performance

### Controls
- **Movement**: WASD or Arrow Keys
- **Pause**: P or ESC
- **Debug Mode**: F3 (shows FPS, collision boxes, AI vectors, stats)
- **God Mode**: F4 (disable collision for testing)
- **Fog of War Toggle**: F5 (enable/disable during gameplay)
- **Menu Navigation**: Up/Down arrows
- **Menu Selection**: Enter

### HUD
- Key collection progress
- Current room number  
- Active effect indicators (Invincible, Ghosts Slowed, Map Revealed)

### Developer Features
- Configuration-driven design via `config.lua`
- Debug visualization mode for development
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
